# common.nix - Base System Configuration

**Location:** `modules/nixos/common.nix`

## Purpose

The common module provides the foundational system configuration shared across all host types. It establishes essential system services, packages, security settings, and provides a global system rebuild helper.

## Dependencies

- **Internal:** `./unfree-packages.nix` (automatically imported)
- **External:** nixpkgs packages, NixOS system options

## Configuration Options

### `common.timezone`
- **Type:** `string`
- **Default:** `"America/New_York"`
- **Description:** System timezone configuration

## Features

### Core System Configuration
- **Nix Settings:** Enables flakes, experimental features, and binary caching
- **Garbage Collection:** Automatic daily cleanup with 30-day retention
- **Boot Loader:** Limits systemd-boot generations to 7 most recent
- **Networking:** NetworkManager with optimized settings
- **Locale:** US English with comprehensive locale settings

### Essential System Packages
The module installs a curated set of essential utilities:

```nix
environment.systemPackages = with pkgs; [
  # Basic utilities
  wget curl git vim htop tree jq unzip zip
  
  # Security tools
  _1password-cli
  
  # System monitoring
  btop iotop iftop
  
  # Network tools
  nettools iputils dnsutils
  
  # File management
  rsync ncdu ripgrep fd
  
  # Process management
  procps psmisc
  
  # Custom rebuild helper
  rebuildn
];
```

### System Rebuild Helper (`rebuildn`)

A custom package that provides system-wide access to the NixOS rebuild functionality:

- **Location:** Available globally as `rebuildn` command and `rebuild` alias
- **Features:** 
  - Auto-detects NixOS configuration directory
  - Searches common locations (`/etc/nixos`, `~/nixos`, etc.)
  - Uses git repository root when available
  - Falls back gracefully to current directory
  - Passes through all arguments to `scripts/rebuild.sh`

**Usage:**
```bash
rebuildn           # Auto-detect and rebuild
rebuildn test      # Test configuration
rebuildn build     # Build only
rebuildn --help    # Show options
```

### Security Configuration

#### SSH Server
```nix
services.openssh = {
  enable = true;
  settings = {
    PermitRootLogin = "no";
    PasswordAuthentication = false;
    X11Forwarding = false;
    AllowTcpForwarding = false;
  };
};
```

#### System Hardening
- **AppArmor:** Application sandboxing enabled
- **Audit Daemon:** System event logging
- **Kernel Protection:** Image and module protection
- **Memory Protection:** Various memory safety features
- **Network Protection:** SMT disabled for security

### Container Support
- **Podman:** Rootless container runtime with Docker compatibility
- **OCI Containers:** Backend configured for Podman

### System Services

#### Journald Configuration
```nix
services.journald.extraConfig = ''
  SystemMaxUse=1G
  SystemKeepFree=2G
  RuntimeMaxUse=256M
  RuntimeKeepFree=512M
  MaxFileSec=1month
'';
```

#### Additional Services
- **Log Rotation:** Automatic log cleanup
- **Cron:** Scheduled task execution
- **FSTRIM:** SSD optimization
- **System Cleanup:** Daily temporary file removal

### Environment Configuration
- **Shell Aliases:** Common shortcuts (`ll`, `la`, `grep` with color)
- **Editor:** vim as default editor
- **Shell Completion:** Enabled for bash and zsh
- **Documentation:** Full man pages and info documents

## Usage Examples

### Basic Host Configuration
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/common.nix
  ];
  
  # Override default timezone
  common.timezone = "Europe/London";
}
```

### Custom Package Addition
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/common.nix
  ];
  
  # Add host-specific packages
  environment.systemPackages = with pkgs; [
    firefox
    thunderbird
  ];
}
```

## Customization

### Adding System Packages
Additional packages should be added at the host level or through specialized modules rather than modifying the common module:

```nix
# In host configuration
environment.systemPackages = with pkgs; [
  your-additional-package
];
```

### Overriding Services
Common services can be overridden in host configurations:

```nix
# Disable SSH on specific host
services.openssh.enable = lib.mkForce false;
```

### Custom Environment Variables
```nix
# Add custom environment variables
environment.variables = {
  CUSTOM_VAR = "value";
};
```

## Integration Notes

### With Other Modules
- **Unfree Packages:** Automatically includes unfree package allowlist
- **Desktop/Laptop/Server:** Provides base functionality extended by specialized modules
- **Development:** Core packages complement development-specific tools

### Host Types
- **Desktop:** Provides foundation for GUI applications and development tools
- **Laptop:** Base system with power management additions
- **Server:** Minimal secure foundation for server-specific hardening

## Troubleshooting

### Rebuild Script Issues
If `rebuildn` can't find your configuration:
1. Ensure you're in a git repository with `flake.nix`
2. Check that `scripts/rebuild.sh` exists and is executable
3. Verify common search paths contain your configuration

### Package Conflicts
If packages conflict with other modules:
1. Use `lib.mkForce` to override
2. Consider moving packages to specialized modules
3. Check unfree package allowlist in `unfree-packages.nix`

### Service Failures
For service startup issues:
1. Check journal logs: `journalctl -u service-name`
2. Verify dependencies are met
3. Test with `systemctl status service-name`

## Security Considerations

- **SSH Keys:** Configure SSH keys through the `users.nix` module
- **Firewall:** Additional firewall rules should be configured per host
- **Updates:** Automatic system updates are enabled but require manual intervention
- **Containers:** Podman runs rootless for security by default