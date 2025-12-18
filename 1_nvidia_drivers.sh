#!/bin/bash
# Arch Linux NVIDIA Drivers Installation Script

set -e

source "$(dirname "$0")/common.sh"

log "Starting NVIDIA drivers installation"

# ===== Blacklist nouveau driver =====
log "Blacklisting nouveau driver"
sudo mkdir -p /etc/modprobe.d
NOUVEAU_CONF="/etc/modprobe.d/blacklist-nouveau.conf"
if [ ! -f "$NOUVEAU_CONF" ]; then
  echo "blacklist nouveau" | sudo tee "$NOUVEAU_CONF" > /dev/null
  echo "options nouveau modeset=0" | sudo tee -a "$NOUVEAU_CONF" > /dev/null
else
  log "Nouveau already blacklisted"
fi

# ===== Update system =====
log "Updating system"
sudo pacman -Syu --noconfirm

# ===== Install NVIDIA proprietary drivers =====
log "Installing NVIDIA proprietary drivers"
sudo pacman -S --needed --noconfirm \
  nvidia \
  nvidia-utils \
  nvidia-settings \
  egl-wayland

# ===== Enable NVIDIA DRM modeset =====
log "Enabling NVIDIA DRM modeset"
sudo mkdir -p /etc/modprobe.d
NVIDIA_CONF="/etc/modprobe.d/nvidia.conf"
MODESET_LINE="options nvidia_drm modeset=1"

if ! sudo grep -q "$MODESET_LINE" "$NVIDIA_CONF" 2>/dev/null; then
  echo "$MODESET_LINE" | sudo tee "$NVIDIA_CONF" > /dev/null
else
  log "DRM modeset already enabled"
fi

# ===== Enable early KMS (mkinitcpio) =====
log "Enabling early KMS in initramfs"
MKINIT="/etc/mkinitcpio.conf"
MODULES_LINE="MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)"

if ! grep -q "nvidia_drm" "$MKINIT"; then
  sudo sed -i "s/^MODULES=.*/$MODULES_LINE/" "$MKINIT"
else
  log "NVIDIA modules already present in mkinitcpio"
fi

# ===== Rebuild initramfs =====
log "Rebuilding initramfs"
sudo mkinitcpio -P

# ===== Enable persistence daemon =====
log "Enabling NVIDIA persistence daemon"
sudo systemctl enable --now nvidia-persistenced.service || true

# ===== Completion =====
log "NVIDIA drivers installation complete"
warn "Reboot REQUIRED"
echo ""
echo "After reboot, verify with:"
echo "  nvidia-smi"
echo "  cat /sys/module/nvidia_drm/parameters/modeset"
