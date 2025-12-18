#!/bin/bash
# NVIDIA Hardware Detection Script

set -e

source "$(dirname "$0")/common.sh"

log "=== NVIDIA Hardware Detection ==="
echo ""

log "1. Checking PCI devices for NVIDIA GPU"
lspci | grep -i nvidia || warn "No NVIDIA GPU found in lspci"
echo ""

log "2. Checking all PCI devices (full list)"
lspci
echo ""

log "3. Checking lsusb for NVIDIA devices"
lsusb | grep -i nvidia || log "No NVIDIA devices in USB"
echo ""

log "4. Checking /proc/bus/pci for NVIDIA"
find /proc/bus/pci -type f -exec grep -l "NVIDIA\|nvidia" {} \; 2>/dev/null || log "No NVIDIA in /proc/bus/pci"
echo ""

log "5. Checking if nouveau driver is loaded (conflicts with nvidia)"
lsmod | grep nouveau && warn "NOUVEAU driver is loaded - this conflicts with NVIDIA!" || log "Nouveau not loaded (good)"
echo ""

log "6. Checking kernel parameters"
cat /proc/cmdline
echo ""

log "7. Checking BIOS/UEFI settings (if accessible)"
dmidecode -s system-product-name 2>/dev/null || log "Cannot read BIOS info"
echo ""

log "8. Checking GPU power state"
cat /sys/class/drm/*/status 2>/dev/null || log "Cannot read display status"
echo ""

log "=== End of Hardware Detection ==="
