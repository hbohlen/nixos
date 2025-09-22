#!/usr/bin/env bash
# /scripts/rebuild.sh

# Exit immediately if a command exits with a non-zero status.
set -e

# Automatically detect the hostname of the current machine.
HOSTNAME=$(hostname)
echo "--- Rebuilding system for host: $HOSTNAME ---"

# Navigate to the flake's root directory (assuming the script is run from there or a subdirectory).
FLAKE_DIR="$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd)"
cd "$FLAKE_DIR"

# Build and switch to the new configuration for the detected hostname.
# The --flake .#$HOSTNAME syntax targets the specific host output in flake.nix.
sudo nixos-rebuild switch --flake .#$HOSTNAME --use-remote-sudo

# Optional: Clean up old generations to save space.
# Uncomment the following line to enable automatic garbage collection
# sudo nix-collect-garbage -d

echo "--- System rebuild complete for host: $HOSTNAME ---"