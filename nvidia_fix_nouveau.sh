#!/bin/bash
# Fix NVIDIA driver by removing nouveau conflict

set -e

source "$(dirname "$0")/common.sh"

log "=== Fixing NVIDIA Driver (Removing Nouveau Conflict) ==="
echo ""

# ===== Blacklist nouveau =====
log "Blacklisting nouveau driver"
sudo mkdir -p /etc/modprobe.d
NOUVEAU_CONF="/etc/modprobe.d/blacklist-nouveau.conf"
if [ ! -f "$NOUVEAU_CONF" ]; then
  echo "blacklist nouveau" | sudo tee "$NOUVEAU_CONF" > /dev/null
  echo "options nouveau modeset=0" | sudo tee -a "$NOUVEAU_CONF" > /dev/null
  log "Nouveau blacklist created"
else
  log "Nouveau already blacklisted"
fi

# ===== Rebuild initramfs =====
log "Rebuilding initramfs to apply nouveau blacklist"
sudo mkinitcpio -P

# ===== Unload nouveau module =====
log "Attempting to unload nouveau module"
sudo modprobe -r nouveau 2>&1 || warn "Could not unload nouveau (may require reboot)"

# ===== Try loading nvidia =====
log "Attempting to load nvidia module"
sudo modprobe nvidia 2>&1 || warn "Could not load nvidia (may require reboot)"

echo ""
log "=== Fix Complete ==="
warn "REBOOT REQUIRED to fully apply changes"
echo ""
echo "After reboot, verify with:"
echo "  nvidia-smi"
echo "  lsmod | grep nvidia"
echo "  lsmod | grep nouveau"
