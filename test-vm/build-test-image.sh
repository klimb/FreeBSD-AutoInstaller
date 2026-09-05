#!/bin/sh
# build-test-image.sh — render a test-vm memstick image without a USB stick.
#
# Must run on a FreeBSD host (uses mdconfig(8)). Creates a scratch file,
# attaches it as a vnode-backed md(4) device, and points build-memstick.sh's
# flash step (-d) at that device instead of a real /dev/daN. The resulting
# file is a fully rendered, bootable memstick image usable directly as a
# QEMU drive — no physical hardware involved.
#
# Usage: sh test-vm/build-test-image.sh [output-path]

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
OUT="${1:-$SCRIPT_DIR/out/test-memstick.img}"

[ "$(uname -s)" = "FreeBSD" ] || { echo "must run on FreeBSD." >&2; exit 1; }

if [ "$(id -u)" -ne 0 ]; then
    for esc in doas sudo; do
        command -v "$esc" >/dev/null 2>&1 && exec "$esc" sh "$0" "$@"
    done
    echo "must run as root (doas/sudo not found)" >&2; exit 1
fi

mkdir -p "$(dirname "$OUT")"
SCRATCH="${OUT}.scratch"

# memstick image is ~1.5G; 2G scratch leaves headroom.
truncate -s 2G "$SCRATCH"

MDDEV=$(mdconfig -a -t vnode -f "$SCRATCH")
cleanup() {
    mdconfig -l 2>/dev/null | grep -qw "$MDDEV" && mdconfig -d -u "${MDDEV#md}"
}
trap cleanup EXIT INT TERM

echo "[+] rendering test image via /dev/$MDDEV"
sh "${REPO_DIR}/build-memstick.sh" test-vm -d "/dev/$MDDEV"

mv "$SCRATCH" "$OUT"
echo "[+] test image ready: $OUT"
