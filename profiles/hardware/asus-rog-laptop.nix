# /profiles/hardware/asus-rog-laptop.nix
{ config, lib, modulesPath, inputs, ... }:

let
  nixosHardwareModules = inputs.nixos-hardware.nixosModules;
  hasGu603zw = lib.hasAttr "asus-zephyrus-gu603zw" nixosHardwareModules;
in
{
  imports =
    (lib.optional hasGu603zw nixosHardwareModules.asus-zephyrus-gu603zw)
    ++ [
      (modulesPath + "/installer/scan/not-detected.nix")
      nixosHardwareModules.asus-zephyrus-gu603h
      nixosHardwareModules.common-cpu-intel
      nixosHardwareModules.common-pc-laptop
      nixosHardwareModules.common-pc-laptop-ssd
    ];

  boot = {
    initrd = {
      availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    blacklistedKernelModules = [ "nouveau" ];
    loader = {
      systemd-boot.enable = lib.mkDefault true;
      efi.canTouchEfiVariables = lib.mkDefault true;
    };
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    enableRedistributableFirmware = true;
    enableAllFirmware = false;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  swapDevices = [ ];
}
