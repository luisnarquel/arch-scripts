#!/bin/bash
# Arch Linux NVIDIA Drivers Installation Script

set -e

source "$(dirname "$0")/common.sh"

log "Starting NVIDIA drivers installation"

# ===== Update system =====
log "Updating system"
sudo pacman -Syu --noconfirm

# ===== Install dependencies =====
sudo pacman -S --needed --noconfirm linux-headers

# ===== Install NVIDIA proprietary drivers =====
log "Installing NVIDIA proprietary drivers"
sudo pacman -S --needed --noconfirm \
  nvidia-utils \
  nvidia-settings
sudo pacman -S --needed --noconfirm nvidia-open-dkms

# ===== Completion =====
log "NVIDIA drivers installation complete"
warn "Reboot REQUIRED"
echo ""
echo "After reboot, verify with:"
echo "  nvidia-smi"
echo "  cat /sys/module/nvidia_drm/parameters/modeset"
