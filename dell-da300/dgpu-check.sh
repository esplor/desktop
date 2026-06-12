#!/usr/bin/env bash
# NVIDIA dGPU state check. We expect the card to be present on PCI but with
# no driver bound, because nouveau + nvidia* are blacklisted to save battery.
# This script confirms that and shows current power state.

set -u

hr() { printf '\n=== %s ===\n' "$1"; }

hr "kernel / date"
uname -r
date -Is

hr "lspci: GPUs (10de = NVIDIA, 1002 = AMD)"
lspci -nn | grep -iE 'vga|3d|display'

hr "blacklist file"
cat /etc/modprobe.d/blacklist-nvidia.conf 2>&1 || echo "missing"

hr "modules loaded (nvidia/nouveau should be absent)"
lsmod | grep -iE 'nvidia|nouveau' || echo "none loaded (expected)"

hr "kernel cmdline (look for nouveau.blacklist=1, modprobe.blacklist=..., pcie_aspm=, etc.)"
cat /proc/cmdline

hr "per-NVIDIA-device state"
for d in /sys/bus/pci/devices/*; do
    vendor=$(cat "$d/vendor" 2>/dev/null)
    [ "$vendor" = "0x10de" ] || continue
    echo "--- $d"
    echo "  device:           $(cat "$d/device" 2>/dev/null)"
    echo "  class:            $(cat "$d/class" 2>/dev/null)"
    drv=$(readlink "$d/driver" 2>/dev/null)
    echo "  driver:           ${drv:+$(basename "$drv")}${drv:-none}"
    echo "  power/control:    $(cat "$d/power/control" 2>/dev/null)"
    echo "  power/runtime_status: $(cat "$d/power/runtime_status" 2>/dev/null)"
    echo "  power_state:      $(cat "$d/power_state" 2>/dev/null)"
    echo "  enable:           $(cat "$d/enable" 2>/dev/null)"
done

hr "DRM cards registered (only iGPU expected with dGPU blacklisted)"
ls -l /sys/class/drm/ 2>&1 | grep -E 'card[0-9]+ ' || ls /sys/class/drm/

hr "ACPI _DSM / Optimus hints in dmesg"
sudo dmesg | grep -iE 'optimus|_dsm|nvidia|nouveau|vga_switcheroo|prime' | tail -30 || echo "no hits"

hr "vga_switcheroo (if present, shows MUX state)"
[ -e /sys/kernel/debug/vgaswitcheroo/switch ] && sudo cat /sys/kernel/debug/vgaswitcheroo/switch || echo "not present (no MUX exposed, likely Optimus mux-less)"

hr "done"
