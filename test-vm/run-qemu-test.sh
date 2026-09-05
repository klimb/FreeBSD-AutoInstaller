#!/bin/sh
# run-qemu-test.sh — boot a rendered test-vm memstick image in QEMU and
# drive the unattended install via expect(1). No physical hardware, no
# USB stick; the memstick image is attached as emulated USB storage and
# a blank raw file stands in for the target disk (ada0).
#
# Requires: qemu-system-x86_64, expect. Runs on macOS/Linux.
#
# Usage: sh test-vm/run-qemu-test.sh <path-to-test-memstick.img>

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
IMG="${1:?usage: $0 <path-to-test-memstick.img>}"
[ -f "$IMG" ] || { echo "no such image: $IMG" >&2; exit 1; }

OUT_DIR="$SCRIPT_DIR/out"
DISK="$OUT_DIR/target-disk.img"
LOG="$OUT_DIR/install-console.log"
mkdir -p "$OUT_DIR"

command -v qemu-system-x86_64 >/dev/null 2>&1 || { echo "qemu-system-x86_64 not found" >&2; exit 1; }
command -v expect >/dev/null 2>&1 || { echo "expect not found" >&2; exit 1; }

# Fresh 8G blank target disk every run.
rm -f "$DISK"
qemu-img create -f raw "$DISK" 8G >/dev/null

echo "[+] booting $IMG in qemu, logging console to $LOG"
: > "$LOG"

expect "$SCRIPT_DIR/expect/install.exp" "$LOG" qemu-system-x86_64 \
    -name freebsd-autoinstaller-test \
    -m 2048 -smp 2 \
    -vga none -display none -monitor none \
    -no-reboot \
    -netdev user,id=net0 -device e1000,netdev=net0 \
    -drive if=none,id=usbstick,file="$IMG",format=raw,readonly=on \
    -device usb-ehci,id=usbbus \
    -device usb-storage,drive=usbstick,bus=usbbus.0,bootindex=0 \
    -drive if=none,id=disk0,file="$DISK",format=raw \
    -device ahci,id=ahci0 \
    -device ide-hd,drive=disk0,bus=ahci0.0,bootindex=1 \
    -serial stdio
rc=$?

if [ $rc -eq 0 ]; then
    echo "[PASS] see full console log: $LOG"
else
    echo "[FAIL] (exit $rc) see full console log: $LOG"
fi
exit $rc
