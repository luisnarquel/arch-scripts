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
sudo pacman -S --needed --noconfirm nvidia-utils nvidia-settings
sudo pacman -S --needed --noconfirm nvidia-open-dkms
sudo pacman -S --needed --noconfirm lib32-nvidia-utils libva-nvidia-driver

# ===== Enable early KMS (mkinitcpio) =====
log "Enabling early KMS in initramfs"

MKINIT="/etc/mkinitcpio.conf"
MODULES_LINE="MODULES=(i915 nvidia nvidia_modeset nvidia_uvm nvidia_drm)"

if ! grep -q "nvidia_drm" "$MKINIT"; then
  sudo sed -i "s/^MODULES=.*/$MODULES_LINE/" "$MKINIT"
else
  log "NVIDIA modules already present in mkinitcpio"
fi

# ===== Rebuild initramfs =====
log "Rebuilding initramfs"
sudo mkinitcpio -P

# ===== Completion =====
log "NVIDIA drivers installation complete"
warn "Reboot REQUIRED"
echo ""
echo "After reboot, verify with:"
echo "  nvidia-smi"
echo "  cat /sys/module/nvidia_drm/parameters/modeset"
