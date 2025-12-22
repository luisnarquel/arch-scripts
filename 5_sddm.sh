#!/bin/bash
# Arch Linux SDDM Installation Script

set -e

source "$(dirname "$0")/common.sh"

log "Starting SDDM installation"

# ===== Update system =====
log "Updating system"
sudo pacman -Syu --noconfirm

# ===== Install SDDM and dependencies =====
log "Installing SDDM"
sudo pacman -S --needed --noconfirm sddm
sudo pacman -S --needed --noconfirm qt5-graphicaleffects qt5-quickcontrols2
sudo pacman -S --needed --noconfirm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg

# ===== Create Hyprland UWSM session file =====
log "Creating Hyprland UWSM session file"
sudo mkdir -p /usr/share/wayland-sessions

cat <<'EOF' | sudo tee /usr/share/wayland-sessions/hyprland-uwsm.desktop
[Desktop Entry]
Name=Hyprland (UWSM)
Comment=Hyprland started via UWSM
Exec=uwsm start hyprland
Type=Application
 DesktopNames=Hyprland
EOF

# ===== Install SDDM Silvia Theme =====
log "Installing SDDM Silvia theme"
SCRIPT_DIR="$(dirname "$0")"
SDDM_CONFIG_PATH="$SCRIPT_DIR/config/sddm"
THEME_NAME="silvia"
THEME_PATH="/usr/share/sddm/themes/$THEME_NAME"

if [ ! -d "$SDDM_CONFIG_PATH" ]; then
	warn "SDDM configuration directory not found at $SDDM_CONFIG_PATH"
	warn "Skipping theme installation"
else
	log "Copying theme files to $THEME_PATH"
	sudo mkdir -p "$THEME_PATH"
	sudo cp -rf "$SDDM_CONFIG_PATH"/* "$THEME_PATH"/

	log "Copying theme fonts to /usr/share/fonts"
	sudo mkdir -p /usr/share/fonts
	sudo cp -r "$THEME_PATH"/fonts/{redhat,redhat-vf} /usr/share/fonts/

	log "Updating metadata.desktop to use Silvia configuration"
	sudo sed -i 's/^ConfigFile=configs\/default\.conf$/ConfigFile=configs\/silvia.conf/' "$THEME_PATH"/metadata.desktop
fi

# ===== Configure SDDM =====
log "Configuring SDDM"
sudo mkdir -p /etc/sddm.conf.d

cat <<EOF | sudo tee /etc/sddm.conf.d/autologin.conf
[General]
DisplayServer=wayland
InputMethod=qtvirtualkeyboard
GreeterEnvironment=QML2_IMPORT_PATH=/usr/share/sddm/themes/$THEME_NAME/components/,QT_IM_MODULE=qtvirtualkeyboard

[Autologin]
User=$USER
Session=hyprland-uwsm

[Theme]
Current=$THEME_NAME
EOF

# ===== Enable SDDM service =====
log "Enabling SDDM service"
sudo systemctl enable sddm.service

# ===== Completion =====
log "SDDM installation complete"
warn "Reboot REQUIRED"