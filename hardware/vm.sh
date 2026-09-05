### Hardware setup fragment — generic QEMU/KVM virtual machine.
### virtio net/blk/scsi/balloon are built into GENERIC; no loader.conf
### module loading required.

# ---- guest agent: host <-> guest integration (QMP fsfreeze, etc.) --------
env ASSUME_ALWAYS_YES=YES pkg install -y qemu-guest-agent || true
sysrc qemu_guest_agent_enable="YES"

# ---- virtio balloon: let the hypervisor reclaim idle guest memory --------
sysrc kld_list+="virtio_balloon"

# ---- loader tunables -------------------------------------------------
cat >> /boot/loader.conf <<'__LDR_EOF__'
# generic QEMU/KVM VM
autoboot_delay="2"
__LDR_EOF__
