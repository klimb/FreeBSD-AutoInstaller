### Hardware setup fragment — ThinkPad X230 Tablet (Ivy Bridge).
### Source: klimb/bsd-laptops FreeBSD/thinkpad-classic-x230t_dvk

# ---- Intel HD 4000 (Ivy Bridge) KMS --------------------------------------
sysrc kld_list+="i915kms"

# ---- Centrino Advanced-N 6205 Wi-Fi (iwn) --------------------------------
sysrc wlans_iwn0="wlan0"
sysrc ifconfig_wlan0="WPA SYNCDHCP"
sysrc wpa_supplicant_enable="YES"

# ---- Webcam via webcamd + cuse -------------------------------------------
sysrc webcamd_enable="YES"

# ---- Power / thermal / time ----------------------------------------------
sysrc powerd_enable="YES"
sysrc powerd_flags="-a hiadaptive -b adaptive"
sysrc ntpd_enable="YES"
sysrc ntpd_sync_on_start="YES"

# ---- Loader tunables -----------------------------------------------------
cat >> /boot/loader.conf <<'__LDR_EOF__'
# ThinkPad X230 Tablet
acpi_ibm_load="YES"
acpi_video_load="YES"
coretemp_load="YES"
cuse_load="YES"
hw.psm.synaptics_support="1"
autoboot_delay="2"
__LDR_EOF__

if [ -n "$TARGET_ADMIN_USER" ]; then
    pw groupmod video    -m "$TARGET_ADMIN_USER" 2>/dev/null || true
    pw groupmod operator -m "$TARGET_ADMIN_USER" 2>/dev/null || true
    pw groupmod webcamd  -m "$TARGET_ADMIN_USER" 2>/dev/null || true
fi

env ASSUME_ALWAYS_YES=YES pkg install -y \
    drm-kmod \
    webcamd \
    cuse \
    || true
