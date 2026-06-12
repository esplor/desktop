#!/usr/bin/env bash
# One-off diagnostic: temporarily bring up the NVIDIA dGPU with nouveau and
# see if the DA300's DP alt mode now negotiates.
#
# blacklist only blocks auto-load via udev; `modprobe nouveau` directly still
# works. This does NOT modify the blacklist file. After the test, either
# `sudo modprobe -r nouveau` (and nouveau_drm/_kms) or just reboot to return
# to the blacklisted state.
#
# Run with the DA300 plugged in.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

hr() { printf '\n=== %s ===\n' "$1"; }

hr "kernel / date"
uname -r
date -Is

hr "before: drm cards"
ls /sys/class/drm/

hr "before: nvidia PCI device state"
cat /sys/bus/pci/devices/0000:01:00.0/enable
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status

hr "loading nouveau (will spin up dGPU, expect heat / battery drain)"
sudo modprobe nouveau
sleep 3

hr "after: modules"
lsmod | grep -iE 'nouveau|drm' | head -20

hr "after: drm cards (looking for new card1 + card1-DP-*)"
ls /sys/class/drm/

hr "after: nvidia PCI device state"
cat /sys/bus/pci/devices/0000:01:00.0/enable
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
drv=$(readlink /sys/bus/pci/devices/0000:01:00.0/driver 2>/dev/null)
echo "driver: ${drv:+$(basename "$drv")}${drv:-none}"

hr "all DP connector status"
for c in /sys/class/drm/card*-DP-*/status; do
    [ -e "$c" ] && echo "$c: $(cat "$c")"
done
for c in /sys/class/drm/card*-HDMI*/status; do
    [ -e "$c" ] && echo "$c: $(cat "$c")"
done

hr "nouveau dmesg (last 40)"
sudo dmesg | grep -iE 'nouveau|nvkm' | tail -40

hr "running da300-check.sh (alt mode side)"
"$SCRIPT_DIR/da300-check.sh"

hr "niri outputs (post-load)"
command -v niri >/dev/null && niri msg outputs 2>&1 || echo "niri not available"

hr "done. to undo without reboot: sudo modprobe -r nouveau"
