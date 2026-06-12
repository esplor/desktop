#!/usr/bin/env bash
set -euo pipefail

# Build dependencies (run once, manually):
# sudo apt install cargo libwayland-dev libegl1-mesa-dev pkg-config libglib2.0-dev libpipewire-0.3-dev libudev-dev libseat-dev libcairo2-dev libpango1.0-dev libdisplay-info-dev libinput-dev libxkbcommon-dev libgbm-dev

cd "$(dirname "$0")/niri"
cargo build --release
install -Dm755 target/release/niri ~/.local/bin/niri
