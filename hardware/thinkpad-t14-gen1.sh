### Hardware setup fragment — ThinkPad T14 Gen 1 (Intel Comet Lake variant).
### Source: klimb/bsd-laptops FreeBSD/thinkpad-t14-gen1_vermaden
### Original write-up: https://vermaden.wordpress.com/2023/05/14/freebsd-13-2-on-thinkpad-t14-gen1/

# ---- Intel UHD KMS -------------------------------------------------------
sysrc kld_list+="i915kms"

# ---- Realtek Wi-Fi (rtwn) ------------------------------------------------
sysrc wlans_rtwn0="wlan0"
sysrc ifconfig_wlan0="WPA SYNCDHCP"
sysrc wpa_supplicant_enable="YES"

# ---- Extra modules per vermaden -----------------------------------------
sysrc kld_list+="fusefs"
sysrc kld_list+="coretemp"
sysrc kld_list+="cpuctl"
sysrc kld_list+="ichsmb"
sysrc kld_list+="cuse"

# ---- Power / thermal / time ---------------------------------------------
sysrc performance_cx_lowest="C1"
sysrc economy_cx_lowest="Cmax"
sysrc powerd_enable="YES"
sysrc powerd_flags="-n adaptive -a hiadaptive -b adaptive -m 800 -M 2000"
sysrc ntpd_enable="YES"
sysrc ntpd_sync_on_start="YES"

# ---- Loader tunables ----------------------------------------------------
cat >> /boot/loader.conf <<'__LDR_EOF__'
# ThinkPad T14 Gen 1 (per vermaden)
autoboot_delay="2"
hw.usb.no_boot_wait="1"
acpi_ibm_load="YES"
acpi_video_load="YES"
coretemp_load="YES"
cpu_microcode_load="YES"
cpu_microcode_name="/boot/firmware/intel-ucode.bin"
aesni_load="YES"
cryptodev_load="YES"
hw.psm.synaptics_support="1"
# drm-kmod power savings
compat.linuxkpi.semaphores="1"
compat.linuxkpi.enable_rc6="7"
compat.linuxkpi.enable_dc="2"
compat.linuxkpi.enable_fbc="1"
# Disable disk-label noise
kern.geom.label.disk_ident.enable="0"
kern.geom.label.gptid.enable="0"
# GELI threads for AES-NI
kern.geom.eli.threads="4"
# Power off unused PCI devices
hw.pci.do_power_nodriver="3"
__LDR_EOF__

if [ -n "$TARGET_ADMIN_USER" ]; then
    pw groupmod video    -m "$TARGET_ADMIN_USER" 2>/dev/null || true
    pw groupmod operator -m "$TARGET_ADMIN_USER" 2>/dev/null || true
fi

env ASSUME_ALWAYS_YES=YES pkg install -y \
    drm-kmod \
    devcpu-data \
    || true
