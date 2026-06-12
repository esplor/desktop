#!/usr/bin/env bash
# DA300 / USB-C alt-mode diagnostic. Run with DA300 plugged in.
# Paste the full output back to Claude.

set -u

hr() { printf '\n=== %s ===\n' "$1"; }

hr "kernel / date"
uname -r
date -Is

hr "port0-partner/number_of_alternate_modes (key signal: >=1 means DP alt mode discovered)"
cat /sys/class/typec/port0-partner/number_of_alternate_modes 2>&1 || echo "missing"

hr "ls /sys/class/typec/port0-partner/ (identity/ dir = Discover Identity ran)"
ls /sys/class/typec/port0-partner/ 2>&1 || echo "missing"

hr "alt-mode subdirs (port0-partner.N)"
ls -d /sys/class/typec/port0-partner.* 2>/dev/null || echo "none"
for d in /sys/class/typec/port0-partner.*/; do
    [ -d "$d" ] || continue
    echo "--- $d"
    for f in svid mode active vdo; do
        [ -e "$d$f" ] && echo "$f: $(cat "$d$f" 2>&1)"
    done
done

hr "DRM DP connector status"
for c in /sys/class/drm/card*-DP-*/status; do
    [ -e "$c" ] && echo "$c: $(cat "$c")"
done

hr "port0 basics"
for f in usb_typec_revision power_role data_role; do
    [ -e "/sys/class/typec/port0/$f" ] && echo "$f: $(cat /sys/class/typec/port0/$f)"
done

hr "port0-partner basics"
for f in usb_power_delivery_revision power_operation_mode supports_usb_power_delivery; do
    [ -e "/sys/class/typec/port0-partner/$f" ] && echo "$f: $(cat /sys/class/typec/port0-partner/$f)"
done

hr "loaded typec / ucsi / dp modules"
lsmod | grep -iE "typec|ucsi|displayport" || echo "none"

hr "dmesg: typec / ucsi / alt-mode / displayport (last 60)"
sudo dmesg | grep -iE "typec|ucsi|alt.?mode|displayport" | tail -60

hr "niri outputs"
command -v niri >/dev/null && niri msg outputs 2>&1 || echo "niri not in PATH or not running"

hr "DA300 USB presence (06c4:c412)"
lsusb | grep -i "06c4:c412" || echo "not enumerated"

hr "done"
