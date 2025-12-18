#!/bin/bash
# Arch Linux Base-Installation Script

set -e

source "$(dirname "$0")/common.sh"

# ===== Sudo authentication =====
sudo -v

# ===== Time synchronization =====
log "Enabling time synchronization"
timedatectl set-ntp true

# ===== Install yay =====
log "Installing yay (AUR helper)"
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..

log "Base-installation complete"
