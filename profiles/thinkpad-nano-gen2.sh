# ThinkPad X1 Nano Gen 2 profile.
# Sourced by build-memstick.sh AFTER config.sh — overrides generic defaults.
# Nothing personal is baked in; the installer prompts for username/passwords.

# Alder Lake NVMe (nda(4) on 14.x+).
TARGET_DISK="nda0"
TARGET_FS="zfs"
TARGET_BOOT_TYPE="UEFI"

# USB-C dock Ethernet works with DHCP; Wi-Fi is set up post-install.
TARGET_IFCONFIG='ifconfig_DEFAULT="DHCP"'

# Enter-through defaults for a quick install.
DEFAULT_HOSTNAME="nano"
DEFAULT_ENCRYPT_DISK="Y"
# DEFAULT_ADMIN_USER intentionally left as config.sh default — asked at install.

# Base packages; hardware fragment adds drm/wifi firmware on top.
TARGET_PACKAGES="sudo bash git vim-tiny tmux curl rsync"

# Hardware setup fragment (Intel Iris Xe, AX211 Wi-Fi, acpi_ibm, microcode).
HARDWARE_PROFILE="thinkpad-nano-gen2"

# Post-install layers (chef's-choice desktop stack).
POSTINSTALL_LAYERS="omarchy"
