# /hosts/laptop/default.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
    ../../modules/nixos/users.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/laptop.nix
    ../../modules/nixos/impermanence.nix
    ../../modules/nixos/disko-zfs.nix
    ../../modules/nixos/nvidia-rog.nix
    inputs.nixos-hardware.nixosModules.asus-zephyrus-gu603h
  ];

  # Host-specific settings
  networking.hostName = "laptop"; # Must match the name in flake.nix
  networking.hostId = "cafebabe"; # Required for ZFS, must be unique 8-character hex
  
  # Set host type for user management
  users.hostType = "laptop";

  # Enable desktop environment
  desktop.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions,
  # are taken. It's crucial for managing upgrades.
  system.stateVersion = "25.05";
}
