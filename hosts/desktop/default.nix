# /hosts/desktop/default.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./hardware/disko-zfs.nix  # Host-specific disko configuration
    ../../modules/nixos/common.nix
    ../../modules/nixos/users.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/development.nix  # Development tools for desktop
    ../../modules/nixos/impermanence.nix
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

  # Configure WiFi for desktop use
  wifi = {
    enable = true;
    powerSaving = "off";  # Disable power saving on desktop for best performance
    enableFirmware = true;
    enableProprietaryFirmware = true;
  };

  # Desktop-specific networking (ensure no conflicts with laptop settings)
  networking = {
    # Use DHCP by default (can be overridden by hardware configuration)
    useDHCP = lib.mkDefault true;
  };

  # SSH Key Configuration (Security)
  # To set up SSH keys and disable password authentication:
  # 1. Generate SSH key: ssh-keygen -t ed25519 -C "your-email@example.com"
  # 2. Add your public key here:
  # users.sshKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... your-key" ];
  # 3. Disable password auth: users.enablePasswordAuth = false;
  # users.sshKeys = [];  # Add your SSH public keys here
  # users.enablePasswordAuth = true;  # Set to false when SSH keys are configured

  # Enable desktop environment
  desktop.enable = true;

  # Enable development tools for desktop use
  development.enable = true;

  # This value determines the NixOS release with which your system is to be compatible.
  # You should change this only after NixOS release notes indicate you should.
  system.stateVersion = "25.05"; # Keep this value stable for a specific install.
}
