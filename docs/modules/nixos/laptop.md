# laptop.nix - Laptop-Specific Configuration

**Location:** `modules/nixos/laptop.nix`

## Purpose

Provides comprehensive laptop-specific optimizations including advanced power management, battery optimization, thermal control, and hardware-specific features for portable computing devices.

## Dependencies

- **Integration:** Typically used with desktop.nix module for laptop workstations
- **Hardware:** Requires laptop hardware with battery, thermal sensors, and power management capabilities
- **External:** TLP, auto-cpufreq, and various power management packages

## Features

### Advanced Power Management

#### TLP Configuration
```nix
# Disable conflicting power-profiles-daemon
services.power-profiles-daemon.enable = false;

services.tlp = {
  enable = true;
  settings = {
    # CPU frequency scaling
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    
    # CPU energy performance policy
    CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    
    # Platform profiles
    PLATFORM_PROFILE_ON_AC = "performance";
    PLATFORM_PROFILE_ON_BAT = "low-power";
    
    # Radio device management
    DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth wifi wwan";
    DEVICES_TO_ENABLE_ON_AC = "bluetooth wifi wwan";
    DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth wifi wwan";
    
    # Storage power management
    SATA_LINKPWR_ON_AC = "max_performance";
    SATA_LINKPWR_ON_BAT = "min_power";
    
    # Network power management
    WIFI_PWR_ON_AC = "off";
    WIFI_PWR_ON_BAT = "on";
  };
};
```

#### Auto CPU Frequency Scaling
```nix
services.auto-cpufreq = {
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
```

### Hardware Control and Monitoring

#### Brightness Control
```nix
programs.light.enable = true;

environment.systemPackages = with pkgs; [
  brightnessctl        # Modern backlight control
  light               # Alternative backlight control
  xorg.xbacklight     # X11 backlight control
];
```

#### Thermal Management  
```nix
services.thermald.enable = true;
services.acpid.enable = true;

# Custom thermal management service
systemd.services.thermal-management = {
  description = "Thermal Management Service";
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${pkgs.thermald}/bin/thermald --no-daemon --adaptive";
  };
};
```

### Battery Optimization

#### Power Management Settings
```nix
powerManagement = {
  enable = true;
  powertop.enable = true;
};

services.upower.enable = true;
```

#### Suspend and Hibernate
```nix
services.logind = {
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

# Enable suspend-then-hibernate for better battery life
systemd.sleep.extraConfig = ''
  HibernateDelaySec=2h
  SuspendThenHibernate=yes
'';
```

### Biometric Authentication

#### Fingerprint Reader Support
```nix
services.fprintd = {
  enable = true;
  tod = {
    enable = true;
    driver = pkgs.libfprint-2-tod1-goodix;
  };
};
```

### Networking Optimizations

#### WiFi Power Management
```nix
networking = {
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
```

### Laptop-Specific Hardware

#### Bluetooth Configuration
```nix
hardware = {
  bluetooth = {
    enable = true;
    powerOnBoot = false;  # Save battery
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };
  
  # Enable CPU microcode updates
  cpu.intel.updateMicrocode = true;
};
```

#### Security Features
```nix
security = {
  # Enable TPM2 support for modern laptops
  tpm2.enable = true;
};
```

### Essential Laptop Packages

#### Power and Hardware Tools
```nix
environment.systemPackages = with pkgs; [
  # Power management
  tlp
  powertop
  acpi
  lm_sensors
  hddtemp
  upower
  
  # Hardware monitoring
  intel-gpu-tools
  pciutils
  usbutils
  
  # Network management
  networkmanagerapplet
  wpa_supplicant_gui
  
  # Bluetooth tools
  blueman
  bluez-tools
  
  # Audio control
  pavucontrol
  easyeffects
  
  # System monitoring
  htop
  btop
  
  # Productivity tools
  redshift            # Blue light filter
  libnotify          # Desktop notifications
  dunst              # Notification daemon
  
  # Backup and sync
  rsync
  rclone
];
```

### Kernel Configuration

#### Laptop-Specific Modules
```nix
boot.kernelModules = [
  "acpi_call"          # ACPI call support
  "tpm"                # TPM support
  "tpm_tis"            # TPM interface
  "tpm_crb"            # TPM command response buffer
  "intel_rapl_msr"     # Intel RAPL energy monitoring
  "intel_rapl_common"  # Intel RAPL common functions
  "coretemp"           # CPU temperature monitoring
  "kvm_intel"          # Intel virtualization
  "snd_hda_intel"      # Audio support
  "iwlwifi"            # Intel WiFi
  "cfg80211"           # WiFi configuration
  "bluetooth"          # Bluetooth support
];
```

#### Kernel Parameters
```nix
boot.kernelParams = [
  "acpi_backlight=vendor"              # Use vendor backlight control
  "acpi_osi=Linux"                     # ACPI OS interface
  "mem_sleep_default=deep"             # Default to deep sleep
  "nvme_core.default_ps_max_latency_us=0"  # NVMe power management
  "i915.enable_psr=1"                  # Intel Panel Self Refresh
  "i915.enable_fbc=1"                  # Intel Frame Buffer Compression
  "i915.enable_guc=2"                  # Intel GuC firmware
];
```

## Usage Examples

### Basic Laptop Setup
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/common.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/laptop.nix
  ];
  
  desktop.enable = true;
  # Laptop module automatically configures power management
}
```

### Developer Laptop
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/common.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/development.nix
    ../../modules/nixos/laptop.nix
  ];
  
  desktop.enable = true;
  development.enable = true;
  
  # Optimize for development workloads
  services.tlp.settings = {
    # Allow higher performance when plugged in
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
  };
}
```

### Gaming Laptop
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/common.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/laptop.nix
    ../../modules/nixos/nvidia-rog.nix
  ];
  
  desktop.enable = true;
  
  # Gaming-optimized power settings
  services.tlp.settings = {
    # Prioritize performance when gaming
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "performance";  # Performance on battery too
    
    # Disable aggressive power saving for gaming
    RUNTIME_PM_ON_BAT = "on";
    WIFI_PWR_ON_BAT = "off";
  };
  
  # Gaming packages
  environment.systemPackages = with pkgs; [
    steam
    lutris
    gamemode
    gamescope
  ];
}
```

### Ultrabook Configuration
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/laptop.nix
  ];
  
  # Ultra-aggressive power saving for ultrabooks
  services.tlp.settings = {
    # Maximum power saving
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    
    # Aggressive device power management
    USB_AUTOSUSPEND = 1;
    RUNTIME_PM_ON_BAT = "auto";
    
    # Network power saving
    WIFI_PWR_ON_BAT = "on";
    DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth wifi wwan";
  };
  
  # Extended sleep configuration
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m  # Hibernate after 30 minutes
    SuspendThenHibernate=yes
  '';
}
```

## Advanced Configuration

### Custom Battery Thresholds
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/laptop.nix
  ];
  
  # Configure battery charge thresholds (ThinkPad example)
  services.tlp.settings = {
    START_CHARGE_THRESH_BAT0 = 40;    # Start charging at 40%
    STOP_CHARGE_THRESH_BAT0 = 80;     # Stop charging at 80%
  };
  
  # Alternative: Use specific ThinkPad tools
  services.thinkfan.enable = true;
  environment.systemPackages = with pkgs; [
    tpacpi-bat          # ThinkPad battery tools
  ];
}
```

### Multi-Monitor Laptop Setup
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/laptop.nix
  ];
  
  desktop.enable = true;
  
  # Auto-configure external monitors
  services.autorandr.enable = true;
  
  environment.systemPackages = with pkgs; [
    arandr             # GUI display configuration
    autorandr          # Automatic display profiles
  ];
  
  # Custom lid behavior when docked
  services.logind.settings.Login = {
    HandleLidSwitchDocked = "ignore";        # Don't suspend when docked
    HandleLidSwitchExternalPower = "ignore"; # Don't suspend on external power
  };
}
```

### Custom Thermal Profiles
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/laptop.nix
  ];
  
  # Custom thermal management
  services.thermald = {
    enable = true;
    configFile = pkgs.writeText "thermal-conf.xml" ''
      <?xml version="1.0"?>
      <ThermalConfiguration>
        <Platform>
          <Name>Laptop Thermal Profile</Name>
          <ProductName>*</ProductName>
          <Preference>QUIET</Preference>
          <ThermalZones>
            <ThermalZone>
              <Type>cpu</Type>
              <TripPoints>
                <TripPoint>
                  <SensorType>cpu</SensorType>
                  <Temperature>60000</Temperature>
                  <type>passive</type>
                  <CoolingDevice>
                    <index>0</index>
                    <type>intel_pstate</type>
                    <influence>100</influence>
                    <SamplingPeriod>2</SamplingPeriod>
                  </CoolingDevice>
                </TripPoint>
              </TripPoints>
            </ThermalZone>
          </ThermalZones>
        </Platform>
      </ThermalConfiguration>
    '';
  };
}
```

## Hardware-Specific Configurations

### Intel Laptop Optimization
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/laptop.nix
  ];
  
  # Intel-specific optimizations
  boot.kernelParams = [
    "i915.enable_psr=1"        # Panel Self Refresh
    "i915.enable_fbc=1"        # Frame Buffer Compression
    "i915.enable_guc=2"        # GuC firmware loading
    "i915.fastboot=1"          # Fast boot
  ];
  
  # Intel GPU frequency scaling
  services.tlp.settings = {
    INTEL_GPU_MIN_FREQ_ON_AC = 300;
    INTEL_GPU_MIN_FREQ_ON_BAT = 300;
    INTEL_GPU_MAX_FREQ_ON_AC = 1300;
    INTEL_GPU_MAX_FREQ_ON_BAT = 300;
    INTEL_GPU_BOOST_FREQ_ON_AC = 1300;
    INTEL_GPU_BOOST_FREQ_ON_BAT = 300;
  };
}
```

### AMD Laptop Configuration
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/laptop.nix
  ];
  
  # AMD-specific settings
  boot.kernelModules = [ "amd-pstate" ];
  boot.kernelParams = [
    "amd_pstate=active"        # Use AMD P-State driver
  ];
  
  # AMD GPU power management
  services.tlp.settings = {
    RADEON_POWER_PROFILE_ON_AC = "high";
    RADEON_POWER_PROFILE_ON_BAT = "low";
  };
  
  # AMD microcode
  hardware.cpu.amd.updateMicrocode = true;
}
```

## Integration with Other Modules

### With Desktop Module
Combined laptop + desktop configuration provides:
- Full GUI environment with laptop optimizations
- Power-aware desktop behavior
- Mobile-friendly applications and settings

### With Development Module  
Developer laptops benefit from:
- Power management during compilation
- Container runtime optimizations
- Development tool power profiles

### With NVIDIA Module
Gaming laptops with discrete GPU:
- GPU power management integration
- Hybrid graphics switching
- Gaming performance profiles

## Power Management Strategies

### Battery Life Optimization
```nix
# Maximum battery life configuration
services.tlp.settings = {
  # CPU scaling
  CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
  CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
  
  # Aggressive power management
  RUNTIME_PM_ON_BAT = "auto";
  USB_AUTOSUSPEND = 1;
  
  # Display backlight
  RADEON_POWER_PROFILE_ON_BAT = "low";
  
  # Network
  WIFI_PWR_ON_BAT = "on";
  
  # Audio power saving
  SOUND_POWER_SAVE_ON_BAT = 10;
  SOUND_POWER_SAVE_CONTROLLER = "Y";
};
```

### Performance Mode
```nix
# Performance-focused configuration
services.tlp.settings = {
  # Maximum performance when needed
  CPU_SCALING_GOVERNOR_ON_AC = "performance";
  CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
  
  # Disable power saving features
  RUNTIME_PM_ON_AC = "on";
  USB_AUTOSUSPEND = 0;
  WIFI_PWR_ON_AC = "off";
};
```

## Troubleshooting

### Power Management Issues

#### TLP Configuration Problems
```bash
# Check TLP status
sudo tlp-stat

# View current power settings
sudo tlp-stat -s

# Apply TLP settings manually
sudo tlp start
```

#### Battery Issues
```bash
# Check battery information
upower -i /org/freedesktop/UPower/devices/battery_BAT0

# Monitor power consumption
sudo powertop

# Check ACPI battery info
cat /proc/acpi/battery/BAT0/info
```

### Thermal Issues

#### Overheating Problems
```bash
# Check CPU temperature
sensors

# Monitor thermal zones
cat /sys/class/thermal/thermal_zone*/temp

# Check thermald status
systemctl status thermald
```

#### Fan Control
```bash
# Check fan speeds
sensors | grep fan

# Manual fan control (if supported)
echo 255 > /sys/class/hwmon/hwmon0/pwm1
```

### Sleep and Suspend Issues

#### Suspend Problems
```bash
# Check suspend/resume logs
journalctl -u systemd-suspend

# Test suspend functionality
systemctl suspend

# Check wake sources
cat /proc/acpi/wakeup
```

#### Hibernate Issues
```bash
# Check hibernate capability
cat /sys/power/state

# Check swap space for hibernation
swapon --show

# Test hibernation
systemctl hibernate
```

### Hardware Detection Issues

#### Device Recognition
```bash
# Check laptop hardware
lspci | grep -i vga
lsusb
lscpu

# Check power management capabilities
ls /sys/class/power_supply/
```

#### Driver Problems
```bash
# Check loaded modules
lsmod | grep -E "(intel|amd|nvidia)"

# Check kernel messages
dmesg | grep -i error

# Verify hardware support
lshw -short
```

## Performance Tuning

### CPU Performance
```nix
# CPU governor tuning
powerManagement.cpuFreqGovernor = "ondemand";

# Custom CPU scaling
boot.kernel.sysctl = {
  "kernel.sched_autogroup_enabled" = 1;
  "vm.laptop_mode" = 1;
};
```

### Memory Optimization
```nix
# Laptop-specific memory settings
boot.kernel.sysctl = {
  "vm.swappiness" = 1;           # Minimize swapping
  "vm.vfs_cache_pressure" = 50;  # Cache tuning
  "vm.dirty_ratio" = 15;         # Dirty page ratio
  "vm.dirty_background_ratio" = 5;  # Background write ratio
};
```

### Storage Optimization
```nix
# SSD optimization for laptops
services.fstrim.enable = true;

# Filesystem mount options for laptops
fileSystems."/".options = [
  "noatime"        # Reduce SSD writes
  "compress=zstd"  # Compression for ZFS
];
```

## Security Considerations

### Physical Security
- **Screen lock:** Automatic lock on lid close
- **Hibernation encryption:** Ensure swap is encrypted for hibernation
- **USB protection:** Auto-suspend can help prevent USB attacks

### Network Security
- **WiFi:** Power management may affect connection stability
- **Bluetooth:** Automatic disable when not in use saves power and improves security
- **Location services:** Geoclue2 integration for location-aware power management

### TPM Integration
```nix
# Enhanced security with TPM
security.tpm2 = {
  enable = true;
  pkcs11.enable = true;  # PKCS#11 interface
  tctiEnvironment.enable = true;  # TCTI environment
};

# Use TPM for encryption keys
boot.initrd.luks.devices."cryptroot" = {
  device = "/dev/disk/by-uuid/your-uuid-here";
  preLVM = true;
  keyFile = "/dev/urandom";
  keyFileSize = 4096;
};
```