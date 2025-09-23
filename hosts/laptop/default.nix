# /hosts/laptop/default.nix
{ config, pkgs, inputs, ... }:

{
  # Import the modules that define the core architecture of the system.
  imports = [
    ./hardware-configuration.nix
  ../../modules/nixos/disko-zfs.nix
    ../../modules/nixos/impermanence.nix
    ../../modules/nixos/common.nix
  ];

  # Host-specific settings.
  networking.hostName = "laptop"; # Must match the name in flake.nix
  networking.hostId = "cafebabe"; # Required for ZFS, must be unique 8-character hex

  # Boot loader configuration (use systemd-boot with EFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Define the user account for this machine.
  users.users.hbohlen = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ]; # Sudo and network access.
    # The password should be set via a secure, declarative method.
    # For an impermanent system, this is critical, as imperative password setting
    # will be lost on reboot. Here we use a placeholder.
    # In a real system, this could be managed by sops-nix or agenix.
    initialPassword = "changeme";
  };

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
      
      # Battery charge thresholds (only for ThinkPads)
      # START_CHARGE_THRESH_BAT0 = 75;
      # STOP_CHARGE_THRESH_BAT0 = 80;
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

  # Enable fingerprint reader if available
  # services.fprintd.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions,
  # are taken. It's crucial for managing upgrades.
  system.stateVersion = "25.05";
}