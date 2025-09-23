# /modules/nixos/impermanence.nix
{ config, lib, pkgs, inputs, username, ... }:

{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  # Enable ZFS support and ensure the pool is imported at boot.
  boot.supportedFilesystems = [ "zfs" ];
  services.zfs.autoScrub.enable = true;
  
  # CRITICAL FIX: Enable systemd in initrd for proper service ordering
  boot.initrd.systemd.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # NVIDIA driver configuration - blacklist nouveau and load nvidia early
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
      "mem_sleep_default=deep"  # Deep sleep for better power management
      "pcie_aspm.policy=powersupersave"  # PCIe power management
    ];
  };

  # Move ZFS rollback to initrd stage where it belongs
  boot.initrd.systemd.services.zfs-rollback = {
    description = "Rollback ZFS root dataset to a blank snapshot";
    wantedBy = [ "initrd.target" ];
    after = [ "zfs-import-rpool.service" ];
    before = [ "sysroot.mount" ];
    path = [ pkgs.zfs ];
    serviceConfig.Type = "oneshot";
    unitConfig.DefaultDependencies = "no";
    script = "zfs rollback -r -f rpool/local/root@blank";
  };

  # Ensure persistent directories are created before they're needed
  boot.initrd.systemd.services.create-needed-for-boot-dirs = {
    after = [ "zfs-rollback.service" ];
    wants = [ "zfs-rollback.service" ];
  };

  # Define which files and directories should persist across reboots.
  # These are bind-mounted from the `/persist` dataset.
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      # System-level directories that need persistence
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/AccountsService"
      "/etc/NetworkManager/system-connections"
      "/var/lib/colord"
      "/var/lib/flatpak"
      "/var/lib/systemd/timers"
      "/var/mail"
      # 1Password system-wide
      "/var/lib/1password"
      # ASUS-specific directories
      "/etc/asusd"
      "/var/lib/asusd"
    ];
    files = [
      # System-level files that need persistence
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  # User-specific persistence (separate from system persistence)
  environment.persistence."/persist/home/${username}" = {
    hideMounts = true;
    directories = [
      # 1Password CLI and GUI (user-specific)
      ".config/op"
      ".config/1Password"
      ".cache/1Password"
      ".config/1Password-Beta"
      # ASUS-specific user directories
      ".config/asusd"
      # Add more user directories as needed
      "Documents"
      "Downloads"
      "Pictures"
      "Music"
      "Videos"
      ".local/share"
    ];
  };

  # Explicitly define the filesystem mounts.
  fileSystems = {
    "/" = {
      device = "rpool/local/root";
      fsType = "zfs";
    };
    "/nix" = {
      device = "rpool/local/nix";
      fsType = "zfs";
      neededForBoot = true;
    };
    "/persist" = {
      device = "rpool/safe/persist";
      fsType = "zfs";
      neededForBoot = true;
    };
    "/home" = {
      device = "rpool/safe/home";
      fsType = "zfs";
    };
    "/boot" = {
      device = "/dev/disk/by-partlabel/disk-main-ESP";
      fsType = "vfat";
      options = [ "umask=0077" ];
      neededForBoot = true;
    };
  };

  # Remove the old zfs-rollback service that runs too late
  systemd.services.zfs-rollback = lib.mkForce { };
  
  # Remove the persist-ensure-ssh-keys service (not needed with proper initrd ordering)
  systemd.services.persist-ensure-ssh-keys = lib.mkForce { };
  
  # Fix for SSH service - ensure it starts after persistent directories are available
  systemd.services.sshd = {
    after = [ "systemd-tmpfiles-setup.service" ];
    wants = [ "systemd-tmpfiles-setup.service" ];
  };

  # ASUS-specific services and configurations
  services = {
    asusd = {
      enable = true;
      enableUserService = true;
    };
    supergfxd.enable = true;
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
        # These will be set by the hardware module, but we can override if needed
        # intelBusId = "PCI:0:2:0";
        # nvidiaBusId = "PCI:1:0:0";
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