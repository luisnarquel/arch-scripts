#!/bin/bash
# NVIDIA Driver Debugging Script

set -e

source "$(dirname "$0")/common.sh"

log "=== NVIDIA Driver Diagnostic Report ==="
echo ""

log "1. Checking if NVIDIA packages are installed"
pacman -Q nvidia nvidia-utils 2>/dev/null || warn "NVIDIA packages not found"
echo ""

log "2. Checking kernel version"
uname -r
echo ""

log "3. Checking if nvidia kernel module is loaded"
lsmod | grep nvidia || warn "NVIDIA module not loaded"
echo ""

log "4. Checking dmesg for NVIDIA errors"
dmesg | grep -i nvidia | tail -20 || log "No NVIDIA messages in dmesg"
echo ""

log "5. Checking Secure Boot status"
mokutil --sb-state 2>/dev/null || log "mokutil not available (Secure Boot may not be enabled)"
echo ""

log "6. Checking /etc/modprobe.d/nvidia.conf"
if [ -f /etc/modprobe.d/nvidia.conf ]; then
  cat /etc/modprobe.d/nvidia.conf
else
  warn "nvidia.conf not found"
fi
echo ""

log "7. Checking mkinitcpio.conf MODULES line"
grep "^MODULES=" /etc/mkinitcpio.conf
echo ""

log "8. Attempting to load nvidia module manually"
sudo modprobe nvidia 2>&1 || warn "Failed to load nvidia module"
echo ""

log "9. Checking if nvidia-smi binary exists"
which nvidia-smi || warn "nvidia-smi not found"
echo ""

log "10. Checking NVIDIA driver version"
cat /proc/driver/nvidia/version 2>/dev/null || warn "Cannot read driver version"
echo ""

log "=== End of Diagnostic Report ==="
