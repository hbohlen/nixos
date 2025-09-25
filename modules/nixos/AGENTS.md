# System-Level NixOS Modules - Comprehensive Documentation

## Directory Purpose
This directory contains system-level NixOS modules that configure core system functionality, including boot processes, filesystems, hardware support, development environments, and user management. These modules form the foundation of the NixOS system configuration and are shared across different host types.

## Module Overview and Configuration Options

### Core System Modules

#### `common.nix` - Base System Configuration
**Purpose**: Shared system configurations used across all hosts including base packages, services, and system-wide settings.

**Key Configuration Areas**:
- **Timezone and Localization**: System timezone, locale settings, internationalization
- **Base Packages**: Essential system utilities, text editors, system monitoring tools
- **System Services**: SSH, NetworkManager, basic system daemons
- **User Environment**: Shell configuration, system-wide environment variables
- **Security**: Basic firewall rules, sudo configuration

**Configuration Options**:
- Network configuration and hostname settings
- System-wide package installations
- Service enablement and configuration
- Locale and timezone management

**Troubleshooting**:
- Check service status: `systemctl status <service>`
- Network issues: `nmcli connection show`
- Package conflicts: `nix-store --verify --check-contents`

#### `boot.nix` - Boot Configuration
**Purpose**: Configures the system boot process, boot loader, kernel parameters, and early-boot initialization.

**Key Features**:
- **systemd-boot**: EFI boot loader configuration with security settings
- **Kernel Management**: Module loading, parameter configuration
- **Initrd Configuration**: Early boot environment and hardware initialization
- **Filesystem Support**: Boot-time filesystem support (ZFS, ext4, etc.)

**Critical Settings**:
- `boot.loader.systemd-boot.editor = false` (security)
- `boot.loader.timeout = 5` (boot menu timeout)
- `boot.tmp.cleanOnBoot = true` (temporary file cleanup)

**Troubleshooting**:
- Boot failures: Check EFI entries with `efibootmgr -v`
- Kernel issues: Review `dmesg` output
- Module problems: Verify with `lsmod` and `modinfo`

#### `impermanence.nix` - Ephemeral Root Filesystem
**Purpose**: Implements ephemeral root filesystem configuration with selective persistence using the impermanence module.

**Architecture**:
- **Ephemeral Root**: `/` mounted on tmpfs, wiped on every boot
- **Persistent Storage**: `/persist` for files that must survive reboots
- **ZFS Integration**: Automated ZFS snapshot rollback to blank state
- **Selective Persistence**: Explicit opt-in for persistent files/directories

**Key Components**:
- ZFS rollback service in initrd
- Persistence directory definitions
- Home directory persistence mapping
- System configuration persistence

**Configuration Areas**:
```nix
environment.persistence."/persist" = {
  directories = [
    "/var/lib/nixos"
    "/var/lib/systemd/coredump"
    "/etc/NetworkManager/system-connections"
  ];
  files = [
    "/etc/machine-id"
    "/etc/ssh/ssh_host_ed25519_key"
  ];
};
```

**Troubleshooting**:
- Missing files after reboot: Check persistence configuration
- Boot issues: Verify ZFS rollback service
- Performance problems: Monitor tmpfs usage
- Recovery: Boot from ISO and restore from `/persist`

### Hardware and Environment Modules

#### `desktop.nix` - Desktop Environment Configuration
**Purpose**: Configures desktop environments including GNOME, Hyprland, fonts, and GUI applications.

**Features**:
- **Desktop Environments**: GNOME, Hyprland Wayland compositor
- **Display Management**: X11/Wayland session management
- **Font Configuration**: System fonts and font rendering
- **Audio**: PipeWire audio system configuration
- **Graphics**: Basic graphics driver support

**Configuration Options**:
```nix
desktop = {
  enable = true;
  environment = "hyprland"; # "gnome" | "hyprland" | "both"
};
```

**Troubleshooting**:
- Display issues: Check Wayland/X11 configuration
- Audio problems: Verify PipeWire services
- Font rendering: Check font cache and configuration

#### `laptop.nix` - Power Management and Optimization
**Purpose**: Laptop-specific power management, thermal controls, and portable device optimizations.

**Key Features**:
- **TLP Power Management**: Advanced battery and CPU power control
- **Thermal Management**: CPU frequency scaling and thermal throttling
- **Hardware Optimization**: WiFi power saving, USB autosuspend
- **Battery Optimization**: Charge thresholds and power profiles

**Configuration Areas**:
- Power profiles (AC vs battery)
- CPU governors and frequency scaling
- Device power management
- Thermal and fan control

**Troubleshooting**:
- Battery drain: Check TLP settings and power-consuming processes
- Thermal issues: Monitor CPU temperature and throttling
- Power management: Verify TLP service status and configuration

#### `server.nix` - Server Hardening and Security  
**Purpose**: Server-specific security hardening, SSH configuration, and minimal overhead settings.

**Security Features**:
- **SSH Hardening**: Key-based authentication, connection limits, security settings
- **Firewall Configuration**: Minimal open ports, strict rules
- **Service Management**: Minimal service set for reduced attack surface
- **Access Control**: User restrictions and privilege management

**Configuration**:
- SSH key-only authentication
- Connection rate limiting
- Logging and monitoring
- Security service defaults

**Troubleshooting**:
- Connection issues: Check SSH configuration and firewall
- Security alerts: Review logs and security service status
- Performance: Monitor resource usage and service overhead

### Development and Application Modules

#### `development.nix` - Development Tools and Environments
**Purpose**: Development tools, programming language support, and development environments (conditional by host type).

**Features**:
- **Core Tools**: GCC, Clang, Make, CMake, pkg-config
- **Version Control**: Git configuration and tools
- **Language Runtimes**: Node.js, Python, build tools
- **Development Services**: Docker, databases (when needed)

**Configuration**:
```nix
development = {
  enable = true; # Typically enabled for desktop/laptop
};
```

**Troubleshooting**:
- Build failures: Check compiler and library dependencies
- Package conflicts: Verify development package versions
- Performance: Monitor build system resource usage

#### `nvidia-rog.nix` - NVIDIA and ROG Hardware Support
**Purpose**: NVIDIA graphics drivers and Republic of Gamers hardware-specific configuration.

**Components**:
- **NVIDIA Drivers**: Proprietary driver configuration
- **Optimus Support**: Hybrid graphics management
- **ROG Hardware**: ASUS ROG-specific features and controls
- **Gaming Optimization**: Performance and compatibility settings

**Configuration**:
- Driver version management
- Hardware acceleration
- Multiple monitor support
- Gaming-specific optimizations

**Troubleshooting**:
- Graphics issues: Check driver installation and kernel modules
- Performance problems: Verify GPU frequency and power management
- Display problems: Check output configuration and monitor setup

### System Management Modules

#### `users.nix` - User Account Management
**Purpose**: User account management with SSH key support and role-based configuration.

**Features**:
- **User Accounts**: Declarative user management
- **SSH Key Management**: Automatic SSH key deployment
- **Group Management**: Role-based group assignments
- **Home Directory Setup**: Initial home directory configuration

**Configuration**:
- User definitions with SSH keys
- Group membership management
- Shell and environment setup
- Password and authentication settings

#### `unfree-packages.nix` - Proprietary Software Management
**Purpose**: Centralized management of proprietary software licenses and unfree packages.

**Features**:
- **License Management**: Allowlisting unfree packages
- **Software Categories**: Organized by use case
- **Security Review**: Documented unfree package usage
- **Compliance**: License compliance tracking

## Dependencies and Integration

### External Dependencies
- **Impermanence Module**: `inputs.impermanence.nixosModules.impermanence`
- **ZFS Support**: Kernel modules and ZFS utilities
- **Hardware Detection**: nixos-hardware profiles
- **Graphics Drivers**: NVIDIA proprietary drivers, Mesa
- **Desktop Environments**: GNOME, Hyprland, and their dependencies

### Module Interdependencies
- `impermanence.nix` requires ZFS configuration and boot integration
- `desktop.nix` may depend on graphics drivers from `nvidia-rog.nix`
- `development.nix` integrates with user configurations
- `common.nix` provides base for all other modules
- `users.nix` coordinates with Home Manager configurations

### Host Integration
- Desktop hosts: Enable desktop, development, nvidia-rog modules
- Laptop hosts: Enable laptop power management, desktop, development
- Server hosts: Enable server hardening, minimal desktop components
- All hosts: Use common, boot, impermanence, users modules

## Best Practices and Security

### Configuration Guidelines
- **Modular Design**: Keep modules focused on single responsibilities
- **Option Types**: Use proper `lib.mkOption` with types and descriptions
- **Conditional Logic**: Use `lib.mkIf` and `lib.mkDefault` appropriately
- **Documentation**: Document complex configurations and security implications
- **Testing**: Test modules across different host types

### Security Considerations
- **Principle of Least Privilege**: Enable only necessary services and features
- **Regular Updates**: Keep modules updated with security patches
- **Configuration Review**: Regular security audits of module configurations
- **Access Control**: Proper user and service permissions
- **Monitoring**: Log and monitor critical system components

### Performance Optimization
- **Service Management**: Disable unnecessary services
- **Resource Usage**: Monitor memory and CPU usage of modules
- **Boot Performance**: Optimize boot time through module configuration
- **Hardware Support**: Use appropriate hardware-specific optimizations

## Troubleshooting and Maintenance

### Common Issues and Solutions

#### Module Loading Problems
- **Symptom**: Module import errors or option conflicts
- **Diagnosis**: Check module imports and option definitions
- **Solution**: Verify module structure and resolve conflicts

#### Configuration Conflicts
- **Symptom**: Build failures due to conflicting options
- **Diagnosis**: Review option priorities and module interactions
- **Solution**: Use `lib.mkForce` or `lib.mkDefault` appropriately

#### Hardware Compatibility
- **Symptom**: Hardware not detected or not working properly
- **Diagnosis**: Check hardware-specific module configuration
- **Solution**: Update hardware modules or add missing drivers

#### Performance Issues
- **Symptom**: Slow boot times or high resource usage
- **Diagnosis**: Profile system startup and resource usage
- **Solution**: Optimize module configuration and service startup

### Maintenance Procedures

#### Regular Maintenance
1. **Update Dependencies**: `nix flake update` to update inputs
2. **Security Review**: Review unfree packages and security settings
3. **Performance Check**: Monitor system performance metrics
4. **Configuration Audit**: Review module configurations for improvements
5. **Backup Verification**: Ensure persistence and backup configurations work

#### Emergency Procedures
1. **Boot Recovery**: Boot from NixOS ISO for emergency access
2. **Configuration Rollback**: Use generation rollback for failed updates
3. **Module Disable**: Temporarily disable problematic modules
4. **System Rebuild**: Rebuild system from scratch if necessary

This comprehensive documentation should guide agents in understanding, modifying, and troubleshooting the system-level NixOS modules effectively.