### Hardware setup fragment — ThinkPad E15 Gen 2 (Comet Lake).
### Source: klimb/bsd-laptops FreeBSD/thinkpad-e15-gen2_dvk

# ---- Intel UHD (Comet Lake) KMS ------------------------------------------
sysrc kld_list+="i915kms"

# ---- Intel Wi-Fi 6 AX201 (iwlwifi) ---------------------------------------
sysrc kld_list+="if_iwlwifi"
sysrc wlans_iwlwifi0="wlan0"
sysrc ifconfig_wlan0="WPA SYNCDHCP"
sysrc wpa_supplicant_enable="YES"

# ---- Power / thermal / time ----------------------------------------------
sysrc powerd_enable="YES"
sysrc powerd_flags="-a hiadaptive -b adaptive"
sysrc ntpd_enable="YES"
sysrc ntpd_sync_on_start="YES"

# ---- Loader tunables -----------------------------------------------------
cat >> /boot/loader.conf <<'__LDR_EOF__'
# ThinkPad E15 Gen 2
acpi_ibm_load="YES"
acpi_video_load="YES"
coretemp_load="YES"
cpu_microcode_load="YES"
cpu_microcode_name="/boot/firmware/intel-ucode.bin"
hw.psm.synaptics_support="1"
autoboot_delay="2"
__LDR_EOF__

if [ -n "$TARGET_ADMIN_USER" ]; then
    pw groupmod video    -m "$TARGET_ADMIN_USER" 2>/dev/null || true
    pw groupmod operator -m "$TARGET_ADMIN_USER" 2>/dev/null || true
fi

env ASSUME_ALWAYS_YES=YES pkg install -y \
    drm-kmod \
    devcpu-data \
    wifi-firmware-kmod \
    || true
