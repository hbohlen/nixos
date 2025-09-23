# /modules/nixos/nvidia-rog.nix
{ config, lib, pkgs, ... }:

{
  # NVIDIA driver configuration for ASUS ROG laptops
  boot = {
    # Blacklist nouveau to prevent conflicts with proprietary NVIDIA drivers
    blacklistedKernelModules = [ "nouveau" ];
    
    # Load nvidia drivers early in the boot process
    initrd.kernelModules = [ "nvidia" "nvidia_drm" "nvidia_modeset" ];
    
    # Additional kernel parameters for NVIDIA and system stability
    kernelParams = [
      "nvidia-drm.modeset=1"  # Enable DRM modesetting for NVIDIA
      "nvidia-drm.fbdev=1"    # Enable framebuffer device
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"  # Preserve video memory allocations
    ];
  };

  # NVIDIA configuration for ASUS ROG laptops
  hardware = {
         # Enable graphics with 32-bit support
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    # NVIDIA proprietary driver configuration
    nvidia = {
      # Modesetting is required for proper NVIDIA functionality
      modesetting.enable = true;
      
      # Enable NVIDIA settings
      nvidiaSettings = true;
      
      # Power management for better battery life
      powerManagement = {
        enable = true;
        finegrained = true;
      };
      
      # Dynamic boost for better performance
      dynamicBoost.enable = true;
      
      # Prime configuration for hybrid graphics
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
      };
      
      # Force the use of the proprietary driver
      forceFullCompositionPipeline = true;
    };
  };

  # Additional udev rules for NVIDIA and ASUS devices
  services.udev.extraRules = ''
    # NVIDIA GPU power management
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", ATTR{power/control}="auto"
    
    # Fix for ASUS keyboard backlight and other features
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0b05", ATTR{idProduct}=="19b6", ATTR{power/autosuspend}="-1"
  '';

  # Ensure X server uses NVIDIA drivers
  services.xserver = {
    videoDrivers = [ "nvidia" ];
  };
}