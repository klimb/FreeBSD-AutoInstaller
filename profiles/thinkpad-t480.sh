# ThinkPad T480 (Kaby Lake R, Intel UHD 620, Intel 8265 Wi-Fi).
# Reference: klimb/bsd-laptops FreeBSD/thinkpad-t480_vermaden
#
# T480 ships with a 2.5" SATA bay (ada0) and an optional M.2 NVMe (nda0).
# Set TARGET_DISK="nda0" if you're installing to the NVMe slot.

TARGET_DISK="ada0"
TARGET_FS="zfs"
TARGET_BOOT_TYPE="UEFI"

TARGET_IFCONFIG='ifconfig_DEFAULT="DHCP"'

DEFAULT_HOSTNAME="t480"
DEFAULT_ENCRYPT_DISK="Y"

TARGET_PACKAGES="sudo bash git vim-tiny tmux curl rsync"

HARDWARE_PROFILE="thinkpad-t480"
POSTINSTALL_LAYERS=""
