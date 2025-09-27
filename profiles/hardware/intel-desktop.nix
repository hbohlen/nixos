# /profiles/hardware/intel-desktop.nix
{ config, lib, modulesPath, inputs, ... }:

let
  nixosHardwareModules = inputs.nixos-hardware.nixosModules;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    nixosHardwareModules.common-cpu-intel
    nixosHardwareModules.common-pc
    nixosHardwareModules.common-pc-ssd
  ];

  boot = {
    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
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

  networking.useDHCP = lib.mkDefault true;

  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    enableRedistributableFirmware = true;
    enableAllFirmware = false;
  };
}
