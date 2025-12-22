#!/bin/bash
# Arch Linux UWSM Installation Script

set -e

source "$(dirname "$0")/common.sh"

log "Starting UWSM installation"

# ===== Update system =====
log "Updating system"
sudo pacman -Syu --noconfirm

# ===== Install UWSM and dependencies =====
log "Installing UWSM"
sudo pacman -S --needed --noconfirm uwsm
sudo pacman -S --needed --noconfirm xdg-desktop-portal xdg-desktop-portal-hyprland

# ===== Completion =====
log "UWSM installation complete"
