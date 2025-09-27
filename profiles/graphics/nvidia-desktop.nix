{ config, pkgs, lib, inputs, ... }:
{
  boot = {
    blacklistedKernelModules = [ "nouveau" ];
    initrd.kernelModules = [ "nvidia" "nvidia_drm" "nvidia_modeset" ];
    kernelParams = [
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      open = false;

      powerManagement = {
        enable = true;
        finegrained = false;
      };

      forceFullCompositionPipeline = false;
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];
}
