#!/bin/sh
# verify.sh — end-to-end repo verification: build a test image on a real
# FreeBSD host, pull it here, and boot it in QEMU to confirm the scripted
# install runs cleanly through the chroot phase.
#
# build-memstick.sh only runs on FreeBSD (uses doas/mdconfig/bsdinstall
# bits), so image rendering must happen on a FreeBSD box; QEMU then runs
# locally on whatever machine has qemu-system-x86_64 + expect installed.
#
# Usage: sh test-vm/verify.sh user@freebsd-host [remote-repo-path]

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
HOST="${1:?usage: $0 user@freebsd-host [remote-repo-path]}"
REMOTE_REPO="${2:-~/src/FreeBSD-AutoInstaller}"
OUT_DIR="$SCRIPT_DIR/out"
mkdir -p "$OUT_DIR"

echo "[1/3] syncing repo + building test image on $HOST"
ssh "$HOST" "cd $REMOTE_REPO && git pull && sh test-vm/build-test-image.sh"

echo "[2/3] fetching rendered image"
scp "$HOST:$REMOTE_REPO/test-vm/out/test-memstick.img" "$OUT_DIR/test-memstick.img"

echo "[3/3] booting test image in local qemu"
sh "$SCRIPT_DIR/run-qemu-test.sh" "$OUT_DIR/test-memstick.img"
