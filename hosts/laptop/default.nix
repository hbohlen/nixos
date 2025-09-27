# /hosts/laptop/default.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./hardware/disko-zfs.nix  # Host-specific disko configuration
    ../../modules/nixos/common.nix
    ../../modules/nixos/users.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/laptop.nix
    ../../modules/nixos/development.nix  # Development tools for laptop
    ../../modules/nixos/impermanence.nix
    ../../profiles/graphics/nvidia-laptop.nix
    ../../profiles/hardware/asus-rog-laptop.nix
  ];

  # Host-specific settings
  networking.hostName = "laptop"; # Must match the name in flake.nix
  networking.hostId = "cafebabe"; # Required for ZFS, must be unique 8-character hex
  
  # Set host type for user management
  users.hostType = "laptop";

  # --- CRITICAL: Ensure only NetworkManager manages WiFi (fix repeated prompts) ---
  networking.wireless.enable = false;
  systemd.services.wpa_supplicant.enable = false;

  # Configure WiFi for laptop use
  wifi = {
    enable = true;
    powerSaving = lib.mkForce "low";  # Force override common.nix setting for better connectivity
    enableFirmware = true;
    enableProprietaryFirmware = lib.mkDefault false;  # Explicit default
  };

  services = {
    asusd = {
      enable = true;
      enableUserService = true;
    };

    supergfxd.enable = true;
  };

  systemd.services.supergfxd.path = [ pkgs.pciutils ];

  boot.kernelParams = [
    "acpi_backlight=vendor"
    "acpi_osi=Linux"
    "nvidia-drm.modeset=1"
    "nvidia.NVreg_EnableBacklightHandler=0"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "mem_sleep_default=deep"
    "nvme_core.default_ps_max_latency_us=0"
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  environment.systemPackages = with pkgs; [
    asusctl
    supergfxctl
    tlp
    powertop
    acpi
  ];

  services.tlp.settings = {
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    PLATFORM_PROFILE_ON_AC = "performance";
    PLATFORM_PROFILE_ON_BAT = "low-power";
    WIFI_PWR_ON_AC = "off";
    WIFI_PWR_ON_BAT = "on";
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

  # Enable development tools for laptop use
  development.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions,
  # are taken. It's crucial for managing upgrades.
  system.stateVersion = "25.05";
}
