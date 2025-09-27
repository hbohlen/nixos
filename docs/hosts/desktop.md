# Desktop Host Configuration

## Overview

The desktop host configuration is optimized for high-performance desktop workstations with Intel CPU and NVIDIA GPU combinations. This configuration provides a complete desktop environment suitable for development work, multimedia tasks, and general productivity.

## Hardware Profile

### Supported Hardware
- **CPU**: Intel processors (primary support)
- **GPU**: NVIDIA discrete graphics with Intel integrated graphics
- **Storage**: NVMe SSDs (preferred) or SATA SSDs/HDDs
- **RAM**: 16GB+ recommended for optimal performance
- **Motherboard**: Standard desktop motherboards with MSI profiles when available

### Hardware-Specific Modules
- `profiles/hardware/intel-desktop.nix`: Aggregates nixos-hardware Intel/desktop modules and
  low-level boot configuration.
- `modules/nixos/nvidia-rog.nix`: NVIDIA GPU configuration with hybrid graphics

## Storage Configuration

### ZFS Layout Optimizations
The desktop uses a performance-optimized ZFS configuration with the following characteristics:

**Disk Partitioning (`hardware/disko-layout.nix`)** (via
`profiles/hardware/disko/zfs-impermanence.nix`):
- **ESP**: 1GB EFI System Partition for boot files
- **Swap**: 16GB encrypted swap (larger than laptop/server for desktop workloads)
- **LUKS**: Full disk encryption with discard support for SSD optimization
- **ZFS Pool**: Single `rpool` with multiple datasets for different use cases

**ZFS Dataset Optimization**:
```nix
"local/root" = {
  recordsize = "1M";        # Optimized for system files
  compression = "zstd";     # Balanced compression/performance
  mountpoint = "legacy";    # Integration with impermanence
};

"local/nix" = {
  recordsize = "1M";        # Large files (Nix store packages)
  compression = "zstd";
  "com.sun:auto-snapshot" = "false"; # No snapshots for Nix store
};

"safe/persist" = {
  recordsize = "128K";      # Mixed workload optimization
  compression = "zstd";     # Persistent system data
};

"safe/home" = {
  recordsize = "128K";      # User files mixed workload
  compression = "zstd";     # User data with compression
};
```

**Performance Characteristics**:
- **Sequential Read/Write**: Optimized for large files with 1M recordsize on system datasets
- **Random I/O**: Balanced 128K recordsize for user data and mixed workloads
- **Compression**: ZSTD provides excellent compression ratios with minimal CPU overhead
- **Deduplication**: Disabled for performance (not needed with Nix store)

## Graphics Configuration

### NVIDIA GPU Setup
The desktop uses the proprietary NVIDIA drivers with hybrid graphics support:

```nix
hardware.nvidia = {
  modesetting.enable = true;          # Required for Wayland/modern display
  nvidiaSettings = true;              # GUI configuration tool
  open = false;                       # Proprietary drivers for older GPUs
  powerManagement.enable = true;      # Power management support
  dynamicBoost.enable = true;         # Performance optimization
  
  prime = {
    offload.enable = true;            # PRIME offload for hybrid graphics
    intelBusId = "PCI:0:2:0";        # Intel iGPU bus ID
    nvidiaBusId = "PCI:1:0:0";       # NVIDIA dGPU bus ID
  };
};
```

### Display Support
- **Wayland**: Primary display protocol via Hyprland
- **X11**: XWayland compatibility for legacy applications
- **Multi-monitor**: Native support with PRIME offload
- **High DPI**: Automatic scaling support

## Desktop Environment

### Available Environments
1. **GNOME**: Full-featured desktop environment
   - Native Wayland support
   - Integrated settings and applications
   - Excellent hardware support
   
2. **Hyprland**: Modern Wayland compositor
   - Tiling window management
   - Advanced animations and effects
   - Highly customizable

### System Services
- **Audio**: PipeWire with ALSA, PulseAudio, and JACK compatibility
- **Bluetooth**: Full desktop Bluetooth stack with Blueman GUI
- **Printing**: CUPS with network printer discovery via Avahi
- **Security**: Polkit, AppArmor, GNOME Keyring integration

## Performance Tuning

### CPU Configuration
- **Governor**: Performance mode (desktop workloads prioritize performance)
- **Microcode**: Intel microcode updates enabled
- **KVM**: Virtualization support enabled

### Memory Management
- **Swap**: 16GB encrypted swap for large desktop applications
- **ZFS ARC**: Automatic tuning based on available RAM
- **Kernel Parameters**: Standard desktop optimizations

### Boot Optimization
- **systemd-boot**: Fast UEFI boot loader
- **EFI Variables**: Full EFI variable support
- **Kernel Modules**: Hardware-specific modules loaded early

## Development Support

### Development Tools
The desktop includes comprehensive development environment support:

```nix
development.enable = true;
```

This enables:
- **IDEs**: VS Code, Zed Editor
- **Languages**: Multiple programming language support
- **Containers**: Docker and Podman for containerized development
- **Virtualization**: QEMU/KVM for testing and development VMs

### Package Management
- **Unfree Packages**: Enabled for proprietary development tools
- **Overlays**: Custom package overlays for development needs
- **Flakes**: Modern Nix flakes for reproducible environments

## Security Configuration

### Encryption
- **Full Disk Encryption**: LUKS with strong cryptographic settings
- **Swap Encryption**: Random encryption for swap security
- **SSH Keys**: Key-based authentication (configure after installation)

### Network Security
- **Firewall**: UFW with desktop-appropriate rules
- **SSH**: Disabled by default (enable if needed)
- **AppArmor**: Application sandboxing enabled

### Access Control
- **Polkit**: Privilege escalation for desktop applications
- **1Password**: GUI integration with system authentication
- **GNOME Keyring**: Secure credential storage

## Installation Requirements

### Minimum Specifications
- **CPU**: Modern Intel processor with virtualization support
- **RAM**: 8GB minimum, 16GB+ recommended
- **Storage**: 256GB SSD minimum, 512GB+ recommended
- **GPU**: NVIDIA GPU with latest driver support

### Pre-Installation Steps
1. **Hardware Detection**: Run `nixos-generate-config` for hardware detection
2. **Disk Identification**: Update the arguments passed to `hardware/disko-layout.nix`
3. **GPU Bus IDs**: Verify PCI bus IDs with `lspci` for PRIME configuration
4. **BIOS Settings**: Enable UEFI mode, disable Secure Boot initially

### Post-Installation Configuration
1. **SSH Keys**: Add SSH public keys for remote access
2. **User Password**: Change from default "changeme" password
3. **NVIDIA Settings**: Configure display outputs and performance profiles
4. **Development Environment**: Configure IDEs and development tools

## Maintenance and Updates

### Regular Maintenance
- **System Updates**: Automatic daily updates configured
- **ZFS Scrubs**: Monthly filesystem integrity checks
- **Package Cleanup**: Automatic old generation cleanup
- **Log Rotation**: Systemd journal with size limits

### Performance Monitoring
- **System Monitor**: GNOME System Monitor for GUI monitoring
- **CLI Tools**: htop, btop for command-line monitoring
- **Hardware Sensors**: lm_sensors for temperature monitoring
- **GPU Monitoring**: nvidia-smi for GPU utilization

### Troubleshooting
- **Boot Issues**: Recovery via systemd-boot menu
- **Graphics Issues**: Fallback to integrated graphics
- **Storage Issues**: ZFS resilience and snapshot recovery
- **Driver Issues**: Kernel module debugging and rollback

## Limitations and Considerations

### Known Limitations
- **NVIDIA Wayland**: Some applications may have compatibility issues
- **Power Consumption**: Desktop optimized for performance over power efficiency
- **Gaming Support**: Removed gaming-specific optimizations (general-purpose configuration)
- **Hardware Compatibility**: Intel + NVIDIA combination required

### Performance Trade-offs
- **Memory Usage**: Higher memory usage due to desktop environment and services
- **Boot Time**: Longer boot time due to comprehensive hardware detection
- **Power Draw**: Higher power consumption compared to laptop configuration
- **Storage Space**: Larger installation footprint with desktop applications

### Migration Considerations
- **From Gaming Setup**: Gaming-specific configurations have been removed
- **Hardware Changes**: Update PCI bus IDs when changing GPU hardware  
- **Monitor Configuration**: Multi-monitor setups may require manual configuration
- **Performance Profiles**: Adjust NVIDIA settings based on workload requirements