# Generic QEMU/KVM virtual machine — plain interactive install (UEFI +
# bsddialog on a video console).
#
# Not to be confused with profiles/test-vm.sh, which drives the automated
# serial-console smoke-test harness in test-vm/.

TARGET_DISK="ada0"          # AHCI/SATA (-device ahci + ide-hd/scsi-hd) -> ada0
                            # virtio-blk (-drive if=virtio)             -> vtbd0
TARGET_FS="zfs"
TARGET_BOOT_TYPE="UEFI"
TARGET_IFCONFIG='ifconfig_DEFAULT="DHCP"'

HARDWARE_PROFILE="vm"
POSTINSTALL_LAYERS=""
