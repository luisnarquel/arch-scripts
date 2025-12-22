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

# ===== Configure SDDM =====
log "Configuring SDDM"
sudo mkdir -p /etc/sddm.conf.d

cat <<EOF | sudo tee /etc/sddm.conf.d/autologin.conf
[General]
DisplayServer=wayland

[Autologin]
User=$USER
Session=hyprland-uwsm

[Theme]
Current=breeze
EOF

# ===== Enable SDDM service =====
log "Enabling SDDM service"
sudo systemctl enable sddm.service

# ===== Completion =====
log "SDDM installation complete"
warn "Reboot REQUIRED"