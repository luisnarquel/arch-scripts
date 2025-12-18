#!/bin/bash
# Arch Linux Installation Script

set -e

source "$(dirname "$0")/common.sh"

# ===== Root check =====
[ "$EUID" -eq 0 ] || error "Run as root"

log "Starting Arch Linux installation"

# ===== Keyboard =====
loadkeys us

# ===== Disk configuration (ADJUST IF NEEDED) =====
EFI_PARTITION="/dev/nvme0n1p1"
ROOT_PARTITION="/dev/nvme0n1p2"
DISK="/dev/nvme0n1"

[ -b "$EFI_PARTITION" ] || error "EFI partition not found"
[ -b "$ROOT_PARTITION" ] || error "Root partition not found"

log "EFI  = $EFI_PARTITION"
log "ROOT = $ROOT_PARTITION"

# ===== Format =====
log "Formatting EFI (FAT32)"
mkfs.fat -F32 "$EFI_PARTITION"

log "Formatting ROOT (BTRFS)"
mkfs.btrfs -f "$ROOT_PARTITION"

# ===== BTRFS subvolumes =====
mount "$ROOT_PARTITION" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt

# ===== Mount layout =====
mount -o compress=zstd,subvol=@ "$ROOT_PARTITION" /mnt
mkdir -p /mnt/home
mount -o compress=zstd,subvol=@home "$ROOT_PARTITION" /mnt/home

mkdir -p /mnt/efi
mount "$EFI_PARTITION" /mnt/efi

# ===== Early config =====
mkdir -p /mnt/etc
echo "KEYMAP=us-acentos" > /mnt/etc/vconsole.conf

# ===== Base install =====
log "Installing base system"
pacstrap -K /mnt \
  base base-devel linux linux-firmware intel-ucode \
  git btrfs-progs limine networkmanager \
  openssh sudo vim pipewire pipewire-alsa \
  pipewire-pulse pipewire-jack wireplumber \
  reflector man

# ===== fstab =====
ROOT_UUID=$(blkid -s UUID -o value "$ROOT_PARTITION")
EFI_UUID=$(blkid -s UUID -o value "$EFI_PARTITION")

cat > /mnt/etc/fstab << EOF
# /etc/fstab for Arch Linux on BTRFS with subvolumes
UUID=$ROOT_UUID   /       btrfs   defaults,subvol=@,compress=zstd  0 1
UUID=$ROOT_UUID   /home   btrfs   defaults,subvol=@home,compress=zstd 0 2
UUID=$EFI_UUID    /efi    vfat    defaults 0 2
EOF

# ===== Chroot config script =====
cat > /mnt/configure_system.sh << 'EOF'
#!/bin/bash
set -e

echo "== System configuration =="

# ---- Time ----
ln -sf /usr/share/zoneinfo/Europe/Lisbon /etc/localtime
hwclock --systohc

# ---- Locale ----
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# ---- Host ----
echo "arch" > /etc/hostname

# ---- Hosts ----
echo "127.0.1.1   arch" >> /etc/hosts

# ---- Root password ----
echo "Set root password"
passwd

# ---- User ----
useradd -m -G wheel -s /bin/zsh narkas
echo "Set password for narkas"
passwd narkas

# ---- Sudo ----
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# ---- Enable services ----
systemctl enable NetworkManager

# ---- Ensure EFI mounted ----
mountpoint -q /efi || mount /dev/nvme0n1p1 /efi

# ---- Install Limine ----
pacman -S --noconfirm limine efibootmgr

mkdir -p /efi/EFI/arch-limine
cp /usr/share/limine/BOOTX64.EFI /efi/EFI/arch-limine/

# ---- Copy kernel + initramfs + microcode to ESP ----
mkdir -p /efi/arch

cp /boot/vmlinuz-linux /efi/arch/
cp /boot/initramfs-linux.img /efi/arch/
cp /boot/intel-ucode.img /efi/arch/

# ---- Limine config (ESP ROOT) ----
ROOT_UUID=$(blkid -s UUID -o value /dev/nvme0n1p2)

cat > /efi/EFI/arch-limine/limine.conf << LIMINECFG
timeout: 5
default: Arch Linux

/Arch Linux
    protocol: linux
    path: boot():/arch/vmlinuz-linux
    cmdline: root=UUID=$ROOT_UUID rw rootflags=subvol=@,compress=zstd quiet loglevel=3
    module_path: boot():/arch/intel-ucode.img
    module_path: boot():/arch/initramfs-linux.img
LIMINECFG

# ---- EFI boot entry ----
efibootmgr \
  --create \
  --disk /dev/nvme0n1 \
  --part 1 \
  --label "Arch Linux (Limine)" \
  --loader '\EFI\arch-limine\BOOTX64.EFI' \
  --unicode

echo "== Chroot configuration complete =="
EOF

chmod +x /mnt/configure_system.sh

# ===== Run chroot =====
arch-chroot /mnt /configure_system.sh
rm /mnt/configure_system.sh

# ===== Cleanup =====
umount -R /mnt

log "Installation complete"

warn "Rebooting in 5 seconds..."
sleep 5
reboot
