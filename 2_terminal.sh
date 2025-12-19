# Install terminal emulator
pacman -S ghostty

# Create config directory
mkdir -p ~/.config/ghostty

# Copy ghostty configuration
cp ./config/ghostty/config ~/.config/ghostty/
chmod 600 ~/.config/ghostty/config

log "Ghostty configuration copied and secured"