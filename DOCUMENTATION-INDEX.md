# Documentation Index & Navigation Guide

This comprehensive index provides navigation across all documentation in the NixOS configuration repository. All files are organized hierarchically and cross-referenced for easy discovery.

## 🏠 Repository Root Documentation

### Core Documentation Files
- **[README.md](README.md)** - Main repository documentation with quick start and overview
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Comprehensive troubleshooting guide for common issues  
- **[AGENTS.md](AGENTS.md)** - AI agent instructions for repository-wide operations

### Configuration Files
- **[flake.nix](flake.nix)** - Central Nix flake configuration defining all inputs and outputs
- **[profiles/hardware/disko/zfs-impermanence.nix](profiles/hardware/disko/zfs-impermanence.nix)** - Parameterized Disko layout for LUKS-encrypted ZFS
- **[disko-layout-simple.nix](disko-layout-simple.nix)** - Simplified disk layout for basic installations

## 📚 Documentation Directory (`docs/`)

### System Architecture & Design
- **[architecture.md](docs/architecture.md)** - Comprehensive system architecture overview with Mermaid diagrams
- **[security.md](docs/security.md)** - Security architecture, hardening, and threat model
- **[performance.md](docs/performance.md)** - Performance optimizations and tuning guide
- **[troubleshooting.md](docs/troubleshooting.md)** - Detailed troubleshooting procedures

### Installation & Setup
- **[installation-scripts-analysis.md](docs/installation-scripts-analysis.md)** - Installation script workflow analysis with diagrams
- **[installation-scripts-functions.md](docs/installation-scripts-functions.md)** - Function reference for installation scripts
- **[zfs-impermanence-configuration.md](docs/zfs-impermanence-configuration.md)** - ZFS and impermanence setup guide

### Host Configuration Documentation (`docs/hosts/`)
- **[README.md](docs/hosts/README.md)** - Host configuration overview and common architecture
- **[desktop.md](docs/hosts/desktop.md)** - Desktop workstation configuration details
- **[laptop.md](docs/hosts/laptop.md)** - Laptop-specific configuration and optimizations  
- **[server.md](docs/hosts/server.md)** - Headless server configuration guide

### Module Documentation (`docs/modules/`)
- **[README.md](docs/modules/README.md)** - Module system overview with dependency diagrams

#### NixOS System Modules (`docs/modules/nixos/`)
- **[common.md](docs/modules/nixos/common.md)** - Base system configuration and rebuild helper
- **[boot.md](docs/modules/nixos/boot.md)** - Boot loader and kernel configuration
- **[users.md](docs/modules/nixos/users.md)** - User account and SSH key management
- **[impermanence.md](docs/modules/nixos/impermanence.md)** - Ephemeral root and persistence configuration
- **[development.md](docs/modules/nixos/development.md)** - Development tools and environments
- **[desktop.md](docs/modules/nixos/desktop.md)** - Desktop environment configuration
- **[laptop.md](docs/modules/nixos/laptop.md)** - Laptop power management and hardware
- **[server.md](docs/modules/nixos/server.md)** - Server hardening and monitoring
- **[nvidia-rog.md](docs/modules/nixos/nvidia-rog.md)** - NVIDIA and ASUS ROG hardware support
- **[unfree-packages.md](docs/modules/nixos/unfree-packages.md)** - Unfree package management

#### Home Manager Modules (`docs/modules/home-manager/`)
- **[README.md](docs/modules/home-manager/README.md)** - Home Manager module overview
- **[desktop.md](docs/modules/home-manager/desktop.md)** - User desktop environment with Hyprland
- **[opnix.md](docs/modules/home-manager/opnix.md)** - 1Password integration for secret management

## 🖥️ Host Configurations (`hosts/`)

Each host directory contains configuration files and documentation:

### Directory Structure
- **[README.md](hosts/README.md)** - Host system overview and shared configurations
- **[AGENTS.md](hosts/AGENTS.md)** - AI agent instructions for host configurations

### Host-Specific Directories
- **`hosts/desktop/`** - Desktop workstation configuration
  - **[AGENTS.md](hosts/desktop/AGENTS.md)** - Desktop-specific agent instructions
- **`hosts/laptop/`** - Laptop configuration with power management
  - **[AGENTS.md](hosts/laptop/AGENTS.md)** - Laptop-specific agent instructions  
- **`hosts/server/`** - Headless server configuration
  - **[AGENTS.md](hosts/server/AGENTS.md)** - Server-specific agent instructions

## 🧩 Module Source Code (`modules/`)

### Root Module Documentation
- **[AGENTS.md](modules/AGENTS.md)** - AI agent instructions for module development

### NixOS Modules (`modules/nixos/`)
- **[AGENTS.md](modules/nixos/AGENTS.md)** - NixOS module development guidelines
- **[BOOT-MODULE.md](modules/nixos/BOOT-MODULE.md)** - Boot module implementation details
- **[ZFS-IMPERMANENCE.md](modules/nixos/ZFS-IMPERMANENCE.md)** - ZFS impermanence implementation

### Home Manager Modules (`modules/home-manager/`)
- **[AGENTS.md](modules/home-manager/AGENTS.md)** - Home Manager module development guidelines

## 👤 User Configurations (`users/`)

### User Documentation
- **[AGENTS.md](users/AGENTS.md)** - User configuration agent instructions
- **`users/hbohlen/`** - Primary user configuration
  - **[AGENTS.md](users/hbohlen/AGENTS.md)** - User-specific agent instructions

## 🔧 Scripts & Automation (`scripts/`)

### Script Documentation
- **[AGENTS.md](scripts/AGENTS.md)** - Comprehensive script documentation with process flows

### Available Scripts
- **[bootstrap.sh](scripts/bootstrap.sh)** - One-line bootstrap installer
- **[install.sh](scripts/install.sh)** - Full installation script with error handling
- **[rebuild.sh](scripts/rebuild.sh)** - Enhanced NixOS rebuild script
- **[format.sh](scripts/format.sh)** - Code formatting and style enforcement

## 🔍 AI Agent Instructions

Agent instruction files provide context-specific guidance for AI coding assistants:

### Repository-Wide Instructions
- **[.github/copilot-instructions.md](.github/copilot-instructions.md)** - GitHub Copilot specific instructions
- **[AGENTS.md](AGENTS.md)** - Root-level agent instructions

### Nested Agent Instructions
All major directories contain `AGENTS.md` files with context-specific instructions for AI agents working in those areas.

## 📊 Diagrams & Visual Documentation

### Architecture Diagrams (Mermaid)
- **System Architecture** - Overall system relationships and data flow
- **Module Dependencies** - Module interaction and dependency graphs  
- **Installation Process** - Step-by-step installation workflow
- **Boot Process** - System boot and initialization sequence
- **ZFS Layout** - Filesystem structure and mounting hierarchy

### Diagram Locations
- **[docs/architecture.md](docs/architecture.md)** - 7 Mermaid diagrams covering system architecture
- **[docs/installation-scripts-analysis.md](docs/installation-scripts-analysis.md)** - 3 installation process diagrams
- **[docs/modules/README.md](docs/modules/README.md)** - Module dependency diagram
- **[scripts/AGENTS.md](scripts/AGENTS.md)** - Script process flow diagrams

## 🛠️ System Management

### Rebuild System
- **Primary Command**: `rebuildn` - Global system rebuild helper
- **Alias**: `rebuild` - User-friendly alias pointing to rebuildn
- **Script Location**: `scripts/rebuild.sh` - Core rebuild functionality
- **Documentation**: [docs/modules/nixos/common.md](docs/modules/nixos/common.md#system-rebuild-helper-rebuildn)

### Usage Examples
```bash
rebuildn           # Auto-detect hostname and switch
rebuildn test      # Test configuration without making it default
rebuildn build     # Build configuration but don't activate
rebuildn --help    # Show comprehensive help and options
```

## 🔗 External References

### Official Documentation
- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - Official NixOS documentation
- [Nix Flakes](https://nixos.wiki/wiki/Flakes) - Flakes documentation and examples
- [Home Manager](https://nix-community.github.io/home-manager/) - User environment management

### Third-Party Tools
- [Disko](https://github.com/nix-community/disko) - Declarative disk partitioning
- [Impermanence](https://github.com/nix-community/impermanence) - Ephemeral root filesystem
- [Hyprland](https://hyprland.org/) - Wayland compositor documentation
- [Opnix](https://github.com/brizzbuzz/opnix) - 1Password Nix integration

## 📈 Repository Statistics

- **Total Documentation Files**: 41 markdown files
- **Mermaid Diagrams**: 15+ diagrams across 7 files
- **Agent Instruction Files**: 12 AGENTS.md files
- **Host Configurations**: 3 (desktop, laptop, server)
- **System Modules**: 10 NixOS modules
- **Home Manager Modules**: 2 user environment modules
- **Scripts**: 4 automation scripts

---

**Maintainer**: Hayden Bohlen ([@hbohlen](https://github.com/hbohlen))  
**Last Updated**: December 2024  
**Repository**: [hbohlen/nixos](https://github.com/hbohlen/nixos)