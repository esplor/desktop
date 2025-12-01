sudo apt install cargo libwayland-egl-backend-dev libwayland-dev libegl1-mesa-dev pkg-config libglib2.0-dev libpipewire-0.3-dev libudev-dev libseat-dev libcairo2-dev libpango1.0-dev libdisplay-info-dev libinput-dev libxkbcommon-dev libgbm-dev xdg-utils xdg-desktop-portal-wlr alacritty waybar
cd niri && cargo build --release
mkdir -p ~/.local/bin && cp target/release/niri ~/.local/bin/
