### Hardware setup fragment — ThinkPad X1 Nano Gen 2 (Alder Lake).
### Executed inside the chrooted new system by installerconfig.
### Assumes: root pw / hostname / admin user already applied by main script.
### Env in: TARGET_ADMIN_USER

# ---- Intel Iris Xe (Alder Lake) KMS ---------------------------------------
sysrc kld_list+="i915kms"

# ---- Intel AX211 Wi-Fi ----------------------------------------------------
sysrc kld_list+="if_iwlwifi"
sysrc wlans_iwlwifi0="wlan0"
sysrc ifconfig_wlan0="WPA SYNCDHCP"
sysrc wpa_supplicant_enable="YES"

# ---- Power / thermal / time -----------------------------------------------
sysrc powerd_enable="YES"
sysrc powerd_flags="-a hiadaptive -b adaptive -n adaptive"
sysrc ntpd_enable="YES"
sysrc ntpd_sync_on_start="YES"

# ---- Loader tunables ------------------------------------------------------
cat >> /boot/loader.conf <<'__LDR_EOF__'
# ThinkPad X1 Nano Gen 2
acpi_ibm_load="YES"
acpi_video_load="YES"
coretemp_load="YES"
cpu_microcode_load="YES"
cpu_microcode_name="/boot/firmware/intel-ucode.bin"
hw.psm.synaptics_support="1"
autoboot_delay="2"
__LDR_EOF__

# ---- Groups needed for GPU / Wi-Fi / suspend ------------------------------
if [ -n "$TARGET_ADMIN_USER" ]; then
    pw groupmod video    -m "$TARGET_ADMIN_USER" 2>/dev/null || true
    pw groupmod operator -m "$TARGET_ADMIN_USER" 2>/dev/null || true
fi

# ---- Firmware / DRM / microcode packages ----------------------------------
# Idempotent; pkg is bootstrapped once in the main chroot script.
env ASSUME_ALWAYS_YES=YES pkg install -y \
    drm-kmod \
    devcpu-data \
    wifi-firmware-kmod \
    || true
