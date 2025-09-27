# Module Patterns and Relationships
# Context for ByteRover MCP - hbohlen/nixos

This document captures the specific patterns, relationships, and conventions used across the NixOS configuration modules.

## Module Dependency Graph

### Core System Dependencies
```
flake.nix (entry point)
├── hosts/{hostname}/default.nix
│   ├── hardware-configuration.nix (auto-generated)
│   ├── hardware/disko-zfs.nix (disk layout)
│   └── imports:
│       ├── ../../modules/nixos/common.nix (base system)
│       ├── ../../modules/nixos/users.nix (user management)
│       ├── ../../modules/nixos/boot.nix (boot configuration)
│       ├── ../../modules/nixos/desktop.nix (optional: desktop hosts)
│       ├── ../../modules/nixos/laptop.nix (optional: laptop hosts)
│       ├── ../../modules/nixos/development.nix (optional: dev hosts)
│       ├── ../../modules/nixos/impermanence.nix (ephemeral root)
│       └── ../../modules/nixos/nvidia-rog.nix (optional: ROG devices)
└── home-manager integration:
    └── users/{username}/home.nix
        └── imports from modules/home-manager/
```

### Module Activation Patterns
- **common.nix**: Always imported (base system configuration)
- **users.nix**: Always imported (user management and SSH)  
- **boot.nix**: Always imported (bootloader and kernel)
- **impermanence.nix**: Always imported (ephemeral root filesystem)
- **desktop.nix**: Conditionally imported (desktop hosts only)
- **laptop.nix**: Conditionally imported (laptop hosts only)
- **development.nix**: Conditionally imported (development workstations)
- **nvidia-rog.nix**: Hardware-specific (ROG devices with Nvidia)

## Configuration Options and Patterns

### Option Definition Patterns
```nix
# Standard module structure
{ config, pkgs, lib, inputs, ... }:

{
  # Options definition (for reusable modules)
  options.moduleName = {
    enable = lib.mkEnableOption "module description";
    option = lib.mkOption {
      type = lib.types.str;
      default = "defaultValue";
      description = "Option description";
    };
  };

  # Configuration implementation
  config = lib.mkIf config.moduleName.enable {
    # Module configuration
  };
}
```

### Conditional Configuration
```nix
# Use mkIf for conditional blocks
config = lib.mkIf config.desktop.enable {
  services.xserver.enable = true;
  # ...
};

# Use mkDefault for overridable defaults
networking.useDHCP = lib.mkDefault true;

# Use mkForce for hard overrides (rare, document why)
wifi.powerSaving = lib.mkForce "off";  # Performance override
```

### Host Type Patterns
```nix
# In host configuration (hosts/{hostname}/default.nix)
users.hostType = "desktop"; # or "laptop" or "server"

# Module behavior based on host type
config = lib.mkIf (config.users.hostType == "laptop") {
  # Laptop-specific configuration
  powerManagement.enable = true;
  services.tlp.enable = true;
};
```

## Persistence Patterns

### System Persistence (impermanence.nix)
```nix
# System files that must persist
environment.persistence."/persist".directories = [
  "/var/log"                    # System logs
  "/var/lib/systemd/coredump"   # Core dumps
  "/etc/NetworkManager"         # Network configurations
];

environment.persistence."/persist".files = [
  "/etc/machine-id"             # System identity
  "/etc/ssh/ssh_host_ed25519_key"       # SSH host keys
  "/etc/ssh/ssh_host_ed25519_key.pub"   # SSH host keys
];
```

### User Persistence (per-user home.nix)  
```nix
# User data that survives reboots
home.persistence."/persist/home/${username}" = {
  directories = [
    "Documents"
    "Downloads"  
    "Pictures"
    "Videos"
    ".ssh"                      # SSH keys and config
    ".config/git"               # Git configuration
    # Application data
    ".mozilla/firefox"
    ".vscode"
  ];
  
  files = [
    ".gitconfig"
    ".bashrc"
  ];
};
```

## Secret Management Patterns

### Opnix Integration (modules/home-manager/opnix.nix)
```nix
# 1Password CLI integration
programs.op = {
  enable = true;
  package = pkgs._1password;
};

# SSH agent integration  
programs.ssh.extraConfig = ''
  Host *
    IdentityAgent ~/.1password/agent.sock
'';

# Environment variable injection
home.sessionVariables = {
  SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";
};
```

### Secret Usage Pattern
```bash
# Runtime secret access (never in nix files)
export API_KEY=$(op item get "api-key-item" --field credential)
export DB_PASSWORD=$(op item get "database" --field password)
```

## Network Configuration Patterns

### WiFi Management
```nix
# Common pattern across hosts  
wifi = {
  enable = true;
  powerSaving = lib.mkDefault "medium";  # Override per host type
  enableFirmware = true;
  enableProprietaryFirmware = lib.mkDefault false;
};

# Laptop optimization (override in laptop hosts)
wifi.powerSaving = lib.mkForce "low";  # Better connectivity

# Desktop optimization (override in desktop hosts)  
wifi.powerSaving = lib.mkForce "off";  # Best performance
```

### NetworkManager vs wpa_supplicant
```nix
# CRITICAL: Prevent conflicts (in laptop/desktop configs)
networking.wireless.enable = false;        # Disable wpa_supplicant
systemd.services.wpa_supplicant.enable = false;  # Force disable
# NetworkManager handles WiFi instead
```

## Hardware Integration Patterns

### GPU Configuration (nvidia-rog.nix)
```nix
# Conditional GPU setup
config = lib.mkIf config.nvidia.enable {
  # Nvidia driver configuration
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;  # Conflicts with TLP
    open = false;                    # Use proprietary driver
    nvidiaSettings = true;
  };
  
  # Hybrid graphics for laptops
  hardware.nvidia.prime = lib.mkIf (config.users.hostType == "laptop") {
    sync.enable = true;
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };
};
```

### Hardware Detection Patterns
```nix
# Use nixos-hardware profiles
imports = [
  inputs.nixos-hardware.nixosModules.asus-zephyrus-gu603h  # Laptop
  inputs.nixos-hardware.nixosModules.common-cpu-intel     # Desktop
  inputs.nixos-hardware.nixosModules.common-pc-ssd        # Desktop
];
```

## Development Environment Patterns

### Language Environment Setup (development.nix)
```nix
config = lib.mkIf config.development.enable {
  environment.systemPackages = with pkgs; [
    # Core development tools
    git
    nixpkgs-fmt
    nil                         # Nix LSP
    
    # Language runtimes (via overlay when needed)
    nodejs
    python3
    rustc
    cargo
  ];
  
  # Development services
  services.postgresql.enable = true;
  virtualisation.docker.enable = true;
};
```

### Editor Integration
```nix
# VS Code with Nix support (home-manager)
programs.vscode = {
  enable = true;
  extensions = with pkgs.vscode-extensions; [
    jnoortheen.nix-ide         # Nix language support
    ms-vscode-remote.remote-ssh # Remote development
  ];
};
```

## Error Handling and Validation

### Build Validation Patterns
```bash
# Pre-deployment validation
nix flake check                          # Syntax and dependency validation
nixos-rebuild build --flake .#hostname   # Test build without activation  
nixos-rebuild dry-activate --flake .#hostname  # Preview changes

# Post-deployment validation
systemctl status                         # Check system health
journalctl -f                           # Monitor logs
```

### Common Error Patterns and Solutions
```nix
# Option conflict resolution
assertion = config.networking.wireless.enable == false;
assertionMessage = "NetworkManager conflicts with wpa_supplicant";

# Hardware compatibility checks
assertion = config.hardware.nvidia.enable -> (config.users.hostType != "server");
assertionMessage = "Nvidia drivers not supported on server configurations";
```

## Testing and Rollback Patterns

### Safe Deployment Workflow
1. **Local Testing**: `nixos-rebuild build --flake .#hostname`
2. **Dry Run**: `nixos-rebuild dry-activate --flake .#hostname`  
3. **Test Activation**: `nixos-rebuild test --flake .#hostname`
4. **Permanent Switch**: `nixos-rebuild switch --flake .#hostname`
5. **Rollback if Needed**: `nixos-rebuild switch --rollback`

### ZFS Snapshot Integration
```bash
# Manual snapshot before major changes
zfs snapshot rpool/nixos/root@pre-upgrade

# Rollback to snapshot if needed
zfs rollback rpool/nixos/root@pre-upgrade
```

This document provides the detailed patterns and relationships needed to understand and maintain the modular NixOS configuration system.