# /hosts/my-laptop/hardware-configuration.nix
# This file will be populated by 'nixos-generate-config' when installing NixOS on real hardware.
# For now, this is just a placeholder with common hardware settings.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Placeholder for bootloader configuration
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Placeholder for hardware settings
  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # CPU settings
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Graphics hardware
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Placeholder for filesystem mounts (these will be managed by Disko and impermanence modules)
  # DO NOT add any fileSystems definitions here, as they will conflict with those defined
  # in the impermanence.nix module.

  # Swapfile is not needed as a swap partition is defined in disko-zfs.nix
  swapDevices = [ ];

  # Enable firmware that might be needed
  hardware.enableRedistributableFirmware = true;
}