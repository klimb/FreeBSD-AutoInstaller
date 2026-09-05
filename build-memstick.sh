#!/bin/sh
# build-memstick.sh — one command, one FreeBSD installer USB.
#
# Author: Dmitry Kalashnikov
#
# Usage:
#   sh build-memstick.sh                       # generic, auto-detect USB
#   sh build-memstick.sh thinkpad-nano-gen2    # ThinkPad profile
#   sh build-memstick.sh nano -d /dev/da2      # force a specific device
#
# Zero prompts on the build side. All install-time questions happen on
# the target: hostname, admin user + password, disk passphrase, Wi-Fi.

set -eu

PROG=$(basename "$0")
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
TEMPLATE_FILE="${SCRIPT_DIR}/installerconfig.template"

# ---- Built-in defaults (override in config.sh or a profile) ---------------
FBSD_VERSION="15.1-RELEASE"
FBSD_ARCH="amd64"
FBSD_MIRROR="https://download.freebsd.org/ftp/releases"
CACHE_DIR="${SCRIPT_DIR}/cache"
PKG_REPO_BRANCH="latest"

TARGET_DISK="ada0"
TARGET_FS="zfs"
TARGET_BOOT_TYPE="UEFI"
TARGET_IFCONFIG='ifconfig_DEFAULT="DHCP"'
TARGET_DEFAULTROUTER=""
TARGET_DNS=""
TARGET_PACKAGES="sudo bash git vim-tiny"

SSH_AUTHORIZED_KEYS=""
PERMIT_ROOT_LOGIN="NO"

DEFAULT_HOSTNAME="freebsd"
DEFAULT_ADMIN_USER="admin"
DEFAULT_ENCRYPT_DISK="Y"

HARDWARE_PROFILE=""
POSTINSTALL_LAYERS=""

# ---- Optional override file -----------------------------------------------
[ -f "${SCRIPT_DIR}/config.sh" ] && . "${SCRIPT_DIR}/config.sh"

# ---- Args -----------------------------------------------------------------
PROFILE=""
CLI_DEVICE=""
while [ $# -gt 0 ]; do
    case "$1" in
        -d)        CLI_DEVICE=$2; shift 2 ;;
        -h|--help)
            cat <<EOF
Usage: sh ${PROG} [PROFILE] [-d /dev/daN]

  PROFILE   Optional profile name (files under ./profiles/).
  -d DEV    Explicit USB device (skip auto-detection).

Fetch + inject + flash in a single pass. Auto-detects the USB device
if exactly one removable is plugged in. Re-execs under doas/sudo when
not root.
EOF
            exit 0 ;;
        -*) echo "unknown flag: $1" >&2; exit 2 ;;
        *)  PROFILE=$1; shift ;;
    esac
done

if [ -n "$PROFILE" ]; then
    p="${SCRIPT_DIR}/profiles/${PROFILE}.sh"
    [ -f "$p" ] || { echo "profile not found: $p" >&2; exit 1; }
    # shellcheck disable=SC1090
    . "$p"
    echo "[+] profile: $PROFILE"
fi

# ---- Auto-elevate ---------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    for esc in doas sudo; do
        if command -v $esc >/dev/null 2>&1; then
            echo "[+] re-executing under $esc"
            set --
            [ -n "$PROFILE" ]    && set -- "$@" "$PROFILE"
            [ -n "$CLI_DEVICE" ] && set -- "$@" -d "$CLI_DEVICE"
            exec $esc sh "$0" "$@"
        fi
    done
    echo "must run as root (doas/sudo not found)" >&2; exit 1
fi

[ "$(uname -s)" = "FreeBSD" ] || { echo "FreeBSD only." >&2; exit 1; }
[ -f "$TEMPLATE_FILE" ]       || { echo "missing installerconfig.template" >&2; exit 1; }

# ---- USB auto-detect ------------------------------------------------------
autodetect_usb() {
    matches=""
    for d in $(sysctl -n kern.disks 2>/dev/null); do
        case "$d" in da[0-9]*) ;; *) continue ;; esac
        # skip if any slice/partition of this disk is mounted
        if mount | awk '{print $1}' | grep -qE "^/dev/${d}([^0-9]|\$)"; then
            continue
        fi
        matches="$matches $d"
    done
    set -- $matches
    [ $# -eq 1 ] || return 1
    printf '/dev/%s' "$1"
}

USB_DEVICE=${CLI_DEVICE:-}
if [ -z "$USB_DEVICE" ]; then
    if USB_DEVICE=$(autodetect_usb); then
        echo "[+] auto-detected USB: $USB_DEVICE"
    else
        {
            echo "could not auto-detect a single USB device."
            echo "candidates: $(sysctl -n kern.disks 2>/dev/null)"
            echo "re-run with:  sh $PROG ${PROFILE:-} -d /dev/daN"
        } >&2
        exit 1
    fi
fi

[ -e "$USB_DEVICE" ] || { echo "no such device: $USB_DEVICE" >&2; exit 1; }
case "$USB_DEVICE" in
    /dev/ada*|/dev/nda*|/dev/nvme*)
        echo "refusing to flash internal disk $USB_DEVICE" >&2; exit 1 ;;
esac

# ---- Paths ----------------------------------------------------------------
IMAGE_NAME="FreeBSD-${FBSD_VERSION}-${FBSD_ARCH}-memstick.img"
IMAGE_URL="${FBSD_MIRROR}/${FBSD_ARCH}/${FBSD_ARCH}/ISO-IMAGES/${FBSD_VERSION%-RELEASE}/${IMAGE_NAME}"
CHECKSUM_URL="${FBSD_MIRROR}/${FBSD_ARCH}/${FBSD_ARCH}/ISO-IMAGES/${FBSD_VERSION%-RELEASE}/CHECKSUM.SHA256-FreeBSD-${FBSD_VERSION}-${FBSD_ARCH}"
mkdir -p "$CACHE_DIR"
IMAGE_PATH="${CACHE_DIR}/${IMAGE_NAME}"
CHECKSUM_PATH="${CACHE_DIR}/CHECKSUM.SHA256-${FBSD_VERSION}-${FBSD_ARCH}"

# ---- Cleanup trap ---------------------------------------------------------
MOUNTPOINT=""
MDDEV=""
cleanup() {
    rc=$?
    if [ -n "$MOUNTPOINT" ] && mount | grep -q " on ${MOUNTPOINT} "; then
        umount "$MOUNTPOINT" 2>/dev/null || umount -f "$MOUNTPOINT" 2>/dev/null || true
    fi
    [ -n "$MOUNTPOINT" ] && [ -d "$MOUNTPOINT" ] && rmdir "$MOUNTPOINT" 2>/dev/null || true
    if [ -n "$MDDEV" ] && mdconfig -l 2>/dev/null | grep -qw "$MDDEV"; then
        mdconfig -d -u "${MDDEV#md}" 2>/dev/null || true
    fi
    exit $rc
}
trap cleanup EXIT INT TERM

# ---- 1. Fetch + verify ----------------------------------------------------
echo "[1/3] fetch $IMAGE_NAME"
fetch -q -o "$CHECKSUM_PATH" "$CHECKSUM_URL"
fetch -r -o "$IMAGE_PATH" "$IMAGE_URL"

expected=$(awk -v f="($IMAGE_NAME)" '$2==f {print $4}' "$CHECKSUM_PATH")
[ -n "$expected" ] || expected=$(grep -F "($IMAGE_NAME)" "$CHECKSUM_PATH" | awk '{print $NF}' | head -n 1)
[ -n "$expected" ] || { echo "no checksum entry for $IMAGE_NAME" >&2; exit 1; }
actual=$(sha256 -q "$IMAGE_PATH")
[ "$expected" = "$actual" ] || { echo "checksum mismatch (expected $expected got $actual)" >&2; exit 1; }

# ---- 2. Inject ------------------------------------------------------------
echo "[2/3] inject installerconfig"
MDDEV=$(mdconfig -a -t vnode -f "$IMAGE_PATH")

part=""
for c in "${MDDEV}s2a" "${MDDEV}s1a" "${MDDEV}p3" "${MDDEV}p2"; do
    [ -e "/dev/$c" ] && { part=$c; break; }
done
[ -n "$part" ] || { echo "no root partition on /dev/${MDDEV}" >&2; exit 1; }
MOUNTPOINT=$(mktemp -d /tmp/fb_usb.XXXXXX)
mount "/dev/$part" "$MOUNTPOINT"

render_installerconfig() {
    dest=$1

    if [ -n "$TARGET_DEFAULTROUTER" ]; then
        defrouter_line="sysrc defaultrouter=\"${TARGET_DEFAULTROUTER}\""
    else
        defrouter_line="# (no static default route)"
    fi
    if [ -n "$TARGET_DNS" ]; then
        resolvconf_line=": > /etc/resolv.conf"
        for ns in $TARGET_DNS; do
            resolvconf_line="${resolvconf_line}; echo 'nameserver ${ns}' >> /etc/resolv.conf"
        done
    else
        resolvconf_line="# (no static DNS)"
    fi

    tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/fb-render.XXXXXX")
    printf '%s\n' "$SSH_AUTHORIZED_KEYS" > "$tmpdir/ssh_keys"

    if [ -n "$HARDWARE_PROFILE" ]; then
        hw="${SCRIPT_DIR}/hardware/${HARDWARE_PROFILE}.sh"
        [ -f "$hw" ] || { echo "hardware fragment missing: $hw" >&2; exit 1; }
        cp "$hw" "$tmpdir/hardware"
    else
        : > "$tmpdir/hardware"
    fi

    : > "$tmpdir/postinstall"
    for l in $POSTINSTALL_LAYERS; do
        f="${SCRIPT_DIR}/postinstall/${l}.sh"
        [ -f "$f" ] || { echo "postinstall layer missing: $f" >&2; exit 1; }
        printf '\n# ---- postinstall: %s ----\n' "$l" >> "$tmpdir/postinstall"
        cat "$f" >> "$tmpdir/postinstall"
    done

    awk -v disk="$TARGET_DISK" -v boot="$TARGET_BOOT_TYPE" -v ifc="$TARGET_IFCONFIG" \
        -v defr="$defrouter_line" -v rslv="$resolvconf_line" -v pkgs="$TARGET_PACKAGES" \
        -v prl="$PERMIT_ROOT_LOGIN" -v dh="$DEFAULT_HOSTNAME" -v du="$DEFAULT_ADMIN_USER" \
        -v de="$DEFAULT_ENCRYPT_DISK" -v pkgbr="$PKG_REPO_BRANCH" \
        -v ssh_file="$tmpdir/ssh_keys" -v hw_file="$tmpdir/hardware" \
        -v post_file="$tmpdir/postinstall" '
    function slurp(fn,  line, out) {
        out=""
        while ((getline line < fn) > 0) out = out line "\n"
        close(fn)
        return out
    }
    {
        gsub(/@@TARGET_DISK@@/,          disk)
        gsub(/@@TARGET_BOOT_TYPE@@/,     boot)
        gsub(/@@TARGET_IFCONFIG@@/,      ifc)
        gsub(/@@DEFAULTROUTER_LINE@@/,   defr)
        gsub(/@@RESOLVCONF_LINE@@/,      rslv)
        gsub(/@@TARGET_PACKAGES@@/,      pkgs)
        gsub(/@@PERMIT_ROOT_LOGIN@@/,    prl)
        gsub(/@@DEFAULT_HOSTNAME@@/,     dh)
        gsub(/@@DEFAULT_ADMIN_USER@@/,   du)
        gsub(/@@DEFAULT_ENCRYPT_DISK@@/, de)
        gsub(/@@PKG_REPO_BRANCH@@/,      pkgbr)
        if (index($0, "@@SSH_AUTHORIZED_KEYS@@")) { printf "%s", slurp(ssh_file);  next }
        if (index($0, "@@HARDWARE_SETUP@@"))      { printf "%s", slurp(hw_file);   next }
        if (index($0, "@@POSTINSTALL_SETUP@@"))   { printf "%s", slurp(post_file); next }
        print
    }' "$TEMPLATE_FILE" > "$dest"

    rm -rf "$tmpdir"
    chmod 0644 "$dest"
}

render_installerconfig "${MOUNTPOINT}/etc/installerconfig"
sync
umount "$MOUNTPOINT"; MOUNTPOINT=""
mdconfig -d -u "${MDDEV#md}"; MDDEV=""

# ---- 3. Flash -------------------------------------------------------------
size="unknown"
sz=$(diskinfo "$USB_DEVICE" 2>/dev/null | awk '{print $3}')
[ -n "$sz" ] && size=$(printf '%s' "$sz" | awk '{printf "%.1f GiB", $1/1024/1024/1024}')

echo "[3/3] flashing $USB_DEVICE ($size) in 5s — Ctrl-C to abort"
for i in 5 4 3 2 1; do printf '  %d... ' "$i"; sleep 1; done
printf '\n'
dd if="$IMAGE_PATH" of="$USB_DEVICE" bs=1M conv=sync status=progress
sync
echo "[+] done. Boot the target from $USB_DEVICE."
