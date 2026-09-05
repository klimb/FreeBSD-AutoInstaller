# QEMU test-vm profile — used only by test-vm/build-test-image.sh.
# Generic ada0 target, no hardware fragment, no postinstall layers
# (Omarchy/Hyprland needs real GPU hardware, out of scope for a VM smoke test).

TARGET_DISK="ada0"
TARGET_FS="zfs"
# BIOS, not UEFI: avoids needing OVMF firmware just to run the smoke test.
TARGET_BOOT_TYPE="BIOS"
TARGET_IFCONFIG='ifconfig_DEFAULT="DHCP"'

DEFAULT_HOSTNAME="testvm"
DEFAULT_ADMIN_USER="testadmin"
DEFAULT_ENCRYPT_DISK="N"

# The VM's serial console can't drive bsddialog's ncurses UI reliably from
# an expect script; fall back to the plain read()-based prompts.
FORCE_PLAIN_PROMPTS="1"

HARDWARE_PROFILE=""
POSTINSTALL_LAYERS=""
