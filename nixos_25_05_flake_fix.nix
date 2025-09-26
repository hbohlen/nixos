# NixOS 25.05 Flake Fix Configuration
# This file addresses the unfree packages configuration conflict in NixOS 25.05
# where duplicate allowUnfreePredicate definitions cause build failures.
# 
# The fix involves:
# 1. Centralizing unfree package configuration in modules/nixos/unfree-packages.nix
# 2. Removing duplicate allowUnfreePredicate from flake.nix
# 3. Setting explicit allowUnfree = true in both contexts
#
# This configuration ensures compatibility with NixOS 25.05's stricter
# handling of unfree packages and firmware requirements.

{ config, lib, pkgs, ... }:

{
  # Import the centralized unfree packages configuration
  imports = [
    ./modules/nixos/unfree-packages.nix
  ];

  # Ensure hardware firmware is configured correctly for NixOS 25.05
  hardware = {
    # Enable redistributable firmware (always safe)
    enableRedistributableFirmware = lib.mkDefault true;
    
    # Only enable all firmware if unfree packages are explicitly allowed
    # This prevents installation failures in NixOS 25.05
    enableAllFirmware = lib.mkDefault false;
  };

  # System state version for NixOS 25.05
  system.stateVersion = "25.05";
}