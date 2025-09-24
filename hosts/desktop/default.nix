# /hosts/desktop/default.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
    ../../modules/nixos/users.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/impermanence.nix
    ../../modules/nixos/disko-zfs.nix
    ../../modules/nixos/nvidia-rog.nix
    # Intel CPU and desktop PC hardware support
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # Host-specific settings
  networking.hostName = "desktop"; # Must match the name in flake.nix
  networking.hostId = "deadbeef"; # Required for ZFS, must be unique 8-character hex
  
  # Set host type for user management
  users.hostType = "desktop";

  # Enable desktop environment
  desktop.enable = true;

  # This value determines the NixOS release with which your system is to be compatible.
  # You should change this only after NixOS release notes indicate you should.
  system.stateVersion = "25.05"; # Keep this value stable for a specific install.
}