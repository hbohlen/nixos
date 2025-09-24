# /hosts/server/default.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
    ../../modules/nixos/users.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/server.nix
    ../../modules/nixos/impermanence.nix
    ../../modules/nixos/disko-zfs.nix
  ];

  # Basic server configuration
  networking.hostName = "server"; # Must match the name in flake.nix
  networking.hostId = "facefeed"; # Required for ZFS, must be unique 8-char hex
  
  # Set host type for user management
  users.hostType = "server";
  
  # This value determines the NixOS release with which your system is to be compatible.
  # You should change this only after NixOS release notes indicate you should.
  system.stateVersion = "25.05"; # Keep this value stable for a specific install.
}