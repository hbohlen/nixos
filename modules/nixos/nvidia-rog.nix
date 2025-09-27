# /modules/nixos/nvidia-rog.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../../profiles/graphics/nvidia-laptop.nix
  ];

  warnings = [
    "modules/nixos/nvidia-rog.nix is deprecated; migrate to profiles/graphics/nvidia-laptop.nix or profiles/graphics/nvidia-desktop.nix."
  ];

  boot = {
    initrd.kernelModules = lib.mkDefault [ "nvidia" "nvidia_drm" "nvidia_modeset" ];
    kernelParams = lib.mkDefault [
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];
  };

  hardware.nvidia = {
    dynamicBoost.enable = lib.mkDefault true;
    forceFullCompositionPipeline = lib.mkDefault true;
  };

  services.udev.extraRules = ''
    # NVIDIA GPU power management
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", ATTR{power/control}="auto"

    # Fix for ASUS keyboard backlight and other features
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0b05", ATTR{idProduct}=="19b6", ATTR{power/autosuspend}="-1"
  '';
}
