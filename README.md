<p align="center">
  <img src="https://www.freebsd.org/images/FreeBSD-logo-light.png" alt="FreeBSD" width="360">
</p>

# FreeBSD-AutoInstaller

**Author:** Dmitry Kalashnikov

Super fast no prompts auto installer that allows me to install FreeBSD, my Omarchy port and configure it as I like it. Its targeted for specific laptops (see bsd-laptops repo). We want complete end-to-end automation so everything works perfect on laptops.

## Usage

On a FreeBSD host with a blank USB stick plugged in:

```sh
sh build-memstick.sh                       # generic install
sh build-memstick.sh thinkpad-nano-gen2    # ThinkPad X1 Nano Gen 2
sh build-memstick.sh thinkpad-t14-gen1     # ThinkPad T14 Gen 1 (Intel)
sh build-memstick.sh thinkpad-t480         # ThinkPad T480
sh build-memstick.sh thinkpad-e15-gen2     # ThinkPad E15 Gen 2
sh build-memstick.sh thinkpad-x230t        # ThinkPad X230 Tablet
```

This will create a usb stick with automated FreeBSD installer just for your laptop.

The script:

- re-execs itself under `doas`/`sudo` if you're not root
- auto-detects the USB stick (or pass `-d /dev/daN` to force one)
- fetches + SHA256-verifies the memstick image (cached, resumable)
- injects the auto-installer `installerconfig`
- flashes with a 5-second countdown (Ctrl-C to abort)

Refuses `/dev/ada*`, `/dev/nda*`, `/dev/nvme*` as flash targets so you
can't nuke the build host by accident.

## What the target asks you (only on the target, not the build host)

1. Hostname
2. Admin username (added to `wheel`)
3. Admin password
4. Encrypt the disk? → GELI passphrase
5. Configure Wi-Fi? → SSID + passphrase

`root` is locked; escalate from the admin user via `doas`/`sudo`.

## Layout

| Path | Purpose |
|---|---|
| [build-memstick.sh](build-memstick.sh) | The one command. |
| [installerconfig.template](installerconfig.template) | Baked into `/etc/installerconfig` on the memstick. |
| [profiles/](profiles) | Per-machine profiles (`thinkpad-nano-gen2.sh`, …). |
| [hardware/](hardware) | Chroot fragments applying hardware-specific tuning. |
| [postinstall/](postinstall) | First-boot layers (`omarchy.sh`, …). |
| [config.sh.example](config.sh.example) | Optional; only if you want to override defaults. |

## Example: ThinkPad X1 Nano Gen 2 profile

`sh build-memstick.sh thinkpad-nano-gen2` gives you an installer that:

- Partitions the NVMe (`nda0`) as UEFI + ZFS + GELI.
- Installs Intel Iris Xe KMS (`i915kms`, `drm-kmod`).
- Wires Intel AX211 Wi-Fi (`if_iwlwifi` + `wifi-firmware-kmod`).
- Loads `acpi_ibm`, `coretemp`, Intel CPU microcode (`devcpu-data`).
- Enables `powerd` (`hiadaptive`/`adaptive`).
- Adds the admin user to `video` and `operator`.
- Arms `omarchy_firstboot`: on first boot, clones
  [`klimb/freebsd-omarchy`](https://github.com/klimb/freebsd-omarchy),
  runs `bootstrap/install.sh` as the admin user, then disables itself.
  Watch it with `tail -f /var/log/omarchy-firstboot.log`; when done,
  run `omg` to enter Hyprland.

## Extending

- **New machine:** add [profiles/mymachine.sh](profiles) setting
  `TARGET_DISK`, `DEFAULT_*`, `HARDWARE_PROFILE`, `POSTINSTALL_LAYERS`;
  invoke with `sh build-memstick.sh mymachine`. Verified per-model
  `rc.conf`/`loader.conf`/`dmesg` data lives in
  [`klimb/bsd-laptops`](https://github.com/klimb/bsd-laptops) — that's
  the reference source when authoring a new profile.
- **New hardware fragment:** add [hardware/mymachine.sh](hardware); its
  contents are pasted into the chroot script after base install.
- **New post-install layer:** add [postinstall/mylayer.sh](postinstall);
  reference it via `POSTINSTALL_LAYERS="mylayer …"` in a profile.

## Related repositories

- [`klimb/freebsd-omarchy`](https://github.com/klimb/freebsd-omarchy) —
  Omarchy's Hyprland/Wayland desktop, ported to FreeBSD (`seatd`,
  `doas`, `wpa_supplicant`, `bhyve`/`jails` instead of Docker). Installed
  on first boot by the [`omarchy`](postinstall/omarchy.sh) layer.
- [`klimb/bsd-laptops`](https://github.com/klimb/bsd-laptops) — verified
  per-model FreeBSD/OpenBSD configs (`etc/`, `loader.conf`, `dmesg`,
  compatibility reports). The reference source when authoring new
  entries under [profiles/](profiles) and [hardware/](hardware).
