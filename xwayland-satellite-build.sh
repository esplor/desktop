#!/usr/bin/env bash
set -euo pipefail

# Build dependencies (run once, manually):
# sudo apt install cargo clang libxcb1-dev libxcb-cursor-dev xwayland

cd "$(dirname "$0")/xwayland-satellite"
cargo build --release
install -Dm755 target/release/xwayland-satellite ~/.local/bin/xwayland-satellite
