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

# ===== Configure Hyprland environment variables =====
log "Configuring Hyprland environment variables"

HYPRLAND_CONFIG_DIR="${HOME}/.config/hypr"
HYPRLAND_CONFIG="${HYPRLAND_CONFIG_DIR}/hyprland.conf"

install -d -m 0755 "${HYPRLAND_CONFIG_DIR}"

if [[ ! -f "${HYPRLAND_CONFIG}" ]]; then
  log "Creating Hyprland config file"
  touch "${HYPRLAND_CONFIG}"
fi

# Add NVIDIA environment variables if not already present
if ! grep -q "LIBVA_DRIVER_NAME" "${HYPRLAND_CONFIG}"; then
  log "Adding NVIDIA environment variables to Hyprland config"
  
  # Create temporary file with variables at the top
  {
    echo "# NVIDIA environment variables"
    echo "env = LIBVA_DRIVER_NAME,nvidia"
    echo "env = __GLX_VENDOR_LIBRARY_NAME,nvidia"
    echo "env = ELECTRON_OZONE_PLATFORM_HINT,auto"
    echo "env = NVD_BACKEND,direct"
    echo ""
    cat "${HYPRLAND_CONFIG}"
  } > "${HYPRLAND_CONFIG}.tmp"
  
  mv "${HYPRLAND_CONFIG}.tmp" "${HYPRLAND_CONFIG}"
else
  log "NVIDIA environment variables already present in Hyprland config"
fi

log "Hyprland installation complete"