# /modules/nixos/boot.nix
{ config, lib, ... }:

{
  # Tell the initrd to unlock the LUKS encrypted partition at boot
  boot.initrd.luks.devices."cryptroot" = { # <- Move the block here, outside of boot.loader
    device = "/dev/disk/by-partlabel/luks";
    preLVM = true;
    allowDiscards = true;
  };

  # Boot loader configuration using systemd-boot with EFI
  boot.loader = {
    systemd-boot = {
      enable = true;
      # Enable editor for emergency recovery (set to false for security)
      editor = false;
    };
    # The luks block does not go here
    efi = {
      canTouchEfiVariables = true;
      # Enable EFI boot manager integration
      efiSysMountPoint = "/boot";
    };
    # Enable timeout for boot menu
    timeout = 5;
  };

  # Kernel configuration
  boot = {
    # Clean /tmp on boot
    tmp.cleanOnBoot = true;
    
    # Enable kernel modules for common hardware
    kernelModules = [
      "v4l2loopback" # For virtual camera support
    ];
    
    # Enable kernel parameters for better performance and compatibility
    kernelParams = [
      "quiet"
      "splash"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
    ];
    
    # Enable initrd debugging if needed
    initrd.verbose = false;
  };

  # Enable firmware updates
  services.fwupd.enable = true;
}
