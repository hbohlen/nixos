# ByteRover MCP Context Initialization
# Repository: hbohlen/nixos - NixOS Configuration System

This document serves as the initial knowledge base for the ByteRover MCP server, providing comprehensive context about the repository structure, workflows, and development patterns.

## Project Architecture

### Core Philosophy
- **"Erase Your Darlings"**: Ephemeral root filesystem reset on every boot
- **Declarative Everything**: From disk partitioning to application themes, everything as code  
- **Modular Design**: Reusable components organized by functionality and host type
- **Selective Persistence**: Only explicitly chosen files/directories survive reboots via `/persist`
- **Security First**: Runtime secrets via 1Password, encrypted storage, no secrets in git

### Technology Stack
- **Nix Flakes**: Reproducible system configurations with pinned dependencies
- **Disko**: Declarative disk partitioning and ZFS filesystem setup  
- **ZFS with LUKS**: Encrypted, snapshot-capable filesystems with data integrity
- **Impermanence**: Ephemeral root filesystem for enhanced security
- **Home Manager**: Declarative user environment and application management
- **Hyprland**: Modern Wayland compositor for desktop environments
- **Opnix/1Password**: Runtime secret management (never commit secrets)

### Directory Structure
```
/
├── flake.nix                    # Entry point: inputs, outputs, system configs
├── hosts/                       # Host-specific configurations  
│   ├── desktop/                 # Desktop workstation config (Intel/Nvidia)
│   │   ├── default.nix          # Main host configuration
│   │   ├── hardware-configuration.nix # Auto-generated hardware config
│   │   └── hardware/disko-zfs.nix # ZFS disk layout
│   ├── laptop/                  # Laptop/mobile config (ASUS ROG tested)
│   │   ├── default.nix
│   │   ├── hardware-configuration.nix  
│   │   └── hardware/disko-zfs.nix
│   └── server/                  # Server/headless config
│       ├── default.nix
│       ├── hardware-configuration.nix
│       └── hardware/disko-layout.nix
├── modules/
│   ├── nixos/                   # System-level modules
│   │   ├── common.nix           # Base system configuration
│   │   ├── users.nix            # User management and SSH
│   │   ├── boot.nix             # Boot configuration and systemd
│   │   ├── desktop.nix          # Desktop environment (Hyprland)
│   │   ├── laptop.nix           # Laptop-specific settings
│   │   ├── development.nix      # Development tools and environments
│   │   ├── impermanence.nix     # Ephemeral root filesystem
│   │   └── nvidia-rog.nix       # Nvidia graphics for ROG devices
│   └── home-manager/            # User-level modules
│       ├── desktop.nix          # Desktop applications and theming
│       ├── development.nix      # User development environment  
│       └── opnix.nix            # 1Password secret management
├── users/
│   └── hbohlen/                 # User-specific configurations
│       └── home.nix             # Home Manager entry point
└── scripts/
    ├── rebuild.sh               # Enhanced rebuild script (primary tool)
    ├── bootstrap.sh             # One-line installation script
    └── format.sh                # Code formatting utilities
```

## Build and Development Workflows

### Primary Build Commands
- **Preferred Method**: `./scripts/rebuild.sh` (auto-detects hostname)
  - Supports: switch, boot, test, build, dry-run modes
  - Automatic hostname detection with manual override
  - Comprehensive error handling and validation
  - Garbage collection and cleanup options
  
- **Manual Method**: `sudo nixos-rebuild switch --flake .#hostname`
- **Test Builds**: `nixos-rebuild build --flake .#hostname` (safe testing)
- **Preview Changes**: `nixos-rebuild dry-activate --flake .#hostname`

### Development Cycle Best Practices
1. **Validation**: `nix flake check` (validate syntax and dependencies)
2. **Format Code**: `./scripts/format.sh` or `npm run fmt`
3. **Test Build**: `nixos-rebuild build` before switching (never skip this)
4. **Deploy**: `./scripts/rebuild.sh switch`  
5. **Rollback**: `nixos-rebuild switch --rollback` if issues occur

### Installation Methods
- **Bootstrap (Recommended)**: 
  ```bash
  curl -L https://raw.githubusercontent.com/hbohlen/nixos/main/scripts/bootstrap.sh | bash
  ```
- **Manual Installation**: Boot NixOS ISO → Run disko → nixos-install with flake

## Configuration Patterns and Standards

### Nix Conventions
- **Module Signature**: `{ config, pkgs, lib, inputs, ... }:` (always include `...`)
- **Import Style**: Use relative imports (e.g., `../../modules/`)
- **Naming**: kebab-case files, camelCase options, snake_case string vars
- **Formatting**: 2-space indentation, trailing commas, <100 char lines
- **Conditionals**: Use `lib.mkDefault` for overrides, `lib.mkIf` for conditionals
- **Options**: Use `lib.mkOption` with proper types for custom options

### Security Practices  
- **SSH Keys Only**: No password authentication (initialPassword for setup only)
- **Secret Management**: Use Opnix/1Password, never commit secrets to repo
- **Disk Encryption**: Full LUKS encryption on all persistent storage
- **Ephemeral Root**: System state reset on every boot via impermanence

### Module Organization
- **System Modules** (`modules/nixos/`): Core system functionality
- **User Modules** (`modules/home-manager/`): Desktop apps and user environment
- **Host Configs** (`hosts/`): Hardware-specific and role-specific settings
- **User Configs** (`users/`): Personal preferences and home directory

## Host-Specific Configurations

### Desktop Workstation
- **Target Hardware**: Intel CPU + Nvidia GPU combinations  
- **Use Cases**: Development, content creation, gaming
- **Key Features**: High-performance settings, full desktop environment
- **Network**: Ethernet preferred, WiFi available with performance optimization

### Laptop Configuration  
- **Target Hardware**: ASUS ROG Zephyrus M16 GU603ZW (tested)
- **Use Cases**: Mobile development, travel computing
- **Key Features**: Power management, hybrid graphics, WiFi optimization
- **Network**: WiFi-first with NetworkManager, power saving disabled for connectivity

### Server Configuration
- **Target Hardware**: Standard server hardware, Intel preferred
- **Use Cases**: Headless services, containers, network services
- **Key Features**: Minimal desktop, optimized for services and automation
- **Network**: Static IP preferred, remote management capabilities

## Filesystem and Storage

### ZFS Configuration
- **Pool Name**: `rpool` (standard across all hosts)
- **Datasets**: Separate datasets for root, home, persist, nix
- **Snapshots**: Automatic snapshots via `@blank` for rollback
- **Compression**: lz4 compression enabled for space efficiency

### Impermanence Setup
- **Root Mount**: tmpfs (ephemeral, wiped on boot)
- **Persistent Storage**: `/persist` (survives reboots)
- **Bind Mounts**: Automatic binding of persistent directories to ephemeral locations
- **Rollback**: Emergency rollback via ZFS snapshot restoration

### Persistence Patterns
- **System Files**: SSH host keys, machine-id, logs
- **User Data**: Home directories, application data, development projects  
- **Application State**: Browser profiles, IDE settings, development caches
- **Service Data**: Databases, service configurations, generated certificates

## Development Environment

### Supported Languages and Tools
- **Nix/NixOS**: Primary configuration language with full LSP support
- **Shell Scripting**: Bash with comprehensive error handling
- **Development**: Full development stack via `development.nix` module
- **Editors**: VS Code, Neovim with Nix language support

### Package Management Strategy
- **Channel**: nixos-unstable (bleeding edge with good stability)
- **Validation**: Always verify packages exist via `nixos_search` before use
- **Overrides**: Use overlays for customizations, avoid direct package modifications
- **Dependencies**: Pin flake inputs for reproducibility

## Troubleshooting and Recovery

### Common Issues
- **Build Failures**: Check `nix flake check` for syntax errors
- **Boot Problems**: Use ZFS snapshots for system rollback
- **Network Issues**: Verify NetworkManager vs wpa_supplicant conflicts
- **GPU Problems**: Check nvidia-rog module and driver compatibility

### Emergency Recovery
- **Boot Recovery**: Boot from NixOS ISO, import ZFS pool, chroot and rebuild
- **Configuration Rollback**: `nixos-rebuild switch --rollback`  
- **Data Recovery**: ZFS snapshots provide point-in-time recovery
- **Network Recovery**: Emergency network configuration via `ip` commands

## Integration Notes

### External Dependencies
- **Flake Inputs**: All external dependencies declared in `flake.nix`
- **Hardware Profiles**: nixos-hardware flake for device-specific optimizations
- **Desktop Environment**: Hyprland flake for cutting-edge Wayland compositor
- **Secret Management**: Opnix flake for 1Password CLI integration

### Module Dependencies  
- **Impermanence**: Requires ZFS pool structure via disko
- **Desktop**: Requires common.nix base configuration
- **Development**: Optional, enabled per-host as needed
- **Hardware**: GPU modules depend on specific hardware detection

This context provides the foundation for understanding and working with the hbohlen/nixos repository. All changes should maintain these patterns and architectural decisions for consistency and reliability.