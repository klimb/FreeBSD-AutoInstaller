### Hardware setup fragment — ThinkPad T480 (Kaby Lake R).
### Reference: klimb/bsd-laptops FreeBSD/thinkpad-t480_vermaden

# ---- Intel UHD 620 (Kaby Lake R) KMS -------------------------------------
sysrc kld_list+="i915kms"

# ---- Intel Wireless-AC 8265 (iwm) ----------------------------------------
sysrc kld_list+="if_iwm"
sysrc wlans_iwm0="wlan0"
sysrc ifconfig_wlan0="WPA SYNCDHCP"
sysrc wpa_supplicant_enable="YES"

# ---- Power / thermal / time ----------------------------------------------
sysrc performance_cx_lowest="C1"
sysrc economy_cx_lowest="Cmax"
sysrc powerd_enable="YES"
sysrc powerd_flags="-a hiadaptive -b adaptive -n adaptive"
sysrc ntpd_enable="YES"
sysrc ntpd_sync_on_start="YES"

# ---- Loader tunables -----------------------------------------------------
cat >> /boot/loader.conf <<'__LDR_EOF__'
# ThinkPad T480
autoboot_delay="2"
acpi_ibm_load="YES"
acpi_video_load="YES"
coretemp_load="YES"
cpu_microcode_load="YES"
cpu_microcode_name="/boot/firmware/intel-ucode.bin"
aesni_load="YES"
cryptodev_load="YES"
hw.psm.synaptics_support="1"
compat.linuxkpi.enable_rc6="7"
compat.linuxkpi.enable_dc="2"
compat.linuxkpi.enable_fbc="1"
kern.geom.eli.threads="4"
__LDR_EOF__

if [ -n "$TARGET_ADMIN_USER" ]; then
    pw groupmod video    -m "$TARGET_ADMIN_USER" 2>/dev/null || true
    pw groupmod operator -m "$TARGET_ADMIN_USER" 2>/dev/null || true
fi

env ASSUME_ALWAYS_YES=YES pkg install -y \
    drm-kmod \
    devcpu-data \
    || true
