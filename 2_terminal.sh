#!/bin/bash
# Arch Linux Terminal Installation Script

set -e

source "$(dirname "$0")/common.sh"

log "Starting terminal installation"

# ===== Update system =====
log "Updating system"
sudo pacman -Syu --noconfirm

# ===== Install terminal emulator =====
log "Installing Ghostty terminal"
sudo pacman -S --needed --noconfirm ghostty

# ===== Configure Ghostty =====
log "Configuring Ghostty"

GHOSTTY_CONFIG_DIR="${HOME}/.config/ghostty"

install -d -m 0755 "${GHOSTTY_CONFIG_DIR}"

if [[ -f "./config/ghostty/config" ]]; then
  log "Copying Ghostty configuration"
  cp ./config/ghostty/config "${GHOSTTY_CONFIG_DIR}/config"
  chmod 600 "${GHOSTTY_CONFIG_DIR}/config"
else
  log "Ghostty config file not found at ./config/ghostty/config"
fi

log "Terminal installation complete"