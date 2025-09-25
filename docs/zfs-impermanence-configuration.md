# ZFS and Impermanence Configuration Guide

This document explains the ZFS pool structure and impermanence configuration used by the NixOS installation scripts, providing detailed insight into how ephemeral root filesystems work with persistent storage.

## ZFS Pool Architecture

### Pool Structure Overview
The installation creates a single encrypted ZFS pool named `rpool` with a hierarchical dataset organization:

```
rpool (ZFS pool on LUKS-encrypted partition)
├── local/              # Ephemeral datasets (cleared on boot)
│   ├── root            # Root filesystem (/ mountpoint)
│   └── nix             # Nix store (/nix mountpoint)  
└── safe/               # Persistent datasets (survive reboots)
    ├── persist         # System persistence (/persist mountpoint)
    └── home           # User home directories (/home mountpoint)
```

### Dataset Configuration

#### rpool/local/root (Ephemeral Root)
```nix
"local/root" = {
  type = "zfs_fs";
  options = {
    mountpoint = "legacy";           # Manually mounted by NixOS
    recordsize = "1M";              # Optimized for system files
  };
  postCreateHook = ''
    zfs snapshot rpool/local/root@blank  # Create rollback point
  '';
};
```

**Purpose**: Contains the root filesystem that is reset to a pristine state on every boot
**Key Features**:
- **Ephemeral**: Contents are lost on reboot (intentionally)
- **Rollback**: Automatically rolled back to `@blank` snapshot during initrd
- **Performance**: 1MB record size optimized for large system files

#### rpool/local/nix (Nix Store)
```nix
"local/nix" = {
  type = "zfs_fs";
  options = {
    mountpoint = "legacy";
    recordsize = "1M";              # Optimized for large files
    "com.sun:auto-snapshot" = "false";  # Disable automatic snapshots
  };
};
```

**Purpose**: Stores the Nix package store and build artifacts
**Key Features**:
- **Persistent**: Not rolled back (for performance)
- **Performance**: 1MB record size optimal for large package files
- **No Snapshots**: Disabled to save space (store is reproducible)

#### rpool/safe/persist (System Persistence)
```nix
"safe/persist" = {
  type = "zfs_fs";
  options = {
    mountpoint = "legacy";
    recordsize = "128K";           # Mixed workload optimization
  };
};
```

**Purpose**: Stores system configuration and state that must survive reboots
**Key Features**:
- **Persistent**: Never rolled back
- **Mixed Workload**: 128KB record size for varied file sizes
- **System Critical**: Contains SSH keys, logs, system state

#### rpool/safe/home (User Data)
```nix
"safe/home" = {
  type = "zfs_fs";
  options = {
    mountpoint = "legacy";
    recordsize = "128K";           # User files mixed workload
  };
};
```

**Purpose**: User home directories and personal data
**Key Features**:
- **Persistent**: User data survives reboots
- **Mixed Files**: 128KB record size for documents, media, etc.
- **User Focused**: Separate from system persistence for clarity

### ZFS Pool-Level Configuration
```nix
zpool = {
  rpool = {
    type = "zpool";
    options = {
      ashift = "12";              # 4KB sectors (modern SSDs)
      autotrim = "on";           # Automatic TRIM for SSDs
    };
    rootFsOptions = {
      compression = "zstd";       # Modern compression algorithm
      acltype = "posixacl";      # POSIX ACL support
      xattr = "sa";              # System attribute storage
      relatime = "on";           # Relative access time updates
      mountpoint = "none";       # Datasets manage their own mountpoints
    };
  };
};
```

**Performance Features**:
- **ashift=12**: Optimized for 4KB sector SSDs
- **autotrim**: Automatic SSD wear leveling
- **zstd compression**: Better compression ratio than lz4
- **relatime**: Balance between performance and atime updates

## Impermanence System

### Core Concept
Impermanence creates an "ephemeral root" system where:
1. **Root filesystem** (`/`) is reset to a clean state on every boot
2. **Selective persistence** allows specific files/directories to survive reboots
3. **Bind mounts** connect persistent storage to expected locations

### Rollback Mechanism

#### Initrd Rollback Service
```nix
boot.initrd.systemd.services.zfs-rollback = {
  description = "Rollback ZFS root dataset to a blank snapshot";
  wantedBy = [ "initrd.target" ];
  after = [ "zfs-import-rpool.service" ];
  before = [ "sysroot.mount" ];
  path = [ pkgs.zfs ];
  serviceConfig.Type = "oneshot";
  unitConfig.DefaultDependencies = "no";
  script = "zfs rollback -r -f rpool/local/root@blank";
};
```

**Process**:
1. **Boot Stage**: Runs during initrd (before main system)
2. **Dependencies**: After ZFS pool import, before root mount
3. **Rollback**: Resets root dataset to pristine `@blank` snapshot
4. **Force**: `-r -f` flags ensure rollback even with dependent snapshots

#### Systemd Boot Integration
```nix
boot.initrd.systemd.enable = true;
boot.initrd.systemd.settings.Manager = {
  DefaultTimeoutStartSec = "300s";    # Extended timeout for ZFS
  DefaultTimeoutStopSec = "30s";
};
```

**Benefits**:
- **Systemd initrd**: Better service ordering and dependency management
- **Extended timeouts**: Accommodates ZFS import delays
- **Reliable ordering**: Ensures rollback happens before root mount

### Persistence Configuration

#### Environment Persistence Mapping
```nix
environment.persistence."/persist" = {
  hideMounts = true;              # Hide bind mounts from df/mount output
  directories = [
    # System directories that need persistence
    "/var/log"                    # System logs
    "/var/lib/nixos"             # NixOS state
    "/var/lib/systemd/coredump"  # Core dumps
    "/var/lib/AccountsService"   # User account service
    "/etc/NetworkManager/system-connections"  # WiFi passwords
    "/etc/ssh"                   # SSH host keys
  ];
  files = [
    "/etc/machine-id"            # Unique machine identifier
  ];
  users.${username} = {
    directories = [
      # User configuration directories
      ".config"                  # Application configuration
      ".local/share"            # Application data
      ".ssh"                    # SSH keys and known hosts
      "Development"             # User projects
      "Documents"               # User documents
      "Downloads"               # Downloaded files
      # ... additional user directories
    ];
    files = [
      ".bash_history"           # Shell command history
      ".zsh_history"
      ".gitconfig"              # Git configuration
    ];
  };
};
```

#### Directory Structure Created
The installation scripts create this persistent directory structure:

```
/persist/
├── etc/
│   ├── ssh/                     # SSH host keys
│   ├── NetworkManager/          # Network configuration
│   └── machine-id               # System identifier
├── var/
│   ├── log/                     # System logs
│   ├── lib/
│   │   ├── nixos/               # NixOS system state
│   │   ├── systemd/             # systemd state
│   │   └── AccountsService/     # User accounts
│   └── ...
├── root/                        # Root user home
└── home/
    └── ${username}/
        ├── .ssh/                # User SSH keys
        ├── .config/             # User configuration
        ├── .local/              # Local application data
        ├── Development/         # User projects
        ├── Documents/           # User documents
        └── ...
```

### Permission Management

#### SSH Key Permission Fix
```nix
system.activationScripts.fixSSHPermissions = {
  text = ''
    # System SSH keys
    if [ -d "/persist/etc/ssh" ]; then
      chown -R root:root /persist/etc/ssh
      chmod 755 /persist/etc/ssh
      chmod 600 /persist/etc/ssh/ssh_host_*_key      # Private keys
      chmod 644 /persist/etc/ssh/ssh_host_*_key.pub  # Public keys
    fi
    
    # User SSH keys
    if [ -d "/persist/home/${username}/.ssh" ]; then
      chown -R ${username}:${username} /persist/home/${username}/.ssh
      chmod 700 /persist/home/${username}/.ssh
      chmod 600 /persist/home/${username}/.ssh/id_*           # Private keys
      chmod 644 /persist/home/${username}/.ssh/id_*.pub       # Public keys
      chmod 644 /persist/home/${username}/.ssh/authorized_keys
      chmod 644 /persist/home/${username}/.ssh/known_hosts*
    fi
  '';
  deps = [ "users" ];
};
```

**Purpose**: Ensures SSH keys have correct permissions after impermanence rollback
**Timing**: Runs after user creation during system activation

## Filesystem Mount Configuration

### Mount Points and Options
```nix
fileSystems = {
  "/" = {
    device = "rpool/local/root";
    fsType = "zfs";
    # No special options - ephemeral root
  };
  "/nix" = {
    device = "rpool/local/nix";
    fsType = "zfs";
    neededForBoot = true;         # Required for boot process
  };
  "/persist" = {
    device = "rpool/safe/persist";
    fsType = "zfs";
    neededForBoot = true;         # Required for impermanence
    options = [ 
      "zfsutil"                   # Use ZFS mount helper
      "x-systemd.device-timeout=300"  # Extended timeout
    ];
  };
  "/home" = {
    device = "rpool/safe/home";
    fsType = "zfs";
    # Standard user data mount
  };
  "/boot" = {
    device = "/dev/disk/by-partlabel/disk-main-ESP";
    fsType = "vfat";
    options = [ "umask=0077" ];   # Secure boot partition
  };
};
```

### Boot Dependencies
- **`neededForBoot = true`**: Ensures `/nix` and `/persist` are available early
- **Extended timeouts**: Accommodates ZFS import delays
- **Device labels**: Uses stable partition labels for boot partition

## Benefits of This Architecture

### Security Benefits
- **Clean State**: System starts fresh on every boot
- **Attack Surface**: Malware cannot persist in root filesystem
- **Configuration Control**: All persistence is explicitly declared

### Maintenance Benefits
- **No System Rot**: Eliminates gradual system degradation
- **Reproducible**: System configuration is fully declarative
- **Easy Recovery**: Broken changes are automatically rolled back

### Performance Benefits
- **ZFS Features**: Compression, checksums, snapshots
- **SSD Optimization**: Proper alignment and TRIM support
- **Record Size**: Optimized for different workload patterns

### Development Benefits
- **Safe Experimentation**: System-level changes don't persist
- **Clean Testing**: Each boot provides clean environment
- **Explicit State**: Forces consideration of what needs persistence

## Common Persistence Patterns

### System Services
Services that need persistence typically store data in:
- `/var/lib/service-name` - Service state and databases
- `/etc/service-name` - Service configuration files
- `/var/log/service-name` - Service log files

### User Applications
Applications typically need persistence for:
- `~/.config/app-name` - Application configuration
- `~/.local/share/app-name` - Application data
- `~/.cache/app-name` - Application cache (optional)

### Development Tools
Development environments often need:
- `~/Development` - Project source code
- `~/.cargo`, `~/.npm` - Language-specific caches
- `~/.gitconfig` - Version control configuration
- SSH keys and known hosts

This architecture provides a robust foundation for modern NixOS systems that emphasize reproducibility, security, and maintainability through declarative configuration and ephemeral root filesystems.