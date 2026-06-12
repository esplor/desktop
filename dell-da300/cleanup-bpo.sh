#!/usr/bin/env bash
# Remove leftover trixie-backports kernels + downgrade missed nvidia helpers
# to trixie. Keeps hardware firmware on bpo (newer is fine).
# Safety: refuses to remove the currently running kernel.

set -euo pipefail

RUNNING=$(uname -r)
echo "Running kernel: $RUNNING"
echo

KERNELS_TO_REMOVE=(
    linux-image-6.16.12+deb13-amd64
    linux-image-6.16.3+deb13-amd64
    linux-image-6.17.13+deb13-amd64
    linux-image-6.17.8+deb13-amd64
    linux-image-6.18.12+deb13-amd64
    linux-image-6.18.5+deb13-amd64
    linux-image-6.18.9+deb13-amd64
    linux-image-6.19.10+deb13-amd64
    linux-image-6.19.11+deb13-amd64
    linux-image-6.19.13+deb13-amd64
    linux-image-6.19.6+deb13-amd64
    linux-image-6.19.8+deb13-amd64
)

# Defensive: never remove the running kernel
for k in "${KERNELS_TO_REMOVE[@]}"; do
    if [[ "$k" == *"$RUNNING"* ]]; then
        echo "ABORT: removal list contains running kernel ($RUNNING). Refusing."
        exit 1
    fi
done

echo "Step 1: removing ${#KERNELS_TO_REMOVE[@]} old bpo kernels..."
sudo apt remove --purge -y "${KERNELS_TO_REMOVE[@]}"

echo
echo "Step 2: apt autoremove (drops orphaned headers/modules)..."
sudo apt autoremove --purge -y

echo
echo "Step 3: rebuilding GRUB menu..."
sudo update-grub

echo
echo "Step 4: downgrading nvidia helpers from bpo to trixie..."
sudo apt install -y --allow-downgrades \
    nvidia-egl-common/trixie \
    nvidia-kernel-support/trixie \
    nvidia-legacy-check/trixie \
    nvidia-suspend-common/trixie \
    nvidia-vulkan-common/trixie

echo
echo "Step 5: ensuring dkms is installed..."
sudo apt install -y dkms --allow-downgrades

echo
echo "Step 6: dkms status (want: nvidia 'installed' against $RUNNING):"
sudo dkms status || true

echo
echo "Step 7: remaining bpo packages (should be only firmware-* now):"
dpkg-query -W -f='${binary:Package}\t${Version}\n' | awk '/~bpo/ {print "  "$1"\t"$2}'

echo
echo "Done."
