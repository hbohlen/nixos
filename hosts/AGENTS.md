# Host Configurations - Comprehensive Documentation

## Directory Purpose
This directory contains host-specific NixOS configurations for different machine types and roles. Each subdirectory represents a complete system configuration tailored for specific hardware and use cases, implementing the modular architecture with host-specific optimizations.

## Host Types and Architecture

### Configuration Philosophy
Each host configuration follows a layered architecture pattern:

```
┌─────────────────────────────────────────────┐
│              Host Configuration              │
│  ┌─────────────────────────────────────────┐ │
│  │         Hardware-Specific Layer         │ │
│  │  • hardware-configuration.nix          │ │  
│  │  • hardware/disko-zfs.nix             │ │
│  │  • Hardware-specific modules           │ │
│  └─────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────┐ │
│  │            Role-Specific Layer          │ │
│  │  • Desktop environment                 │ │
│  │  • Server hardening                    │ │
│  │  • Laptop power management            │ │
│  └─────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────┐ │
│  │           Common System Layer           │ │
│  │  • Base system configuration          │ │
│  │  • User management                     │ │
│  │  • Network and security               │ │
│  └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

## Host Type Specifications

### Desktop Configuration (`desktop/`)

**Purpose**: High-performance desktop workstation optimized for development, multimedia, and intensive computing tasks.

#### Hardware Profile
- **CPU**: Intel processors with performance optimization
- **GPU**: NVIDIA discrete graphics with proprietary drivers
- **Memory**: 16GB+ RAM with performance tuning
- **Storage**: NVMe SSD with ZFS for maximum performance
- **Cooling**: Advanced thermal management for sustained performance

#### Software Stack
```nix
# Key modules imported by desktop configuration
modules = [
  ../../modules/nixos/common.nix         # Base system
  ../../modules/nixos/boot.nix          # Boot optimization
  ../../modules/nixos/desktop.nix       # Desktop environment
  ../../modules/nixos/development.nix   # Development tools
  ../../modules/nixos/nvidia-rog.nix    # Graphics drivers
  ../../modules/nixos/impermanence.nix  # Ephemeral root
  ../../modules/nixos/users.nix         # User management
];
```

#### Configuration Features
- **Performance-First**: CPU governors set to performance mode
- **Graphics Acceleration**: Full NVIDIA support with CUDA capabilities
- **Development Environment**: Complete development toolchain
- **Multimedia Support**: Hardware video decoding, professional audio
- **High-Resolution Display**: 4K/multi-monitor support
- **Gaming Capabilities**: Steam, GPU acceleration, low latency

#### Optimization Parameters
```nix
# Desktop-specific optimizations
desktop = {
  enable = true;
  environment = "hyprland";  # High-performance Wayland compositor
};

development = {
  enable = true;  # Full development stack
};

# Performance tuning
boot.kernelParams = [
  "quiet"
  "splash"
  "mitigations=off"  # Security vs performance trade-off
];

# High-performance CPU governor
powerManagement.cpuFreqGovernor = "performance";
```

#### Troubleshooting Desktop Issues
- **Graphics problems**: Check NVIDIA driver compatibility and Wayland support
- **Performance issues**: Monitor CPU throttling and thermal management
- **Display problems**: Verify multi-monitor configuration and refresh rates
- **Development issues**: Check development environment package conflicts

### Laptop Configuration (`laptop/`)

**Purpose**: Portable computing optimized for battery life, thermal management, and mobile productivity.

#### Hardware Profile
- **CPU**: Intel mobile processors with power efficiency focus
- **GPU**: Hybrid Intel/NVIDIA graphics with PRIME switching
- **Memory**: 16GB+ LPDDR with power optimization
- **Storage**: NVMe SSD with power-efficient ZFS settings
- **Battery**: Advanced power management and charge control
- **Display**: Power-efficient display management

#### Software Stack
```nix
# Laptop-specific module configuration
modules = [
  ../../modules/nixos/common.nix         # Base system
  ../../modules/nixos/boot.nix          # Optimized boot
  ../../modules/nixos/desktop.nix       # Desktop environment
  ../../modules/nixos/laptop.nix        # Power management
  ../../modules/nixos/development.nix   # Development tools
  ../../modules/nixos/impermanence.nix  # Ephemeral root
  ../../modules/nixos/users.nix         # User management
  inputs.nixos-hardware.nixosModules.asus-zephyrus-gu603h  # Hardware profile
];
```

#### Power Management Features
- **TLP Integration**: Advanced power management with profile switching
- **CPU Scaling**: Dynamic frequency scaling based on AC/battery status
- **GPU Switching**: PRIME offloading for hybrid graphics
- **Thermal Management**: Temperature-based throttling and fan control
- **Sleep Optimization**: Suspend-to-RAM and hibernate support
- **Battery Protection**: Charge thresholds and battery health monitoring

#### Configuration Parameters
```nix
# Power-efficient settings
services.tlp = {
  enable = true;
  settings = {
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    
    # Battery optimization
    START_CHARGE_THRESH_BAT0 = 20;
    STOP_CHARGE_THRESH_BAT0 = 80;
    
    # Device power management
    USB_AUTOSUSPEND = 1;
    WIFI_PWR_ON_BAT = "on";
  };
};

# Hybrid graphics configuration
hardware.nvidia = {
  modesetting.enable = true;
  prime = {
    offload.enable = true;
    # Device IDs specific to hardware
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };
};
```

#### Laptop-Specific Troubleshooting
- **Battery issues**: Check TLP configuration and battery health
- **Thermal problems**: Monitor temperature and fan operation
- **Graphics switching**: Verify PRIME configuration and GPU detection
- **WiFi problems**: Check power management and driver compatibility
- **Suspend issues**: Verify suspend/resume functionality and wake sources

### Server Configuration (`server/`)

**Purpose**: Headless server optimized for stability, security, and resource efficiency with minimal overhead.

#### Hardware Profile
- **CPU**: Server-grade processors optimized for 24/7 operation
- **Memory**: ECC RAM for data integrity (when available)
- **Storage**: Enterprise SSD/HDD with redundancy
- **Network**: Gigabit Ethernet with redundancy options
- **Management**: IPMI/BMC for remote management

#### Software Stack
```nix
# Minimal server configuration
modules = [
  ../../modules/nixos/common.nix         # Base system (minimal)
  ../../modules/nixos/boot.nix          # Secure boot
  ../../modules/nixos/server.nix        # Server hardening
  ../../modules/nixos/impermanence.nix  # Ephemeral root
  ../../modules/nixos/users.nix         # User management
];
```

#### Security Hardening Features
- **SSH Hardening**: Key-only authentication, connection limits, security settings
- **Firewall**: Strict firewall rules with minimal open ports
- **Service Minimization**: Only essential services enabled
- **Access Control**: Restricted user privileges and sudo access
- **Audit Logging**: Comprehensive system and security event logging
- **Automatic Updates**: Automated security updates with rollback capability

#### Server Configuration Parameters
```nix
# Security-first configuration
services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "no";
    MaxAuthTries = 3;
    ClientAliveInterval = 300;
    Protocol = 2;
    X11Forwarding = false;
    AllowTcpForwarding = false;
  };
};

# Minimal desktop components (for emergency access)
services.xserver.enable = false;
sound.enable = false;

# Network security
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ 22 ];  # SSH only
  logReversePathDrops = true;
  pingLimit = "--limit 1/minute --limit-burst 5";
};

# Performance optimization for server workloads
powerManagement.cpuFreqGovernor = "ondemand";
```

#### Server-Specific Troubleshooting
- **SSH access issues**: Check firewall rules and SSH service configuration
- **Security concerns**: Review logs and security service status
- **Performance monitoring**: Monitor CPU, memory, and disk usage
- **Service failures**: Check systemd service status and dependencies
- **Network connectivity**: Verify network configuration and routing

## Host Configuration Best Practices

### Hardware Configuration Management

#### Hardware Detection and Configuration
```nix
# Generated hardware configuration (hardware-configuration.nix)
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Boot configuration
  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Filesystem configuration
  fileSystems."/" = {
    device = "rpool/local/root";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/XXXX-XXXX";
    fsType = "vfat";
  };

  # Hardware-specific settings
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
};
```

#### Custom Hardware Modules
```nix
# hardware/custom-hardware.nix
{ config, lib, pkgs, ... }:

{
  # Custom hardware-specific configuration
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;
  
  # Hardware-specific kernel modules
  boot.kernelModules = [
    "acpi_call"      # ACPI functionality
    "coretemp"       # Temperature monitoring
  ];
  
  # Hardware-specific services
  services.fwupd.enable = true;  # Firmware updates
  services.thermald.enable = true;  # Thermal management
};
```

### Disk Configuration Management

#### ZFS Pool Configuration
```nix
# hardware/disko-zfs.nix - Host-specific disk layout
{ lib, ... }:

{
  disko.devices = {
    disk.main = {
      device = "/dev/disk/by-id/nvme-specific-device-id";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1G";
            type = "EF00";  # EFI System Partition
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypt-root";
              settings.allowDiscards = true;
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };
    };

    zpool.rpool = {
      type = "zpool";
      options = {
        ashift = "12";
        autotrim = "on";
        compression = "zstd";
      };
      
      datasets = {
        "local" = {
          type = "zfs_fs";
          options.canmount = "off";
        };
        "local/root" = {
          type = "zfs_fs";
          mountpoint = "/";
          options.canmount = "noauto";
        };
        # Additional datasets...
      };
    };
  };
}
```

### Network Configuration Patterns

#### Host-Specific Networking
```nix
# Host networking configuration
networking = {
  hostName = "hostname";
  hostId = "abcd1234";  # Required for ZFS, must be unique per host
  
  # Network interface configuration
  interfaces = {
    enp0s31f6 = {
      useDHCP = true;
    };
    wlp0s20f3 = {
      useDHCP = true;
    };
  };
  
  # Wireless configuration
  wireless = {
    enable = false;  # Use NetworkManager instead
    userControlled.enable = true;
  };
  
  networkmanager = {
    enable = true;
    wifi.powersave = false;  # Disable for performance
  };
};
```

## Integration and Dependency Management

### Module Integration Patterns
```nix
# Host default.nix integration pattern
{ config, lib, pkgs, inputs, username, ... }:

{
  imports = [
    # Hardware configuration
    ./hardware-configuration.nix
    ./hardware/disko-zfs.nix
    
    # System modules
    ../../modules/nixos/common.nix
    ../../modules/nixos/boot.nix
    
    # Role-specific modules
    ../../modules/nixos/desktop.nix    # Desktop only
    ../../modules/nixos/laptop.nix     # Laptop only
    ../../modules/nixos/server.nix     # Server only
    
    # Common modules
    ../../modules/nixos/impermanence.nix
    ../../modules/nixos/users.nix
    
    # Hardware-specific modules
    ../../modules/nixos/nvidia-rog.nix # When applicable
    
    # External hardware profiles
    inputs.nixos-hardware.nixosModules.asus-zephyrus-gu603h  # When applicable
  ];
  
  # Host-specific configuration
  networking.hostName = "hostname";
  networking.hostId = "unique-id";
  
  # Enable role-specific features
  desktop.enable = true;      # Desktop/laptop
  development.enable = true;  # Desktop/laptop
  
  # System state version
  system.stateVersion = "25.05";
}
```

### Home Manager Integration
```nix
# Home Manager host integration
home-manager = {
  useGlobalPkgs = true;
  useUserPackages = true;
  extraSpecialArgs = { 
    inherit inputs username; 
  };
  
  users.${username} = {
    imports = [
      ../../users/${username}/home.nix
      ../../modules/home-manager/desktop.nix
      ../../modules/home-manager/opnix.nix
    ];
    
    # Host-specific user configuration
    programs.git.userName = "User Name";
    programs.git.userEmail = "user@example.com";
  };
};
```

## Maintenance and Deployment

### Host Deployment Procedures
1. **New Host Setup**:
   ```bash
   # Clone configuration
   git clone https://github.com/hbohlen/nixos.git
   cd nixos
   
   # Create host configuration
   cp -r hosts/desktop hosts/new-host
   
   # Update configuration
   vim hosts/new-host/default.nix
   vim hosts/new-host/hardware-configuration.nix
   
   # Add to flake.nix
   vim flake.nix
   
   # Test configuration
   nixos-rebuild build --flake .#new-host
   ```

2. **Host Maintenance**:
   ```bash
   # Regular updates
   nix flake update
   nixos-rebuild switch --flake .#hostname
   
   # System cleanup
   nix-collect-garbage -d
   nixos-rebuild switch --flake .#hostname
   ```

### Monitoring and Health Checks
```bash
# System health monitoring
systemctl --failed                    # Check failed services
zpool status                         # Check ZFS health
journalctl -p err -S today           # Check error logs
df -h                               # Check disk usage
free -h                             # Check memory usage

# Host-specific checks
tlp-stat -s                         # Laptop power status
nvidia-smi                          # Desktop GPU status
ss -tuln                           # Server network services
```

This comprehensive host configuration documentation provides detailed guidance for understanding, configuring, and maintaining different host types in the NixOS configuration system.