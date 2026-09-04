# ThinkPad X230 Tablet (Ivy Bridge, HD 4000, iwn0 Wi-Fi, digitizer + webcam).
# Source: klimb/bsd-laptops FreeBSD/thinkpad-classic-x230t_dvk

# 2.5" SATA SSD/HDD on this generation.
TARGET_DISK="ada0"
TARGET_FS="zfs"
TARGET_BOOT_TYPE="UEFI"

TARGET_IFCONFIG='ifconfig_DEFAULT="DHCP"'

DEFAULT_HOSTNAME="x230t"
DEFAULT_ENCRYPT_DISK="Y"

TARGET_PACKAGES="sudo bash git vim-tiny tmux curl rsync"

HARDWARE_PROFILE="thinkpad-x230t"
POSTINSTALL_LAYERS=""
