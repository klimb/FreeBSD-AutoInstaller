# ThinkPad E15 Gen 2 (Comet Lake, Intel UHD, AX201 Wi-Fi).
# Source: klimb/bsd-laptops FreeBSD/thinkpad-e15-gen2_dvk

TARGET_DISK="nda0"
TARGET_FS="zfs"
TARGET_BOOT_TYPE="UEFI"

TARGET_IFCONFIG='ifconfig_DEFAULT="DHCP"'

DEFAULT_HOSTNAME="e15"
DEFAULT_ENCRYPT_DISK="Y"

TARGET_PACKAGES="sudo bash git vim-tiny tmux curl rsync"

HARDWARE_PROFILE="thinkpad-e15-gen2"
POSTINSTALL_LAYERS=""
