# NixOS Configuration - Comprehensive Agent Guidelines

## 🏗️ Repository Architecture

This repository implements a modern, declarative NixOS configuration system using:

- **Nix Flakes**: Reproducible system configurations with pinned dependencies
- **Disko**: Declarative disk partitioning and ZFS filesystem setup
- **ZFS with LUKS**: Encrypted, snapshot-capable filesystems with data integrity
- **Impermanence**: Ephemeral root filesystem for enhanced security and cleanliness
- **Home Manager**: Declarative user environment and application management
- **Modular Design**: Reusable components organized by functionality and host type

### Key Components

#### Core System Components
- **`flake.nix`**: Entry point defining all inputs, outputs, and system configurations
- **`hosts/`**: Host-specific configurations for desktop, laptop, and server roles
- **`modules/nixos/`**: System-level modules for core functionality and hardware
- **`modules/home-manager/`**: User-level modules for desktop environments and applications
- **`users/`**: Per-user Home Manager configurations and preferences
- **`scripts/`**: System management and automation utilities

#### Advanced Features
- **Ephemeral Root**: `/` is mounted on tmpfs, wiped on every boot for security
- **Selective Persistence**: Only explicitly defined files/directories survive reboots via `/persist`
- **ZFS Snapshots**: Automatic system state snapshots for rollback capabilities
- **Encrypted Storage**: Full disk encryption using LUKS for data protection
- **Runtime Secrets**: Secrets managed via Opnix/1Password integration (never committed)

## 🚀 Build Commands

### Primary Build Operations
- **Full rebuild**: `./scripts/rebuild.sh` (auto-detects hostname, preferred method)
- **Manual rebuild**: `sudo nixos-rebuild switch --flake .#hostname`
- **Test build**: `nixos-rebuild build --flake .#hostname` (safe testing)
- **Dry run**: `nixos-rebuild dry-activate --flake .#hostname` (preview changes)

### Validation and Maintenance  
- **Check config**: `nix flake check` (validate flake syntax and dependencies)
- **Format code**: `./scripts/format.sh` or `npm run fmt`
- **Lint check**: `./scripts/format.sh --check` or `npm run fmt:check`
- **Update inputs**: `nix flake update` (update all flake inputs)

### Installation and Recovery
- **Fresh install**: `./scripts/install.sh` (disko-based installation from NixOS ISO)
- **Bootstrap**: `./scripts/bootstrap.sh` (one-line installation from web)
- **Emergency recovery**: Boot from NixOS ISO and use ZFS rollback capabilities

## 📝 Development Standards

### Module Structure and Conventions
- **Module signature**: Always use `{ config, pkgs, lib, inputs, ... }:` (include `...`)
- **Imports**: Use relative paths like `../../modules/` for portability
- **Options**: Define using `lib.mkOption` with proper types and descriptions
- **Conditionals**: Use `lib.mkIf` for conditional configuration
- **Defaults**: Use `lib.mkDefault` for overridable default values
- **Error handling**: Use `lib.optionalAttrs`, `lib.optionalString` for safety

### Naming Conventions
- **Files**: kebab-case (`desktop-config.nix`, `nvidia-rog.nix`)
- **Options**: camelCase (`desktop.enable`, `development.enableTools`)
- **Variables**: snake_case (`user_name`, `host_type`)
- **Attributes**: Follow NixOS conventions

### Code Formatting
- **Indentation**: 2 spaces (no tabs)
- **Line length**: <100 characters for readability
- **Trailing commas**: Always use for list/attribute set items
- **Comments**: Descriptive comments for complex logic
- **Documentation**: Include descriptions for all custom options

## 🔒 Security Guidelines

### Critical Security Rules
- **Never commit secrets**: Use Opnix/1Password for runtime secret injection
- **Test before switch**: Always use `nixos-rebuild build` before `switch`
- **Validate hardware**: Test hardware-specific configs on target hardware
- **Review changes**: Use `nixos-rebuild dry-activate` to preview system changes
- **Backup critical data**: Ensure important data is in `/persist` or backed up

### Security Features
- **SSH hardening**: Key-based auth only, no passwords, connection limits
- **Firewall**: Enabled by default with minimal open ports
- **User isolation**: Non-root users with sudo via wheel group
- **Ephemeral root**: Automatic cleanup of temporary files and potential malware
- **Encrypted storage**: Full disk encryption for data at rest protection

## 🛠️ Troubleshooting Guide

### Common Issues and Solutions

#### Build/Configuration Issues
- **Flake check fails**: Run `nix flake check --show-trace` for detailed errors
- **Module import errors**: Verify relative paths and module structure
- **Package conflicts**: Check for version mismatches in flake inputs
- **Option type errors**: Ensure proper types in `lib.mkOption` definitions

#### Boot and Filesystem Issues
- **Boot failure**: Boot from NixOS ISO, import ZFS pool, check system generations
- **ZFS import failure**: Check pool status with `zpool status`, may need `zpool import -f`
- **Impermanence issues**: Verify `/persist` mount and directory structure
- **LUKS unlock failure**: Check passphrase, may need emergency recovery

#### Hardware-Specific Issues
- **NVIDIA problems**: Check driver version compatibility and kernel modules
- **Power management**: Verify TLP configuration and conflicting services
- **Network issues**: Check NetworkManager status and firewall rules
- **Display issues**: Verify Wayland/X11 configuration and GPU drivers

#### Performance Issues
- **Slow boot**: Check systemd service dependencies and initrd modules
- **High memory usage**: Monitor ZFS ARC usage and adjust if needed
- **Disk space**: Check ZFS snapshot usage and cleanup old snapshots
- **Network latency**: Review firewall rules and network configuration

### Recovery Procedures

#### System Recovery
1. **Boot from NixOS ISO**: Use live environment for recovery
2. **Import ZFS pool**: `zpool import rpool` to access filesystems
3. **Mount filesystems**: Mount `/mnt` and `/mnt/persist` as needed
4. **Rollback system**: Use `nixos-rebuild --rollback` or select older generation
5. **ZFS rollback**: `zfs rollback rpool/local/root@blank` for clean state

#### Data Recovery
1. **Access persistent data**: Mount `/persist` to access important files
2. **Snapshot recovery**: Use `zfs list -t snapshot` to find and restore snapshots
3. **Emergency shell**: Use `systemctl rescue` for minimal recovery environment
4. **Backup restoration**: Restore from external backups if available

## 📚 Module Documentation

### System Modules (`modules/nixos/`)
- **`common.nix`**: Base system configuration shared across all hosts
- **`boot.nix`**: Boot loader, kernel, and early-boot configuration
- **`desktop.nix`**: Desktop environment setup (GNOME, Hyprland)
- **`development.nix`**: Development tools and programming environments
- **`laptop.nix`**: Laptop-specific power management and hardware optimizations
- **`server.nix`**: Server hardening, SSH configuration, and security settings
- **`impermanence.nix`**: Ephemeral root filesystem with selective persistence
- **`nvidia-rog.nix`**: NVIDIA graphics and ROG hardware support
- **`users.nix`**: User account management and SSH key configuration
- **`unfree-packages.nix`**: Centralized management of proprietary software licenses

### Home Manager Modules (`modules/home-manager/`)
- **`desktop.nix`**: User desktop environment with Hyprland compositor
- **`opnix.nix`**: 1Password integration for secret management

### Host Configurations (`hosts/`)
- **`desktop/`**: High-performance desktop with Intel CPU + NVIDIA GPU
- **`laptop/`**: Portable configuration with power management optimizations  
- **`server/`**: Headless server with security hardening and minimal overhead

## 🔄 Development Workflow

### Adding New Features
1. **Plan changes**: Design module structure and options
2. **Create module**: Follow existing patterns and conventions
3. **Test locally**: Use `nixos-rebuild build` for validation
4. **Document options**: Add descriptions and examples
5. **Test across hosts**: Verify compatibility with different host types
6. **Update documentation**: Ensure AGENTS.md files are current

### Modifying Existing Components
1. **Understand impact**: Review module dependencies and usage
2. **Test changes**: Use dry-run to preview effects
3. **Backward compatibility**: Maintain compatibility when possible
4. **Update documentation**: Reflect changes in relevant AGENTS.md files
5. **Cross-host testing**: Test on all affected host types

### Best Practices
- **Incremental changes**: Make small, focused modifications
- **Test thoroughly**: Validate on target hardware when possible
- **Document decisions**: Explain complex configuration choices
- **Review security**: Consider security implications of all changes
- **Monitor performance**: Check for performance regressions
- **Maintain modularity**: Keep modules focused and reusable