# ThinkPad T14 Gen 1 (Intel Comet Lake variant).
# Source: klimb/bsd-laptops FreeBSD/thinkpad-t14-gen1_vermaden
# Blog:   https://vermaden.wordpress.com/2023/05/14/freebsd-13-2-on-thinkpad-t14-gen1/

TARGET_DISK="nda0"
TARGET_FS="zfs"
TARGET_BOOT_TYPE="UEFI"

TARGET_IFCONFIG='ifconfig_DEFAULT="DHCP"'

DEFAULT_HOSTNAME="t14"
DEFAULT_ENCRYPT_DISK="Y"

TARGET_PACKAGES="sudo bash git vim-tiny tmux curl rsync"

HARDWARE_PROFILE="thinkpad-t14-gen1"
POSTINSTALL_LAYERS=""
