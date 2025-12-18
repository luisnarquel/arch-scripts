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

# ===== Time synchronization =====
log "Enabling time synchronization"
timedatectl set-ntp true

# ===== Install yay =====
log "Installing yay (AUR helper)"
pacman -S --noconfirm --needed git base-devel go

AUR_BUILD_DIR="/home/${SUDO_USER}/.cache/aur"
install -d -m 0755 -o "${SUDO_USER}" -g "${SUDO_USER}" "${AUR_BUILD_DIR}"

YAY_DIR="${AUR_BUILD_DIR}/yay"
if [[ -d "${YAY_DIR}/.git" ]]; then
  sudo -u "${SUDO_USER}" -H git -C "${YAY_DIR}" pull --ff-only
else
  sudo -u "${SUDO_USER}" -H git clone https://aur.archlinux.org/yay.git "${YAY_DIR}"
fi

sudo -u "${SUDO_USER}" -H bash -lc "cd '${YAY_DIR}' && makepkg -c"

YAY_PKG_FILE=$(find "${YAY_DIR}" -maxdepth 1 -type f -name '*.pkg.tar.*' ! -name '*-debug-*.pkg.tar.*' | sort | tail -n 1)
if [[ -z "${YAY_PKG_FILE}" ]]; then
  error "Failed to locate built yay package in ${YAY_DIR}"
fi

pacman -U --noconfirm --needed "${YAY_PKG_FILE}"

log "Base-installation complete"
