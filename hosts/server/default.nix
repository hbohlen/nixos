# /hosts/server/default.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./hardware/disko-zfs.nix  # Host-specific disko configuration
    ../../modules/nixos/common.nix
    ../../modules/nixos/users.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/server.nix
    ../../modules/nixos/impermanence.nix
  ];

  # Basic server configuration
  networking.hostName = "server"; # Must match the name in flake.nix
  networking.hostId = "facefeed"; # Required for ZFS, must be unique 8-char hex
  
  # Set host type for user management
  users.hostType = "server";
  
  # SSH Key Configuration (Security - CRITICAL for servers)
  # To set up SSH keys and disable password authentication:
  # 1. Generate SSH key: ssh-keygen -t ed25519 -C "your-email@example.com"
  # 2. Add your public key here:
  # users.sshKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... your-key" ];
  # 3. Disable password auth: users.enablePasswordAuth = false;
  # users.sshKeys = [];  # Add your SSH public keys here
  # users.enablePasswordAuth = true;  # Set to false when SSH keys are configured
  
  # This value determines the NixOS release with which your system is to be compatible.
  # You should change this only after NixOS release notes indicate you should.
  system.stateVersion = "25.05"; # Keep this value stable for a specific install.
}