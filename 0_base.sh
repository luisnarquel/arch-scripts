#!/bin/bash
# Arch Linux Base-Installation Script

set -e

source "$(dirname "$0")/common.sh"

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  error "Run this script with sudo"
fi

if [[ -z "${SUDO_USER:-}" || "${SUDO_USER}" == "root" ]]; then
  error "Run via sudo from a non-root user (so AUR builds can run unprivileged)"
fi

SUDO_USER_HOME="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
if [[ -z "${SUDO_USER_HOME}" ]]; then
  error "Failed to determine home directory for ${SUDO_USER}"
fi

# ===== Time synchronization =====
log "Enabling time synchronization"
timedatectl set-ntp true

# ===== Enable multilib =====
log "Enabling multilib repository"
sudo sed -i \
  -e 's/^#\[multilib\]/[multilib]/' \
  -e '/^\[multilib\]/{n; s/^#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/}' \
  /etc/pacman.conf
sudo pacman -Syu --noconfirm

# ===== Install yay =====
log "Installing yay (AUR helper)"
pacman -S --noconfirm --needed git base-devel go

AUR_CACHE_DIR="${SUDO_USER_HOME}/.cache"
GOCACHE_DIR="${AUR_CACHE_DIR}/go-build"
AUR_BUILD_DIR="${AUR_CACHE_DIR}/aur"
install -d -m 0755 -o "${SUDO_USER}" -g "${SUDO_USER}" "${AUR_CACHE_DIR}" "${GOCACHE_DIR}" "${AUR_BUILD_DIR}"

YAY_DIR="${AUR_BUILD_DIR}/yay"
if [[ -d "${YAY_DIR}/.git" ]]; then
  sudo -u "${SUDO_USER}" -H git -C "${YAY_DIR}" pull --ff-only
else
  sudo -u "${SUDO_USER}" -H git clone https://aur.archlinux.org/yay.git "${YAY_DIR}"
fi

sudo -u "${SUDO_USER}" -H env GOCACHE="${GOCACHE_DIR}" bash -lc "cd '${YAY_DIR}' && makepkg -c"

YAY_PKG_FILE=$(find "${YAY_DIR}" -maxdepth 1 -type f -name '*.pkg.tar.*' ! -name '*-debug-*.pkg.tar.*' | sort | tail -n 1)
if [[ -z "${YAY_PKG_FILE}" ]]; then
  error "Failed to locate built yay package in ${YAY_DIR}"
fi

pacman -U --noconfirm --needed "${YAY_PKG_FILE}"

# ===== Configure mkinitcpio preset =====
log "Configuring mkinitcpio to save initramfs to /efi/arch"
sed -i 's|default_image="/boot/initramfs-linux.img"|default_image="/efi/arch/initramfs-linux.img"|g' /etc/mkinitcpio.d/linux.preset
sed -i 's|fallback_image="/boot/initramfs-linux-fallback.img"|fallback_image="/efi/arch/initramfs-linux-fallback.img"|g' /etc/mkinitcpio.d/linux.preset

log "Base-installation complete"

# ===== Install additional fonts =====
sudo pacman -S --noconfirm --needed ttf-jetbrains-mono-nerd

# ===== Enable Num Lock early (mkinitcpio) =====
log "Enabling Num Lock during early boot (initramfs)"

# Install mkinitcpio-numlock (AUR)
sudo -u "${SUDO_USER}" -H yay -S --noconfirm --needed mkinitcpio-numlock

MKINIT_CONF="/etc/mkinitcpio.conf"

# Ensure numlock hook exists before encrypt
if ! grep -q '\bnumlock\b' "${MKINIT_CONF}"; then
  log "Adding numlock hook to mkinitcpio.conf"

  sed -i \
    -E 's/\(([^)]*)\)/(\1 numlock)/' \
    "${MKINIT_CONF}"

  # Move numlock before encrypt if encrypt exists
  sed -i \
    -E 's/(numlock )(.*)( encrypt)/\2\1encrypt/' \
    "${MKINIT_CONF}"
else
  log "numlock hook already present, skipping"
fi

# Regenerate initramfs
log "Regenerating initramfs"
mkinitcpio -P