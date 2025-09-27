# ByteRover MCP Knowledge Base Index
# Repository: hbohlen/nixos - NixOS Configuration System

This document serves as the master index for the ByteRover MCP knowledge base, providing quick access to all context and decision history for the repository.

## Knowledge Base Structure

### Core Context Files
- **[byterover-context.md](./byterover-context.md)**: Complete repository architecture and technology stack
- **[module-patterns.md](./module-patterns.md)**: Module relationships, patterns, and conventions
- **[development-workflows.md](./development-workflows.md)**: Practical workflows and troubleshooting guides
- **[copilot-instructions.md](./copilot-instructions.md)**: GitHub Copilot integration and MCP server guidelines

## Quick Reference

### Repository Identity
- **Name**: hbohlen/nixos
- **Purpose**: Modern, declarative NixOS system configuration
- **Philosophy**: "Erase Your Darlings" - ephemeral root with selective persistence
- **Primary User**: hbohlen
- **Target Systems**: Desktop, Laptop, Server configurations

### Key Technologies
- **Nix Flakes**: Reproducible configurations with pinned dependencies
- **ZFS + LUKS**: Encrypted storage with snapshots and rollback
- **Impermanence**: Ephemeral root filesystem reset on every boot  
- **Home Manager**: Declarative user environment management
- **Hyprland**: Modern Wayland compositor for desktop
- **Opnix/1Password**: Runtime secret management (no secrets in git)

### Host Configurations
1. **Desktop** (`hosts/desktop/`)
   - Target: Intel CPU + Nvidia GPU workstations
   - Use Case: Development, content creation, gaming
   - Network: Ethernet preferred, WiFi performance optimized

2. **Laptop** (`hosts/laptop/`)  
   - Target: ASUS ROG Zephyrus M16 GU603ZW (tested)
   - Use Case: Mobile development and travel computing
   - Network: WiFi-first with power management

3. **Server** (`hosts/server/`)
   - Target: Standard server hardware, headless operation
   - Use Case: Services, containers, network infrastructure
   - Network: Static IP, remote management capabilities

### Module Organization
```
modules/
├── nixos/           # System-level configuration
│   ├── common.nix   # Base system (always imported)
│   ├── users.nix    # User management and SSH (always)
│   ├── boot.nix     # Boot configuration (always)
│   ├── impermanence.nix # Ephemeral root (always)
│   ├── desktop.nix  # Desktop environment (conditional)
│   ├── laptop.nix   # Laptop optimizations (conditional)
│   ├── development.nix # Dev tools (conditional)
│   └── nvidia-rog.nix  # GPU drivers (hardware-specific)
└── home-manager/    # User environment configuration
    ├── desktop.nix  # Desktop apps and theming
    ├── development.nix # User dev environment
    └── opnix.nix    # 1Password secret management
```

## Decision History and Patterns

### Architecture Decisions
- **Ephemeral Root**: Chosen for security and system cleanliness
- **ZFS Storage**: Selected for snapshots, compression, and data integrity
- **Flake-based**: Ensures reproducible builds and dependency management
- **Modular Design**: Enables reuse across different host types
- **Secret Management**: Runtime injection via 1Password prevents secret leakage

### Development Patterns
- **Build Process**: Always test with `nixos-rebuild build` before switching
- **Module Structure**: Standard signature `{ config, pkgs, lib, inputs, ... }:`
- **Naming Conventions**: kebab-case files, camelCase options, snake_case vars
- **Error Handling**: Use `lib.mkIf`, `lib.mkDefault`, assertions for safety
- **Code Style**: 2-space indentation, trailing commas, <100 character lines

### Security Patterns
- **SSH Keys Only**: No password authentication (except initial setup)
- **Encrypted Storage**: LUKS encryption on all persistent storage
- **Secret Management**: Opnix/1Password integration, never commit secrets
- **Network Security**: Firewall enabled, minimal exposed services
- **System Hardening**: Regular updates, minimal attack surface

## Common Tasks and Solutions

### Quick Operations
```bash
# Standard rebuild (auto-detects hostname)  
./scripts/rebuild.sh

# Test build without activation
nixos-rebuild build --flake .#hostname

# Preview changes
nixos-rebuild dry-activate --flake .#hostname  

# Validate configuration
nix flake check

# Emergency rollback
nixos-rebuild switch --rollback
```

### Troubleshooting Checklist
1. **Build Failures**: Check `nix flake check` for syntax errors
2. **Boot Issues**: Use previous generation or ZFS snapshots  
3. **Network Problems**: Verify NetworkManager vs wpa_supplicant conflicts
4. **GPU Issues**: Check nvidia-rog module and driver compatibility
5. **Persistence Issues**: Verify `/persist` mounts and impermanence config

### Adding New Functionality  
1. **New Host**: Copy existing host → update hostname/hostId → add to flake.nix
2. **New Module**: Create with standard template → import in appropriate location
3. **New Package**: Search with `nix search` → add to appropriate module
4. **New Service**: Configure via NixOS options → add to relevant module

## Integration Points

### External Dependencies (flake.nix inputs)
- **nixpkgs**: Package repository (nixos-unstable channel)
- **home-manager**: User environment management
- **disko**: Declarative disk partitioning
- **impermanence**: Ephemeral root filesystem support  
- **hyprland**: Wayland compositor
- **opnix**: 1Password CLI integration
- **nixos-hardware**: Hardware-specific optimizations

### Hardware Support
- **CPU**: Intel processors (primary), AMD possible with changes
- **GPU**: Nvidia graphics with proprietary drivers
- **Storage**: NVMe/SSD preferred, ZFS compatibility required
- **Boot**: UEFI only (no Legacy BIOS support)
- **Network**: WiFi and Ethernet, NetworkManager preferred

### Service Integration
- **SSH**: Host keys persisted, user keys via 1Password
- **Network**: NetworkManager for WiFi, systemd-networkd for servers
- **Graphics**: Hyprland Wayland compositor with Nvidia support
- **Development**: Full dev stack optional via development.nix module

## Maintenance Procedures

### Regular Maintenance
- **Weekly**: `nix flake update` to get latest packages
- **Monthly**: Clean old generations with `nix-collect-garbage -d`
- **Quarterly**: Review and update pinned flake inputs
- **As Needed**: ZFS snapshots before major changes

### Emergency Procedures
- **Boot Failure**: Select previous generation from boot menu
- **Config Corruption**: Rollback via `nixos-rebuild switch --rollback`
- **Data Loss**: Restore from ZFS snapshots (`zfs rollback`)
- **System Corruption**: Boot NixOS ISO, import pools, chroot and rebuild

This index provides the complete context needed for the ByteRover MCP to maintain memory and consistency across development sessions in the hbohlen/nixos repository.