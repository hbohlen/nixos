# NixOS Configuration

A modern, declarative NixOS system configuration built on the "Erase Your Darlings" philosophy, featuring ephemeral root filesystem with selective persistence, ZFS storage, and Hyprland desktop environment.

## 🎯 Overview

This repository provides a comprehensive NixOS configuration that combines several advanced technologies to create a robust, reproducible, and secure computing environment:

- **🔄 Ephemeral Root**: The root filesystem is reset to a pristine state on each boot
- **📁 Selective Persistence**: Only explicitly chosen files and directories survive reboots  
- **📋 Declarative Everything**: From disk partitioning to application themes, everything is defined as code
- **🖥️ Multi-Host Support**: Configurations for desktop, laptop, and server environments
- **🎨 Modern Desktop**: Hyprland Wayland compositor with integrated theming
- **🔐 Secret Management**: Runtime secret injection via 1Password integration

## 📋 System Requirements

### Minimum Requirements
- **Operating System**: NixOS 23.11 or later (configuration targets 25.05)
- **Architecture**: x86_64-Linux (Intel/AMD 64-bit)
- **Memory**: 8GB RAM minimum (for ZFS ARC cache and desktop environment)
- **Storage**: 50GB free space, NVMe SSD strongly recommended
- **Boot**: UEFI-compatible system (Legacy BIOS not supported)
- **Network**: Internet connection for initial setup and package downloads

### Hardware Compatibility

| Component | Supported | Notes |
|-----------|-----------|-------|
| **CPU** | Intel processors | AMD support possible with configuration changes |
| **GPU** | Nvidia graphics | Proprietary drivers configured |
| **Memory** | 8GB+ RAM | ZFS ARC cache requires adequate memory |
| **Storage** | NVMe/SSD | HDD works but not recommended for ZFS |
| **Boot** | UEFI only | Legacy BIOS not supported |

### Tested Hardware
- **Laptop**: ASUS ROG Zephyrus M16 GU603ZW (Intel/Nvidia hybrid graphics)
- **Desktop**: MSI motherboards with Intel CPU + Nvidia GPU combinations
- **General**: Modern systems with UEFI and good Linux hardware support

## 🚀 Quick Installation

### Method 1: One-Line Bootstrap (Recommended)

Boot from NixOS LiveISO and run:
```bash
sudo -i
curl -L https://raw.githubusercontent.com/hbohlen/nixos/main/scripts/bootstrap.sh | bash
```

### Method 2: Clone and Install
```bash
# Boot from NixOS LiveISO and run:
sudo -i
nix-shell -p git
cd /tmp
git clone https://github.com/hbohlen/nixos
cd nixos
./scripts/install.sh
```

Both methods will:
- 📝 Prompt for hostname, username, and target disk
- 💾 Handle Disko partitioning with ZFS+LUKS encryption
- 🔒 Set up impermanence with persistent directories  
- 📂 Mount all filesystems correctly
- ⚙️ Install NixOS with your configuration
- 🛡️ Provide comprehensive error handling and cleanup

⚠️ **Warning**: This will destroy all data on the target disk!

## 📁 Repository Structure

```
├── 📄 flake.nix              # Central configuration entry point
├── 🖥️ hosts/                 # Host-specific configurations
│   ├── desktop/              # High-performance desktop setup
│   ├── laptop/               # Portable laptop configuration
│   └── server/               # Headless server setup
├── 🧩 modules/               # Reusable configuration modules
│   ├── nixos/                # System-level modules
│   └── home-manager/         # User-level modules
├── 👤 users/                 # Per-user Home Manager configurations
├── 🔧 scripts/               # System management and automation tools
├── 📚 docs/                  # Architecture and setup documentation
└── 🔐 secrets/               # Placeholder for runtime secret injection
```

### Key Components

- **Nix Flakes**: Reproducible system definition with locked dependencies
- **Disko**: Declarative disk partitioning and filesystem setup
- **ZFS + LUKS**: Advanced filesystem features with full-disk encryption
- **Impermanence**: Ephemeral root with selective persistence
- **Hyprland**: Modern Wayland compositor for desktop environments
- **Home Manager**: Declarative user environment management
- **Opnix**: 1Password integration for secure secret management

## ⚙️ System Management

### Rebuild Commands

The system provides multiple convenient ways to rebuild your configuration:

#### Rebuild Alias (Global)
```bash
rebuild          # Build and switch (default mode)
rebuild test     # Build and test without making permanent  
rebuild build    # Build only, don't activate
rebuild --help   # Show all available options
```

This alias automatically finds your NixOS configuration directory and works from any location.

#### Rebuild Script (Local)
```bash
cd /path/to/nixos-config
./scripts/rebuild.sh          # Auto-detect hostname and switch
./scripts/rebuild.sh test     # Test configuration  
./scripts/rebuild.sh build    # Build only
```

#### Manual Commands
```bash
sudo nixos-rebuild switch --flake .#hostname    # Apply configuration
nixos-rebuild build --flake .#hostname         # Build without applying
nixos-rebuild test --flake .#hostname          # Test configuration
nixos-rebuild dry-activate --flake .#hostname  # Preview changes
nix flake check                                # Validate flake syntax
```

### Available Options

| Option | Description | Example |
|--------|-------------|---------|
| `switch` | Build and activate (default) | `rebuild switch` |
| `boot` | Build and set for next boot | `rebuild boot` |
| `test` | Build and activate temporarily | `rebuild test` |
| `build` | Build without activating | `rebuild build` |
| `dry-run` | Show what would be built | `rebuild dry-run` |
| `--flake-update` | Update flake inputs first | `rebuild --flake-update` |
| `--gc` | Run garbage collection after | `rebuild --gc` |

## 🔧 Customization Guide

### Adding a New Host

1. **Create host directory**:
   ```bash
   mkdir -p hosts/new-hostname/hardware
   ```

2. **Generate hardware configuration**:
   ```bash
   nixos-generate-config --dir hosts/new-hostname
   ```

3. **Create host configuration**:
   ```nix
   # hosts/new-hostname/default.nix
   { config, pkgs, lib, inputs, ... }:
   {
     imports = [
       ./hardware-configuration.nix
       ./hardware/disko-zfs.nix
       ../../modules/nixos/common.nix
       ../../modules/nixos/impermanence.nix
       # Add other modules as needed
     ];
     
     networking.hostName = "new-hostname";
     networking.hostId = "12345678"; # Unique 8-character hex
     
     # Set host type for module selection
     users.hostType = "desktop"; # or "laptop" or "server"
     
     # Add host-specific configuration here
     system.stateVersion = "25.05";
   }
   ```

4. **Add to flake.nix**:
   ```nix
   nixosConfigurations = {
     # ... existing hosts ...
     "new-hostname" = mkSystem {
       hostname = "new-hostname";
       username = "your-username";
     };
   };
   ```

### Hardware Configuration

Each host has hardware-specific configurations in the `hardware/` subdirectory:

- **`disko-layout.nix`**: Host-specific disk partitioning and ZFS layout  
- **`disko-zfs.nix`**: Disko module integration

**Important**: Update the device path in each host's `hardware/disko-layout.nix`:
```nix
{ device ? "/dev/disk/by-id/your-actual-disk-id", ... }:
```

Find your device ID:
```bash
lsblk -f
ls -la /dev/disk/by-id/
```

### Adding New Modules

1. **System modules** → `modules/nixos/`
2. **User modules** → `modules/home-manager/`  
3. **Follow existing patterns** for options and configuration structure
4. **Import modules** in appropriate host or user configurations

Example module structure:
```nix
# modules/nixos/my-module.nix
{ config, pkgs, lib, ... }:

with lib;

{
  options.myModule = {
    enable = mkEnableOption "my custom module";
    
    package = mkOption {
      type = types.package;
      default = pkgs.my-package;
      description = "Package to use for my module";
    };
  };

  config = mkIf config.myModule.enable {
    # Your configuration here
  };
}
```

### Persistence Configuration

Edit `modules/nixos/impermanence.nix` to add files or directories that should survive reboots:

```nix
environment.persistence."/persist" = {
  directories = [
    "/var/lib/your-service"        # System service data
    "/etc/your-app"                # System configuration
  ];
  files = [
    "/etc/your-config-file"        # Individual config files
  ];
  users.username = {
    directories = [
      ".config/your-app"           # User application configs
      ".local/share/your-app"      # User application data
    ];
    files = [
      ".ssh/known_hosts"           # SSH known hosts
    ];
  };
};
```

## 📝 Manual Installation (Advanced)

For manual installation or troubleshooting, follow these detailed steps:

### Prerequisites
- NixOS LiveISO (latest stable version)  
- Internet connection
- Target system meeting system requirements
- UEFI-compatible system (not Legacy BIOS)

### Installation Steps

#### 1. Boot from LiveISO
Boot the target system from the NixOS LiveISO and reach the command line.

#### 2. Setup Network and Tools
```bash
# Connect to internet (if needed)
sudo systemctl start wpa_supplicant
# OR for ethernet: sudo dhcpcd

# Install git for cloning the repository  
nix-shell -p git

# Enable experimental features for flakes
export NIX_CONFIG="experimental-features = nix-command flakes"
```

#### 3. Identify Target Disk
```bash
# List available disks - use by-id paths for stability
ls -l /dev/disk/by-id/

# Set your target disk (replace with your actual disk ID)
export DISK=/dev/disk/by-id/nvme-YOUR_DISK_ID
```

#### 4. Clone Configuration Repository
```bash
git clone https://github.com/hbohlen/nixos.git /tmp/nixos-config
cd /tmp/nixos-config
```

#### 5. Partition and Setup ZFS with Disko
```bash
# IMPORTANT: This will DESTROY all data on the target disk
sudo nix run --extra-experimental-features 'nix-command flakes' \
  github:nix-community/disko -- --mode disko \
  --argstr device "$DISK" \
  ./hosts/desktop/hardware/disko-layout.nix
```

#### 6. Verify ZFS Setup
```bash
# Verify the ZFS pool was created correctly
zpool status rpool
zfs list

# Check that filesystems are mounted
findmnt -t zfs
```

#### 7. Copy Configuration and Install
```bash
# Copy configuration to target system
sudo cp -r /tmp/nixos-config/* /mnt/etc/nixos/
sudo chown -R root:root /mnt/etc/nixos

# Generate hardware configuration
sudo nixos-generate-config --root /mnt --dir /tmp/hardware

# Install the system (choose your hostname)
sudo nixos-install --flake .#desktop

# Set root password when prompted, then reboot
sudo reboot
```

## 🔍 Troubleshooting

### Common Issues

#### Boot Failures
**Symptoms**: System fails to boot or drops to emergency shell
**Solutions**:
- Boot from an older generation in the boot menu
- Check `/var/log/boot.log` for specific errors
- Use `journalctl -b` to examine boot logs

**Prevention**: Always test with `nixos-rebuild build` before `switch`

#### ZFS Import Failures  
**Symptoms**: `failed to import pool 'rpool'`
**Solutions**:
```bash
# Check disk connections and pool status
zpool status
zpool import -f rpool

# If pool is degraded, check disk health
```
**Prevention**: Use stable `/dev/disk/by-id/` paths instead of `/dev/sdX`

#### SSH Service Failures
**Symptoms**: SSH host keys missing or service won't start
**Solutions**:
- Ensure SSH host keys are in persistence configuration
- Check `/etc/ssh/ssh_host_*` files are persisted in `impermanence.nix`
```bash
# Regenerate SSH host keys if needed
sudo ssh-keygen -A
```

#### Home Manager Build Failures
**Symptoms**: Package conflicts or `buildEnv error`
**Solutions**:
- Check for duplicate package definitions between system and user configs
- Use `programs.package.enable = true` instead of adding to `home.packages`
- For Node.js conflicts, centralize to system development module

#### Package Not Found Errors
**Symptoms**: `attribute 'package' does not exist`
**Solutions**:
- Check package name in [NixOS Search](https://search.nixos.org/)
- Use `nix search nixpkgs package-name` to find correct attribute path

#### Installation: ESP Mount Issues
**Symptom**: `efiSysMountPoint = '/boot' is not a mounted partition`

**Solutions**:
1. Re-run Disko to ensure partitions are created and mounted:
   ```bash
   sudo nix run --extra-experimental-features 'nix-command flakes' \
     github:nix-community/disko -- --mode disko \
     --argstr device "$DISK" ./hosts/desktop/hardware/disko-layout.nix
   ```

2. If already partitioned, just mount everything:
   ```bash
   sudo nix run --extra-experimental-features 'nix-command flakes' \
     github:nix-community/disko -- --mode mount \
     --argstr device "$DISK" ./hosts/desktop/hardware/disko-layout.nix
   ```

3. If `/mnt/boot` is still missing, mount ESP manually:
   ```bash
   sudo mkdir -p /mnt/boot
   sudo mount -o umask=0077 /dev/disk/by-partlabel/disk-main-ESP /mnt/boot
   ```

### Debug Commands

```bash
# Check configuration syntax
nix flake check

# Build without switching
nixos-rebuild build --flake .#hostname

# Show what would change  
nixos-rebuild dry-activate --flake .#hostname

# Check system status
systemctl status
journalctl -f

# ZFS status
zpool status
zfs list

# Check persistent data
ls -la /persist
```

## 🛠️ Development & Contributing

### Code Formatting

The repository includes multiple formatting options:

```bash
# Format all files using Prettier (recommended)
npm run fmt

# Check formatting without changes
npm run fmt:check

# Smart format script (auto-detects best formatter)
./scripts/format.sh

# Use flake's default formatter
nix fmt
```

### Testing Changes

1. **Syntax validation**:
   ```bash
   nix flake check
   ```

2. **Build test**:
   ```bash
   nixos-rebuild build --flake .#hostname
   ```

3. **Dry run**:
   ```bash
   nixos-rebuild dry-activate --flake .#hostname
   ```

4. **Test on appropriate hardware** - Don't test GPU configurations without GPU hardware

### Code Style Guidelines

- **Nix files**: 2-space indentation, trailing commas, descriptive comments
- **Module structure**: Use standard `{ config, pkgs, lib, inputs, ... }:` signature  
- **Naming conventions**:
  - Files: kebab-case (`my-module.nix`)
  - Options: camelCase (`myModule.enable`)
  - Variables: snake_case (`my_variable`)
- **Imports**: Use relative paths, group by type
- **Security**: Never commit secrets, use runtime injection instead

### Pull Request Process

1. **Fork** the repository
2. **Create** a feature branch from `main`
3. **Follow** the code style guidelines above
4. **Test** your changes thoroughly:
   - `nix flake check` for syntax
   - `nixos-rebuild build` for functionality
   - Test on appropriate hardware
5. **Update** documentation for any new features
6. **Submit** pull request with clear description of changes

### Reporting Issues

When reporting issues, please include:

- **Host configuration** affected (desktop/laptop/server)
- **Steps to reproduce** the problem
- **Error messages** or logs
- **System information** (`nixos-version`, hardware details)
- **Context**: Fresh install vs. after changes

### Development Environment

Get a development shell with Nix tooling:

```bash
nix develop
# or
nix-shell

# Available tools:
# - nixfmt-rfc-style: Official Nix formatter
# - alejandra: Alternative Nix formatter  
# - nil: Nix Language Server
# - statix: Nix linter
# - deadnix: Dead code detection
```

## 📚 Architecture

For detailed information about the system architecture, see:
- [`docs/architecture.md`](docs/architecture.md) - Complete system architecture overview
- [`docs/zfs-impermanence-configuration.md`](docs/zfs-impermanence-configuration.md) - ZFS and impermanence details
- [`docs/installation-scripts-functions.md`](docs/installation-scripts-functions.md) - Installation script documentation

### Key Architectural Decisions

- **Flake-based configuration** for reproducible builds
- **Ephemeral root** with ZFS snapshots for clean state
- **Modular design** for reusability across host types  
- **Declarative disk management** via Disko
- **Runtime secret injection** for security

## 🔗 References

- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - Official NixOS documentation
- [Nix Flakes](https://nixos.wiki/wiki/Flakes) - Flakes documentation and examples  
- [Disko](https://github.com/nix-community/disko) - Declarative disk partitioning
- [Impermanence](https://github.com/nix-community/impermanence) - Ephemeral root filesystem
- [Hyprland](https://hyprland.org/) - Wayland compositor documentation
- [Home Manager](https://nix-community.github.io/home-manager/) - User environment management
- [Opnix](https://github.com/brizzbuzz/opnix) - 1Password Nix integration
- [NixOS Hardware](https://github.com/NixOS/nixos-hardware) - Hardware-specific configurations

---

**Maintainer**: Hayden Bohlen ([@hbohlen](https://github.com/hbohlen))  
**License**: See repository license  
**NixOS Version**: 25.05 (unstable channel)