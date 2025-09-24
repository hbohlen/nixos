# /hosts/desktop/default.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/disko-zfs.nix
    ../../modules/nixos/common.nix
    ../../modules/nixos/impermanence.nix
    ../../modules/nixos/nvidia-rog.nix
    # Intel CPU and desktop PC hardware support
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # Basic desktop configuration
  networking.hostName = "desktop"; # Must match the name in flake.nix
  
  # Desktop-specific settings (use new option paths)
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Audio: Use PipeWire, disable PulseAudio to avoid conflict
  # sound.enable removed (deprecated)
  services.pulseaudio.enable = false;

  # Boot loader configuration (use systemd-boot with EFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ZFS requires a hostId (must be 8 hex digits, e.g. "deadbeef")
  networking.hostId = "deadbeef";

  # User configuration for hbohlen
  users.users.hbohlen = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    initialPassword = "changeme"; # Replace with secure method in production
    group = "hbohlen";
    createHome = true;
    home = "/home/hbohlen";
  };
  users.groups.hbohlen = {};

  # Additional desktop-specific packages
  environment.systemPackages = with pkgs; [
    # Minimal for test install
    # firefox
    # thunderbird
    # gimp
    # libreoffice
    # vlc
  ];
  
  # This value determines the NixOS release with which your system is to be compatible.
  # You should change this only after NixOS release notes indicate you should.
  system.stateVersion = "25.05"; # Keep this value stable for a specific install.
}