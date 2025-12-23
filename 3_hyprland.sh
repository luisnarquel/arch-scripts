#!/bin/bash
# Arch Linux Hyprland Installation Script

set -e

source "$(dirname "$0")/common.sh"

log "Starting Hyprland installation"

# ===== Update system =====
log "Updating system"
sudo pacman -Syu --noconfirm

# ===== Install Hyprland and dependencies =====
log "Installing Hyprland"
sudo pacman -S --needed --noconfirm egl-wayland
sudo pacman -S --needed --noconfirm qt5-wayland qt6-wayland
sudo pacman -S --needed --noconfirm hyprland kitty

# ===== Configure Hyprland =====
log "Configuring Hyprland"

HYPRLAND_CONFIG_DIR="${HOME}/.config/hypr"
SCRIPT_DIR="$(dirname "$0")"
SOURCE_CONFIG="${SCRIPT_DIR}/config/hyprland/hyprland.conf"

install -d -m 0755 "${HYPRLAND_CONFIG_DIR}"

log "Copying Hyprland config file"
cp "${SOURCE_CONFIG}" "${HYPRLAND_CONFIG_DIR}/hyprland.conf"

log "Hyprland installation complete"