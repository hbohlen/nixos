# Host Configuration Documentation

This directory contains comprehensive documentation for each host type in the NixOS configuration.

## Host Types

### [Desktop](./desktop.md)
High-performance desktop workstation configuration with Intel CPU and NVIDIA GPU support. Optimized for development work, multimedia tasks, and general productivity with full desktop environment.

**Key Features**:
- Intel CPU + NVIDIA GPU with hybrid graphics
- Full desktop environment (GNOME + Hyprland)
- Development tools and IDEs
- Performance-optimized ZFS layout
- 16GB swap for large desktop applications

### [Laptop](./laptop.md)  
Mobile-optimized configuration for ASUS ROG Zephyrus series and similar laptops. Emphasizes power management, battery life, and thermal efficiency while maintaining performance capabilities.

**Key Features**:
- ASUS ROG Zephyrus hardware support
- Advanced power management with TLP
- Hybrid NVIDIA/Intel graphics with PRIME offload
- Thermal management and battery optimization
- Suspend-then-hibernate for extended battery life

### [Server](./server.md)
Headless server configuration optimized for stability, security, and 24/7 operation. Designed for service hosting, containerized applications, and always-on server workloads.

**Key Features**:
- Headless operation without desktop environment
- Enhanced security and firewall configuration
- Container and virtualization support
- Performance tuning for server workloads
- Minimal resource footprint

## Common Architecture

All host configurations share the following architectural elements:

### Storage Architecture
- **ZFS on LUKS**: Full disk encryption with ZFS filesystem
- **Impermanence**: Ephemeral root with opt-in persistence  
- **Disko**: Declarative disk partitioning and formatting
- **Host-Specific Layouts**: Optimized swap and partition sizes

### Security Framework
- **SSH Key Authentication**: Password authentication disabled in production
- **Full Disk Encryption**: LUKS encryption for data at rest
- **Firewall Protection**: UFW with host-appropriate rules
- **Fail2Ban**: Automatic intrusion prevention

### Package Management
- **Nix Flakes**: Reproducible and declarative system configuration
- **Home Manager**: User environment management
- **Unfree Packages**: Controlled inclusion of proprietary software
- **Overlays**: Custom package modifications and additions

### Boot and Hardware
- **systemd-boot**: Modern UEFI boot loader
- **Hardware Profiles**: nixos-hardware integration for specific devices  
- **Kernel Optimization**: Host-specific kernel parameters
- **Microcode Updates**: Automatic CPU microcode updates

## Configuration Structure

Each host follows a consistent configuration pattern:

```
hosts/{hostname}/
├── default.nix              # Main host configuration
├── hardware-configuration.nix # Hardware-specific settings  
└── hardware/
    ├── disko-layout.nix     # Calls shared Disko template with host parameters
    └── disko-zfs.nix        # Disko module integration
```

### Configuration Flow
1. **flake.nix**: Defines host in system configurations
2. **hosts/{hostname}/default.nix**: Main host configuration and module imports
3. **hardware-configuration.nix**: Hardware detection and device-specific settings
4. **hardware/disko-layout.nix**: Declarative disk layout built from
   `profiles/hardware/disko/zfs-impermanence.nix`
5. **modules/nixos/**: Shared system modules imported by hosts
6. **users/**: Home Manager configurations for user environments

## Hardware Requirements

### Minimum Requirements
- **CPU**: Modern x86_64 processor (Intel/AMD)
- **RAM**: 8GB minimum, 16GB+ recommended
- **Storage**: 256GB SSD minimum for desktop/laptop, 128GB for server
- **Network**: Ethernet or WiFi connectivity
- **UEFI**: Modern UEFI firmware (BIOS mode not supported)

### Recommended Specifications
- **Desktop**: Intel CPU + NVIDIA GPU, 32GB RAM, 1TB NVMe SSD
- **Laptop**: Intel mobile CPU + NVIDIA mobile GPU, 16GB+ RAM, 512GB+ NVMe SSD
- **Server**: Server-grade CPU, 32GB+ RAM, enterprise SSD/HDD

## Installation Guide

### General Installation Process
1. **Hardware Preparation**:
   - Enable UEFI mode in firmware
   - Disable Secure Boot (temporarily for installation)
   - Verify hardware compatibility

2. **Configuration Preparation**:
   - Update device paths via the arguments passed to `hardware/disko-layout.nix`
   - Generate hardware configuration with `nixos-generate-config`
   - Configure SSH keys and user settings

3. **Installation**:
   - Boot from NixOS installation media
   - Run installation using flake configuration
   - Verify system functionality post-installation

4. **Post-Installation**:
   - Change default passwords
   - Configure SSH key authentication
   - Test host-specific features
   - Set up backup and monitoring

### Host-Specific Considerations
- **Desktop**: Verify NVIDIA driver installation and multi-monitor setup
- **Laptop**: Test power management, thermal controls, and hybrid graphics
- **Server**: Configure network settings, firewall rules, and services

## Security Configuration

### SSH Security
```nix
# Example SSH configuration (add to host default.nix)
users.sshKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... your-key" ];
users.enablePasswordAuth = false;  # Disable after SSH keys configured
```

### Firewall Configuration
Each host type has appropriate default firewall rules:
- **Desktop**: Restrictive rules for personal use
- **Laptop**: Mobile-appropriate rules with VPN support  
- **Server**: Server-focused rules with service ports

### Encryption
All hosts use multiple layers of encryption:
- **Disk Encryption**: LUKS full disk encryption
- **Swap Encryption**: Random encryption for swap partitions
- **Network Encryption**: SSH, TLS, and VPN encryption
- **Backup Encryption**: Encrypted backups with Borg/Restic

## Performance Optimization

### Host-Specific Optimizations
- **Desktop**: Maximum performance, large swap, high-performance governors
- **Laptop**: Power efficiency, thermal management, battery optimization
- **Server**: 24/7 stability, low latency, resource efficiency

### ZFS Optimization
- **Record Sizes**: Optimized for workload patterns (1M for system, 128K for mixed)
- **Compression**: ZSTD for excellent compression/performance balance
- **ARC Tuning**: Automatic memory management based on available RAM
- **TRIM Support**: Automatic TRIM for SSD longevity

## Troubleshooting

### Common Issues
1. **Boot Problems**: Use systemd-boot menu for recovery options
2. **Graphics Issues**: Check driver installation and PCI bus IDs
3. **Network Problems**: Verify network manager configuration
4. **Storage Issues**: Check ZFS pool status and disk health

### Diagnostic Tools
- **System**: `journalctl`, `systemctl`, `dmesg`
- **Hardware**: `lspci`, `lsusb`, `lscpu`, `sensors`
- **Network**: `ip`, `ss`, `ping`, `traceroute`
- **Storage**: `zpool status`, `zfs list`, `lsblk`, `smartctl`

### Recovery Procedures
- **System Recovery**: Boot from installation media, import ZFS pool
- **Configuration Recovery**: Git history and configuration rollback
- **Data Recovery**: ZFS snapshots and backup restoration
- **Hardware Recovery**: Hardware replacement and configuration migration

## Contributing

When modifying host configurations:

1. **Test Changes**: Use `nixos-rebuild build --flake .#hostname` to test
2. **Document Changes**: Update relevant documentation
3. **Security Review**: Ensure security implications are addressed
4. **Performance Testing**: Verify performance impact
5. **Cross-Host Impact**: Consider effects on other host types

### Best Practices
- Keep host-specific settings in host configurations
- Use shared modules for common functionality  
- Document hardware-specific requirements
- Test on actual hardware when possible
- Maintain backward compatibility when feasible

## References

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Disko Documentation](https://github.com/nix-community/disko)
- [Impermanence Documentation](https://github.com/nix-community/impermanence)
- [ZFS on Linux Documentation](https://openzfs.github.io/openzfs-docs/)