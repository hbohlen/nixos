# /hosts/server/default.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
    ../../modules/nixos/impermanence.nix
    ../../modules/nixos/disko-zfs.nix
  ];

  # Basic server configuration
  networking.hostName = "server"; # Must match the name in flake.nix
  networking.hostId = "facefeed"; # Required for ZFS, must be unique 8-char hex
  
  # Server-specific settings
  services.openssh = {
    enable = true;
    # Prefer key authentication over passwords
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # User configuration for hbohlen
  users.users.hbohlen = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "changeme"; # Replace with secure method in production
    group = "hbohlen";
    createHome = true;
    home = "/home/hbohlen";
  };
  users.groups.hbohlen = {};

  # Additional server-specific packages
  environment.systemPackages = with pkgs; [
    # Minimal for test install
    # tmux
    # htop
    # git
    # vim
    # curl
    # wget
  ];
  
  # This value determines the NixOS release with which your system is to be compatible.
  # You should change this only after NixOS release notes indicate you should.
  system.stateVersion = "25.05"; # Keep this value stable for a specific install.
}