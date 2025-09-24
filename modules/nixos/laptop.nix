# /modules/nixos/laptop.nix
{ config, pkgs, lib, ... }:

{
  # Disable power-profiles-daemon which conflicts with TLP
  services.power-profiles-daemon.enable = false;

  # TLP for advanced power management
  services.tlp = {
    enable = true;
    settings = {
      # CPU frequency scaling governor settings
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      
      # CPU energy performance policy
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      
      # Platform power settings
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";
      
      # Power saving settings
      RESTORE_DEVICE_STATE_ON_STARTUP = 1;
      
      # USB autosuspend
      USB_AUTOSUSPEND = 1;
      USB_AUTOSUSPEND_DISABLE_ON_SHUTDOWN = 1;
      
      # Radio device control
      DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth wifi wwan";
      DEVICES_TO_ENABLE_ON_AC = "bluetooth wifi wwan";
      DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth wifi wwan";
      
      # Battery charge thresholds (for supported laptops)
      # START_CHARGE_THRESH_BAT0 = 75;
      # STOP_CHARGE_THRESH_BAT0 = 80;
      
      # Runtime power management
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";
      
      # SATA link power management
      SATA_LINKPWR_ON_AC = "max_performance";
      SATA_LINKPWR_ON_BAT = "min_power";
      
      # PCIe active state power management
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";
      
      # WiFi power saving
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
      
      # Wake-on-LAN
      WOL_DISABLE = "Y";
      
      # Audio power saving
      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;
      SOUND_POWER_SAVE_CONTROLLER = "Y";
      
      # Allow charging of external devices
      BAY_POWEROFF_ON_AC = 0;
      BAY_POWEROFF_ON_BAT = 0;
      
      # Optical drive power management
      OPTICAL_AC_POWER = 1;
      OPTICAL_BAT_POWER = 0;
      
      # Graphics power management
      RADEON_POWER_PROFILE_ON_AC = "high";
      RADEON_POWER_PROFILE_ON_BAT = "low";
      
      # Intel GPU power management
      INTEL_GPU_MIN_FREQ_ON_AC = 300;
      INTEL_GPU_MIN_FREQ_ON_BAT = 300;
      INTEL_GPU_MAX_FREQ_ON_AC = 1300;
      INTEL_GPU_MAX_FREQ_ON_BAT = 300;
      INTEL_GPU_BOOST_FREQ_ON_AC = 1300;
      INTEL_GPU_BOOST_FREQ_ON_BAT = 300;
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
  services.fprintd = {
    enable = true;
    tod = {
      enable = true;
      driver = pkgs.libfprint-2-tod1-goodix;
    };
  };

  # Laptop-specific packages
  environment.systemPackages = with pkgs; [
    # Power management tools
    tlp
    powertop
    acpi
    lm_sensors
    hddtemp
    
    # Battery monitoring
    upower
    
    # Laptop utilities
    brightnessctl
    light
    xorg.xbacklight
    
    # Thermal management
    thermald
    
    # Network management
    networkmanagerapplet
    wpa_supplicant_gui
    
    # Bluetooth management
    blueman
    bluez-tools
    
    # Audio tools
    pavucontrol
    easyeffects
    
    # System monitoring
    gnome-system-monitor
    htop
    btop
    
    # Laptop-specific hardware tools
    intel-gpu-tools
    pciutils
    usbutils
    
    # Backup and sync
    rsync
    rclone
    
    # Productivity
    redshift
    libnotify
    dunst
  ];

  # Enable laptop-specific hardware support
  hardware = {
    # Enable Bluetooth
    bluetooth = {
      enable = true;
      powerOnBoot = false; # Save battery
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
      };
    };
    
    # Enable CPU frequency scaling
    cpu.intel.updateMicrocode = true;
  };

  # Enable laptop-specific services
  services = {
    # Enable location services for adaptive brightness
    geoclue2.enable = true;
    
    # Enable automatic screen brightness
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };
    
    # Enable thermal daemon
    thermald.enable = true;
    
    # Enable UPower for battery management
    upower.enable = true;
    
    # Enable logind power management
    logind = {
      settings = {
        Login = {
          HandleLidSwitch = "suspend";
          HandleLidSwitchDocked = "ignore";
          HandleLidSwitchExternalPower = "ignore";
          HandlePowerKey = "suspend";
          HandleSuspendKey = "suspend";
          HandleHibernateKey = "hibernate";
        };
      };
    };
  };

  # Enable suspend-then-hibernate for better battery life
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=2h
    SuspendThenHibernate=yes
  '';

  # Configure suspend-then-hibernate
  systemd.targets = {
    suspend-then-hibernate = {
      description = "Suspend then Hibernate";
      documentation = [ "man:systemd-suspend.service(8)" ];
      unitConfig = {
        DefaultDependencies = "no";
        Requires = "systemd-suspend.service";
        After = "systemd-suspend.service";
      };
    };
  };

  # Enable laptop-specific kernel modules
  boot.kernelModules = [
    "acpi_call"
    "tpm"
    "tpm_tis"
    "tpm_crb"
    "intel_rapl_msr"
    "intel_rapl_common"
    "coretemp"
    "kvm_intel"
    "snd_hda_intel"
    "iwlwifi"
    "cfg80211"
    "bluetooth"
  ];

  # Enable laptop-specific kernel parameters
  boot.kernelParams = [
    "acpi_backlight=vendor"
    "acpi_osi=Linux"
    "mem_sleep_default=deep"
    "nvme_core.default_ps_max_latency_us=0"
    "i915.enable_psr=1"
    "i915.enable_fbc=1"
    "i915.enable_guc=2"
  ];



  # Enable laptop-specific security
  security = {
    # Enable TPM2 support
    tpm2.enable = true;
  };

  # Enable laptop-specific networking optimizations
  networking = {
    # Enable power saving for WiFi
    networkmanager = {
      wifi.powersave = true;
      connectionConfig = {
        "wifi.powersave" = 3;
      };
    };
    
    # Enable IPv6 privacy extensions
    useDHCP = false;
    useNetworkd = true;
  };

  # Enable laptop-specific systemd services
  systemd.services = {
    # Enable thermal management service
    thermal-management = {
      description = "Thermal Management Service";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.thermald}/bin/thermald --no-daemon --adaptive";
      };
    };
    
    # Enable battery optimization service
    battery-optimization = {
      description = "Battery Optimization Service";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.tlp}/bin/tlp start";
      };
    };
  };
}