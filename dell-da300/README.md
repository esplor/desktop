# Dell DA300 HDMI out on Linux

Working on Debian 13 (trixie) + niri (Wayland) on Lenovo ThinkBook 16p G2 ACH (`20YM`).

## Hardware

- Laptop: Lenovo ThinkBook 16p G2 ACH, BIOS `GXCN50WW`
- iGPU: AMD Cezanne (`05:00.0`)
- dGPU: NVIDIA RTX 3060 Mobile, GA106M (`01:00.0`)
- Dongle: Dell DA300, Bizlink USB ID `06c4:c412`

## Why this needs special setup

The USB-C DP alt-mode lanes on this laptop are MUXed in firmware to the **NVIDIA dGPU**, not the AMD iGPU. With the dGPU blacklisted or absent in Linux, no GPU receives the lanes and nothing lights up. The iGPU's `card0-DP-*` connectors never see the dongle.

The DP routing happens at the EC / MUX firmware level, below the kernel `typec_displayport` / UCSI subsystem. `number_of_alternate_modes` stays `0` even when HDMI is working. Do not chase that, it's not the signal. The real signal is `card1-DP-*` going `connected` once nvidia is loaded.

## Setup

### 1. Use a kernel that nvidia 550.x supports

Debian's `nvidia-driver` is currently 550.163.01 in both trixie main and trixie-backports. It **does not build** against trixie-backports kernels ≥ 6.19. Stay on the trixie stable kernel (6.12.x).

If you've been on a backports kernel:

```bash
sudo apt install linux-image-amd64/trixie linux-headers-amd64/trixie linux-base/trixie linux-libc-dev/trixie
sudo update-grub
# reboot, pick the 6.12.x entry in GRUB "Advanced options for Debian"
uname -r   # confirm 6.12.x
```

### 2. Install firmware and driver

```bash
sudo apt install firmware-misc-nonfree nvidia-driver
```

Verify after install:

```bash
dkms status | grep nvidia    # want "installed" against the running kernel
```

### 3. Configure for Wayland

```bash
sudo tee /etc/modprobe.d/nvidia-wayland.conf >/dev/null <<'EOF'
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia-drm modeset=1
options nvidia-drm fbdev=1
EOF
sudo update-initramfs -u
```

`modeset=1` is required for nvidia to expose itself as a Wayland-capable DRM device. `PreserveVideoMemoryAllocations=1` is required for clean suspend/resume on laptops.

### 4. Confirm no leftover blacklist

`/etc/modprobe.d/` must not contain any file that blacklists `nvidia`, `nvidia_drm`, `nvidia_modeset`, etc. The package installs `nvidia-blacklists-nouveau.conf` (blacklists nouveau only) which is correct. Any prior `blacklist-nvidia.conf` from battery-saver setups must be removed:

```bash
grep -r '^[[:space:]]*blacklist[[:space:]]\+nvidia' /etc/modprobe.d/
# any hits here will prevent nvidia from auto-loading on boot
```

### 5. Reboot and verify

```bash
sudo reboot
```

After login, in a terminal:

```bash
lsmod | grep nvidia_drm       # must list nvidia_drm
ls /sys/class/drm/             # must show card1 alongside card0
nvidia-smi                     # must list the RTX 3060
```

Plug the DA300 in. Then:

```bash
./da300-check.sh
niri msg outputs
```

You should see `card1-DP-3` (or DP-4) flip to `connected` and a new output appear in niri.

## Trade-off

Loading nvidia keeps the dGPU active. Idle draw is ~9 W per `nvidia-smi`, with corresponding battery / heat cost. If battery is more important than the external display, restore a blacklist file (`blacklist nvidia`, `nvidia_drm`, `nvidia_modeset`, `nvidia_uvm`, `nvidiafb`, plus `nouveau`) and rebuild initramfs.

## References

- Debian wiki, NvidiaGraphicsDrivers: <https://wiki.debian.org/NvidiaGraphicsDrivers>
- Lenovo PSREF, ThinkBook 16p G2 ACH: <https://psref.lenovo.com/syspool/Sys/PDF/ThinkBook/ThinkBook_16p_G2_ACH/ThinkBook_16p_G2_ACH_Spec.html>
