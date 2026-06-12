#!/usr/bin/env bash
# Write /etc/modprobe.d/nvidia-wayland.conf and rebuild initramfs.
# Also dumps every file in /etc/modprobe.d/ so you can confirm nothing else
# is fighting (stale blacklist-nvidia.conf, leftover snippets, etc).
# Backs up an existing nvidia-wayland.conf if present.

set -euo pipefail

MPD=/etc/modprobe.d
CONF="$MPD/nvidia-wayland.conf"
TS=$(date +%Y%m%d-%H%M%S)

echo "=== current files in $MPD ==="
ls -la "$MPD"

echo
echo "=== contents of every file in $MPD ==="
for f in "$MPD"/*; do
    [ -f "$f" ] || continue
    echo
    echo "--- $f ---"
    cat "$f"
done

echo
if [ -e "$CONF" ]; then
    echo "Existing $CONF found, backing up to $CONF.bak.$TS"
    sudo cp -a "$CONF" "$CONF.bak.$TS"
fi

echo "Writing $CONF..."
sudo tee "$CONF" >/dev/null <<'EOF'
# Wayland / niri config for nvidia proprietary driver.
# PreserveVideoMemoryAllocations: required for clean suspend/resume on laptops.
# nvidia-drm modeset=1: required for KMS / Wayland.
# nvidia-drm fbdev=1: gives nvidia an fbdev console.
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia-drm modeset=1
options nvidia-drm fbdev=1
EOF

echo
echo "=== new $CONF ==="
cat "$CONF"

echo
echo "=== rebuilding initramfs ==="
sudo update-initramfs -u

echo
echo "Done. Reboot, then in TTY verify:"
echo "  lsmod | grep nvidia       # want nvidia_drm present"
echo "  nvidia-smi                 # want RTX 3060 listed"
echo "  ls /sys/class/drm/         # want card1 alongside card0"
