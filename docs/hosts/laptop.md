# Laptop Host Configuration

## Overview

The laptop host configuration is specifically optimized for portable computing with emphasis on power management, battery life, and thermal efficiency. This configuration targets ASUS ROG Zephyrus series laptops but provides general optimizations suitable for most modern Intel-based gaming and productivity laptops.

## Hardware Profile

### Target Hardware
- **Model**: ASUS ROG Zephyrus M16 GU603ZW/GU603H series
- **CPU**: Intel mobile processors (11th gen and newer)
- **GPU**: NVIDIA RTX mobile + Intel Iris Xe integrated graphics
- **Storage**: NVMe M.2 SSD (typically PCIe 4.0)
- **RAM**: 16GB+ DDR4/DDR5
- **Display**: High refresh rate (144Hz+) with variable refresh support

### Hardware-Specific Modules
- `profiles/hardware/asus-rog-laptop.nix`: Aggregates nixos-hardware ASUS profiles and laptop
  boot configuration.
- `modules/nixos/nvidia-rog.nix`: NVIDIA mobile GPU with hybrid graphics
- `modules/nixos/laptop.nix`: Comprehensive power management and laptop-specific services

## Power Management

### TLP Configuration
The laptop uses TLP (ThinkPad-Linux Project) for advanced power management:

```nix
services.tlp = {
  enable = true;
  settings = {
    # CPU Scaling Governors
    CPU_SCALING_GOVERNOR_ON_AC = "performance";    # Plugged in: maximum performance
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";     # Battery: power efficiency
    
    # CPU Energy Performance Policy  
    CPU_ENERGY_PERF_POLICY_ON_AC = "performance";  # AC: favor performance
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";      # Battery: favor power savings
    
    # Platform Power Profiles
    PLATFORM_PROFILE_ON_AC = "performance";        # AC: maximum performance mode
    PLATFORM_PROFILE_ON_BAT = "low-power";        # Battery: low power mode
    
    # USB Power Management
    USB_AUTOSUSPEND = 1;                           # Enable USB autosuspend
    USB_AUTOSUSPEND_DISABLE_ON_SHUTDOWN = 1;      # Prevent shutdown issues
    
    # Wireless Device Control
    DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth wifi wwan";     # Start disabled
    DEVICES_TO_ENABLE_ON_AC = "bluetooth wifi wwan";          # Enable when plugged
    DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth wifi wwan"; # Smart disable
    
    # Storage Power Management
    SATA_LINKPWR_ON_AC = "max_performance";        # AC: maximum SATA performance  
    SATA_LINKPWR_ON_BAT = "min_power";            # Battery: minimum power SATA
    
    # PCIe Power Management
    PCIE_ASPM_ON_AC = "default";                   # AC: default PCIe power
    PCIE_ASPM_ON_BAT = "powersupersave";         # Battery: maximum PCIe savings
    
    # WiFi Power Saving
    WIFI_PWR_ON_AC = "off";                        # AC: WiFi power saving off
    WIFI_PWR_ON_BAT = "on";                       # Battery: WiFi power saving on
    
    # Intel GPU Power Management
    INTEL_GPU_MIN_FREQ_ON_AC = 300;               # AC: higher minimum GPU freq
    INTEL_GPU_MIN_FREQ_ON_BAT = 300;              # Battery: lower minimum
    INTEL_GPU_MAX_FREQ_ON_AC = 1300;              # AC: maximum GPU performance
    INTEL_GPU_MAX_FREQ_ON_BAT = 300;              # Battery: limit GPU frequency
  };
};
```

### Auto CPU Frequency Management
Additional CPU frequency management through `auto-cpufreq`:

```nix
services.auto-cpufreq = {
  enable = true;
  settings = {
    battery = {
      governor = "powersave";      # Conservative CPU scaling
      turbo = "never";            # Disable turbo boost for battery life
    };
    charger = {
      governor = "performance";    # Maximum performance when plugged in
      turbo = "auto";             # Allow turbo boost when needed
    };
  };
};
```

### Battery Optimization Features
- **Suspend-then-Hibernate**: Suspends to RAM, then hibernates after 2 hours
- **Thermal Management**: `thermald` for intelligent thermal control  
- **Power Profiles**: Hardware-level power profile switching
- **Runtime Power Management**: Aggressive device power management

## Graphics Configuration

### Hybrid Graphics Setup
The laptop uses NVIDIA Optimus with PRIME offload for optimal battery life:

```nix
hardware.nvidia = {
  modesetting.enable = true;              # Wayland compatibility
  powerManagement = {
    enable = true;                        # Enable power management
    finegrained = true;                   # Fine-grained power control
  };
  dynamicBoost.enable = true;             # Performance optimization
  
  prime = {
    offload = {
      enable = true;                      # PRIME offload mode
      enableOffloadCmd = true;            # nvidia-offload command
    };
    intelBusId = "PCI:0:2:0";            # Intel iGPU (always-on)
    nvidiaBusId = "PCI:1:0:0";           # NVIDIA dGPU (on-demand)
  };
};
```

### Graphics Power Management
- **Default**: Intel integrated graphics for power efficiency
- **On-Demand**: NVIDIA GPU activated for demanding applications
- **Automatic**: Applications can request high-performance GPU
- **Manual**: `nvidia-offload` command for explicit GPU selection

## Storage Configuration  

### ZFS Layout for Laptops
The laptop storage configuration prioritizes reliability and power efficiency:

**Disk Partitioning**:
- **ESP**: 1GB EFI System Partition
- **Swap**: 8GB encrypted swap (smaller than desktop for battery efficiency)
- **LUKS**: Full disk encryption with SSD optimizations
- **ZFS**: Single pool with power-efficient settings

**ZFS Optimizations**:
```nix
zpool.options = {
  ashift = "12";                 # 4K sector alignment
  autotrim = "on";              # Automatic TRIM for SSD health
};

datasets = {
  "local/root" = {
    recordsize = "1M";          # System files optimization
    compression = "zstd";       # CPU-efficient compression
  };
  "local/nix" = {
    recordsize = "1M";          # Large files (Nix store)
    compression = "zstd";       
    "com.sun:auto-snapshot" = "false"; # No snapshots for Nix store
  };
};
```

**Power-Efficient Features**:
- **Automatic TRIM**: Maintains SSD performance and longevity
- **Compression**: Reduces writes to extend SSD life
- **Optimized Record Sizes**: Balances performance and space efficiency

## Thermal Management

### Thermal Control Systems
Multiple layers of thermal management ensure optimal performance and comfort:

1. **Hardware Level**:
   - Intel Speed Shift for rapid frequency scaling
   - ASUS fan curve management through hardware controls
   - CPU thermal throttling at hardware limits

2. **Kernel Level**:
   - `thermald`: Intel thermal daemon for proactive thermal management
   - Kernel thermal governors for CPU and GPU
   - ACPI thermal zone monitoring

3. **User Level**:
   - TLP thermal-aware power management
   - Auto-cpufreq for thermal-aware CPU scaling
   - Dynamic performance profile switching

### Thermal Optimization Parameters
```nix
boot.kernelParams = [
  "acpi_backlight=vendor";               # ASUS backlight control
  "acpi_osi=Linux";                      # Enhanced ACPI support
  "mem_sleep_default=deep";              # Deep sleep for better battery
  "i915.enable_psr=1";                   # Panel Self Refresh
  "i915.enable_fbc=1";                   # Framebuffer Compression
  "i915.enable_guc=2";                   # GuC/HuC firmware loading
];
```

## Connectivity and Peripherals

### Wireless Configuration
Optimized for mobile use with power-aware settings:

```nix
networking.networkmanager = {
  wifi.powersave = true;               # Enable WiFi power saving
  connectionConfig = {
    "wifi.powersave" = 3;             # Maximum WiFi power savings
  };
};
```

### Bluetooth Management
- **Power-Aware**: Bluetooth disabled on boot to save battery
- **Automatic**: Enabled when AC power detected
- **Smart Control**: Disabled when not in use on battery
- **Modern Stack**: BlueZ with experimental features for better device support

### Audio Configuration
Laptop-specific audio optimizations:
- **PipeWire**: Low-latency audio with power management
- **Power Saving**: Audio codec power management enabled
- **Hardware Support**: Intel HDA and USB audio device support
- **Bluetooth Audio**: High-quality codec support for wireless headphones

## Input Devices

### ASUS-Specific Features
- **ROG Keyboard**: Backlight control and special key mapping
- **Trackpad**: Advanced gesture support and palm rejection
- **Fingerprint Reader**: Goodix TOD driver support for secure login
- **Special Keys**: Function key mapping for ASUS-specific controls

### Brightness Control
Multiple brightness control methods:
- **Hardware Keys**: Native ASUS function key support
- **Software Control**: `brightnessctl` and `light` utilities
- **Automatic**: Location-aware brightness via `geoclue2`
- **Backlight**: Vendor-specific ACPI backlight control

## Performance Characteristics

### Performance Modes

**Battery Mode**:
- CPU limited to base frequency, no turbo boost
- GPU: Intel integrated only, NVIDIA disabled
- Storage: Aggressive power management, slower performance
- Network: Power-saving WiFi, Bluetooth disabled when idle
- Display: Reduced refresh rate, adaptive brightness

**AC Power Mode**:
- CPU: Full turbo boost, performance governor
- GPU: NVIDIA available on-demand for demanding tasks
- Storage: Maximum performance, reduced power management
- Network: Full performance WiFi, Bluetooth enabled
- Display: Maximum refresh rate, full brightness range

### Benchmarks and Expectations
- **Battery Life**: 6-8 hours typical use, 4-5 hours under load
- **Thermal Envelope**: 45W sustained, 65W+ burst performance
- **Performance Scaling**: 60-70% performance on battery vs AC
- **Wake Time**: <2 seconds from suspend, <10 seconds from hibernate

## Development Environment

### Mobile Development Optimizations
The laptop includes development tools optimized for mobile use:

```nix
development.enable = true;
```

**Optimized Features**:
- **Container Support**: Docker/Podman with power-aware settings
- **IDE Configuration**: VS Code and Zed with laptop-appropriate settings
- **Build Performance**: Balanced compilation settings for thermal management
- **Version Control**: Git with credential caching for mobile workflows

### Remote Development
- **SSH Configuration**: Ready for remote server development
- **VPN Support**: Network Manager VPN integration
- **Cloud Integration**: Credentials management via 1Password
- **Sync Tools**: Rsync and rclone for mobile file synchronization

## Power States and Sleep Management

### Sleep Configuration
Advanced sleep management for optimal battery life:

```nix
services.logind.settings = {
  HandleLidSwitch = "suspend";              # Suspend on lid close
  HandleLidSwitchDocked = "ignore";         # Don't suspend when docked
  HandlePowerKey = "suspend";               # Power button suspends
  HandleSuspendKey = "suspend";             # Suspend key action  
  HandleHibernateKey = "hibernate";         # Hibernate key action
};
```

### Suspend-Then-Hibernate
Innovative power management combining suspend and hibernation:
- **Phase 1**: Suspend to RAM for instant wake (first 2 hours)
- **Phase 2**: Automatic hibernation for long-term battery preservation
- **Benefits**: Fast wake times with zero battery drain for extended periods

## Installation and Setup

### Pre-Installation Requirements
1. **BIOS Configuration**:
   - Disable Secure Boot (temporarily for installation)
   - Enable UEFI mode
   - Configure GPU mode (Hybrid recommended)
   - Enable Intel VT-x for virtualization

2. **Hardware Verification**:
   - Run `lspci` to verify GPU bus IDs
   - Check WiFi card compatibility  
   - Verify NVMe SSD detection
   - Test keyboard special keys

### Installation Process
1. **Disk Preparation**: Update the arguments passed to `hardware/disko-layout.nix`
2. **Hardware Config**: Run `nixos-generate-config` for hardware detection
3. **GPU Configuration**: Verify and update PCI bus IDs for PRIME
4. **Network Setup**: Configure WiFi during installation
5. **User Setup**: Set user password and SSH keys

### Post-Installation Configuration
1. **Power Profile Testing**: Verify battery vs AC power behavior
2. **Thermal Testing**: Monitor temperatures under load
3. **Graphics Testing**: Verify hybrid graphics switching
4. **Peripheral Testing**: Test keyboard, trackpad, audio, WiFi
5. **Development Environment**: Set up development tools and credentials

## Maintenance and Monitoring

### Battery Health
- **Charge Thresholds**: Available on supported ASUS models (75-80% range)
- **Cycle Monitoring**: `upower` for battery statistics
- **Health Checks**: Regular battery capacity monitoring
- **Calibration**: Periodic full discharge/charge cycles

### Performance Monitoring
- **Power Consumption**: `powertop` for detailed power analysis
- **Thermal Monitoring**: `sensors` for temperature tracking
- **CPU Frequency**: Real-time governor and frequency monitoring  
- **GPU Usage**: Intel and NVIDIA GPU utilization tracking

### System Maintenance
- **Automatic Updates**: Controlled update schedule for stability
- **Thermal Paste**: Monitor temperatures for thermal paste degradation
- **Fan Cleaning**: Regular maintenance for optimal cooling
- **SSD Health**: Monitor SMART data and wear leveling

## Troubleshooting

### Common Issues

**Power Management**:
- Issue: Poor battery life
- Solution: Check TLP settings, verify power profiles active
- Tools: `powertop`, `tlp-stat`, `auto-cpufreq --stats`

**Graphics**:
- Issue: NVIDIA GPU always active
- Solution: Verify PRIME offload configuration, check running applications
- Tools: `nvidia-smi`, `intel_gpu_top`, `lspci -k`

**Thermal**:
- Issue: Excessive heat/throttling
- Solution: Check thermal daemon, verify fan operation, update thermal paste
- Tools: `sensors`, `thermald --adaptive --no-daemon`

**Sleep/Wake**:
- Issue: Won't suspend or wake properly
- Solution: Check kernel parameters, verify ACPI settings
- Tools: `journalctl -u systemd-suspend`, `dmesg | grep -i suspend`

### Recovery Procedures
- **Boot Recovery**: systemd-boot menu for kernel selection
- **Graphics Recovery**: Boot with `nomodeset` parameter
- **Power Recovery**: Disable TLP temporarily for testing
- **Network Recovery**: Use USB tethering or Ethernet adapter

## Limitations and Considerations

### Hardware Limitations
- **ASUS Specific**: Some features require ASUS hardware
- **NVIDIA Dependency**: Hybrid graphics requires specific NVIDIA mobile GPU
- **Thermal Constraints**: Performance limited by laptop thermal design
- **Battery Capacity**: Battery life depends on usage patterns and battery age

### Software Limitations  
- **Power Management**: Some applications may not respect power profiles
- **Graphics Switching**: Some applications may force NVIDIA GPU usage
- **Sleep Compatibility**: Some USB devices may prevent proper sleep
- **Thermal Control**: Limited compared to desktop thermal solutions

### Performance Trade-offs
- **Battery vs Performance**: Significant performance reduction on battery power
- **Thermal Throttling**: Performance may be limited by temperature constraints
- **Mobile Optimizations**: Some features sacrifice performance for power efficiency
- **Hybrid Graphics**: Occasional graphics switching delays or incompatibilities