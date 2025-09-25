# /hosts/laptop/simple.nix - Simplified config without ZFS/impermanence
{ config, pkgs, lib, inputs, ... }:

{
  # Import unfree packages configuration
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
    ../../modules/nixos/users.nix
    ../../modules/nixos/nvidia-rog.nix
    inputs.nixos-hardware.nixosModules.asus-zephyrus-gu603h
  ];

  # Host-specific settings.
  networking.hostName = "laptop"; # Must match the name in flake.nix

  # Boot loader configuration (use systemd-boot with EFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set host type for user management
  users.hostType = "laptop";

  # Hardware-specific configurations for laptop
  services.tlp = {
    enable = true;
    settings = {
      # CPU frequency scaling governor settings
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      
      # Power saving settings
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    };
  };

  # Enable brightness control for laptop
  programs.light.enable = true;

  # Enable laptop-specific services
  services.acpid.enable = true;
  
  # Power management
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions,
  # are taken. It's crucial for managing upgrades.
  system.stateVersion = "25.05";
}