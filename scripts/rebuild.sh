#!/usr/bin/env bash
# /scripts/rebuild.sh

# Exit immediately if a command exits with a non-zero status.
# Also exit on undefined variables and pipe failures
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2; }
info() { log "INFO: $*"; }
error() { log "ERROR: $*"; exit 1; }
warn() { log "WARN: $*"; }

# Automatically detect the hostname of the current machine.
HOSTNAME=$(hostname)
info "Rebuilding system for host: $HOSTNAME"

# Navigate to the flake's root directory (assuming the script is run from there or a subdirectory).
FLAKE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$FLAKE_DIR" || error "Failed to change to flake directory: $FLAKE_DIR"

# Validate that we have a flake.nix file
[[ -f "flake.nix" ]] || error "flake.nix not found in $FLAKE_DIR"

# Check if the hostname exists in the flake configuration
info "Validating hostname exists in flake configuration..."
if ! nix eval --no-warn-dirty ".#nixosConfigurations.$HOSTNAME" >/dev/null 2>&1; then
    error "Host '$HOSTNAME' not found in flake configuration. Available hosts: $(nix eval --no-warn-dirty --raw ".#nixosConfigurations" 2>/dev/null | jq -r 'keys[]' 2>/dev/null || echo "unable to list")"
fi

# Optional: Show what will be built/updated
if [[ "${1:-}" == "--dry-run" ]]; then
    info "Performing dry run..."
    nixos-rebuild dry-activate --flake ".#$HOSTNAME"
    exit 0
fi

# Build and switch to the new configuration for the detected hostname.
# The --flake .#$HOSTNAME syntax targets the specific host output in flake.nix.
info "Building and switching to new configuration..."
sudo nixos-rebuild switch --flake ".#$HOSTNAME"

# Optional: Clean up old generations to save space.
if [[ "${1:-}" == "--gc" ]]; then
    info "Cleaning up old generations..."
    sudo nix-collect-garbage -d
fi

info "System rebuild complete for host: $HOSTNAME"
info "Reboot may be required for some changes to take effect"