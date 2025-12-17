#!/bin/bash

# Arch Linux Installation Script

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Function to prompt for user input
prompt() {
    local prompt_text="$1"
    local default_value="$2"
    local variable_name="$3"
    
    echo -e "${BLUE}[PROMPT]${NC} $prompt_text"
    if [ -n "$default_value" ]; then
        echo -e "${BLUE}[DEFAULT]${NC} $default_value"
    fi
    read -p "> " input
    
    if [ -z "$input" ] && [ -n "$default_value" ]; then
        input="$default_value"
    fi
    
    declare -g "$variable_name"="$input"
}

# Function to detect disks
detect_disks() {
    log "Detecting available disks..."
    lsblk -d -o NAME,SIZE,MODEL | grep -E '^sd|^nvme|^vd|^hd'
    echo ""
}

# Function to get partition UUID
get_uuid() {
    local partition="$1"
    blkid -s UUID -o value "$partition"
}

# Start installation
log "Starting automated Arch Linux installation..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "This script must be run as root"
fi

# Step 1: Set keyboard layout
log "Setting keyboard layout to us..."
loadkeys us

# Step 2: Disk configuration
echo ""
log "=== Disk Configuration ==="
detect_disks

# Set default partitions
EFI_PARTITION="/dev/nvme0n1p1"
ROOT_PARTITION="/dev/nvme0n1p2"

# Verify partitions exist
if [ ! -b "$EFI_PARTITION" ]; then
    error "EFI partition $EFI_PARTITION does not exist"
fi

if [ ! -b "$ROOT_PARTITION" ]; then
    error "Root partition $ROOT_PARTITION does not exist"
fi

log "Using EFI partition: $EFI_PARTITION"
log "Using root partition: $ROOT_PARTITION"

# Step 3: Format partitions
log "Formatting EFI partition with FAT32..."
mkfs.fat -F 32 "$EFI_PARTITION"

log "Formatting root partition with BTRFS..."
mkfs.btrfs -f "$ROOT_PARTITION"

# Step 4: Create BTRFS subvolumes
log "Creating BTRFS subvolumes..."
mount "$ROOT_PARTITION" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt

# Step 5: Mount filesystems
log "Mounting filesystems with compression..."
mount -o compress=zstd,subvol=@ "$ROOT_PARTITION" /mnt
mkdir -p /mnt/home
mount -o compress=zstd,subvol=@home "$ROOT_PARTITION" /mnt/home
mkdir -p /mnt/efi
mount "$EFI_PARTITION" /mnt/efi

# Step 5.5: Create early system configuration files
log "Creating early system configuration..."
mkdir -p /mnt/etc
echo 'KEYMAP=us-acentos' > /mnt/etc/vconsole.conf

# Step 6: Install base system
log "Installing base system packages..."
pacstrap -K /mnt base base-devel linux linux-firmware git btrfs-progs limine timeshift intel-ucode vim networkmanager pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber reflector zsh zsh-completions zsh-autosuggestions openssh man sudo

# Step 7: Generate fstab
log "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

log "Generated fstab:"
cat /mnt/etc/fstab
echo ""

# Step 8: Chroot and configure system
log "Configuring system settings..."

# Create configuration script for chroot
cat > /mnt/configure_system.sh << 'EOF'
#!/bin/bash

# System configuration inside chroot

# Set timezone
echo "Setting timezone to Europe/Lisbon..."
ln -sf /usr/share/zoneinfo/Europe/Lisbon /etc/localtime
hwclock --systohc

# Configure locale
echo "Configuring locale..."
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

echo 'LANG=en_US.UTF-8' > /etc/locale.conf

# Set hostname
echo "arch" > /etc/hostname

# Configure hosts file
echo "127.0.1.1   arch" >> /etc/hosts

# Set root password
echo "Setting root password..."
passwd

# Create user
echo "Creating user narkas..."
useradd -mG wheel narkas
echo "Setting password for narkas..."
passwd narkas

# Configure sudo
echo "Configuring sudo..."
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Install Limine bootloader
echo "Installing Limine bootloader..."
pacman -S --noconfirm limine
mkdir -p /efi/EFI/arch-limine
cp /usr/share/limine/BOOTX64.EFI /efi/EFI/arch-limine/

# Get root partition UUID
ROOT_UUID=$(blkid -s UUID -o value /dev/nvme0n1p2)

# Create Limine configuration
cat > /efi/EFI/arch-limine/limine.cfg << LIMINECFG
timeout: 5

/Arch Linux
    protocol: linux
    path: boot():/vmlinuz-linux
    cmdline: root=UUID=$ROOT_UUID rw
    module_path: boot():/initramfs-linux.img
LIMINECFG

# Install efibootmgr and create boot entry
echo "Creating EFI boot entry..."
pacman -S --noconfirm efibootmgr
efibootmgr \
    --create \
    --disk /dev/nvme0n1 \
    --part 1 \
    --label "Arch Linux Limine Boot Loader" \
    --loader '\EFI\arch-limine\BOOTX64.EFI' \
    --unicode

# Enable NetworkManager
echo "Enabling NetworkManager..."
systemctl enable NetworkManager

echo "System configuration completed!"
EOF

chmod +x /mnt/configure_system.sh

# Run configuration inside chroot
log "Running system configuration inside chroot..."
arch-chroot /mnt /configure_system.sh

# Clean up
rm /mnt/configure_system.sh

# Step 9: Final cleanup
log "Performing final cleanup..."
umount -R /mnt

log "Installation completed successfully!"
echo ""
log "=== Installation Summary ==="
log "EFI Partition: $EFI_PARTITION"
log "Root Partition: $ROOT_PARTITION"
log "Filesystem: BTRFS with compression"
log "Bootloader: Limine"
log "Username: narkas"
echo ""
warn "The system will now reboot. Remove the installation media when prompted."
warn "After reboot, you can log in as 'narkas' with the password you set."
echo ""

# Prompt for reboot
prompt "Reboot now? (y/n):" "y" "REBOOT_CHOICE"

if [[ "$REBOOT_CHOICE" =~ ^[Yy]$ ]]; then
    log "Rebooting system..."
    reboot
else
    log "Installation complete. You can reboot manually when ready."
    log "Run 'reboot' to restart the system."
fi
