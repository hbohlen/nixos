#!/usr/bin/env bash
# /scripts/bootstrap.sh
# Quick bootstrap script for NixOS installation from live ISO
#
# This script can be run directly from the web:
# curl -L https://raw.githubusercontent.com/hbohlen/nixos/main/scripts/bootstrap.sh | bash
#
# Or downloaded and run locally:
# wget https://raw.githubusercontent.com/hbohlen/nixos/main/scripts/bootstrap.sh
# chmod +x bootstrap.sh && ./bootstrap.sh

set -euo pipefail

# Color codes
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

print_status() {
    echo -e "${BLUE}[BOOTSTRAP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root. Please run: sudo -i"
    exit 1
fi

print_status "🚀 Starting NixOS installation bootstrap..."

# Install git if not available
print_status "Installing git..."
nix-shell -p git --run "echo 'Git available'"

# Clone repository
print_status "Cloning NixOS configuration repository..."
cd /tmp
if [[ -d "nixos" ]]; then
    rm -rf nixos
fi
git clone https://github.com/hbohlen/nixos.git
cd nixos

# Make install script executable (in case it's not)
chmod +x scripts/install.sh

print_success "Bootstrap complete! Now running the installation script..."
print_status "You will be prompted for hostname, username, and target disk..."
print_status "During disk partitioning, you will also be prompted for LUKS encryption password..."

# Ensure Nix environment is available for the install script
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Run the main installation script with proper TTY inheritance
exec ./scripts/install.sh < /dev/tty