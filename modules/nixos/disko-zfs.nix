# /modules/nixos/disko-zfs.nix
# ⚠️  DEPRECATED: This module is no longer used ⚠️
#
# Hardware-specific disko configurations have been moved to per-host:
# - hosts/desktop/hardware/disko-zfs.nix
# - hosts/laptop/hardware/disko-zfs.nix  
# - hosts/server/hardware/disko-zfs.nix
#
# Each host now manages its own disko configuration with appropriate
# device paths for their specific hardware.
#
# MIGRATION: Update your host imports from:
#   ../../modules/nixos/disko-zfs.nix
# TO:
#   ./hardware/disko-zfs.nix
#
# TODO: Remove this file after confirming all hosts use the new structure
{ inputs, ... }:

{
  imports = [ inputs.disko.nixosModules.disko ../../disko-layout.nix ];
}
