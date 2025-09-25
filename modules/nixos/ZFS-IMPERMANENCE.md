# ZFS and Impermanence Configuration - Advanced Documentation

## Overview
This configuration implements an advanced storage architecture using ZFS (Zettabyte File System) with LUKS encryption and impermanence (ephemeral root filesystem). This setup provides maximum security, data integrity, and system cleanliness through automated rollback to a pristine state on each boot.

## Architecture Components

### Storage Stack Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    EFI System Partition                     │
│                     /boot (vfat)                           │
├─────────────────────────────────────────────────────────────┤
│                   LUKS Encryption Layer                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                  ZFS Pool (rpool)                   │    │
│  │  ┌─────────────────┬─────────────────────────────┐  │    │
│  │  │   Ephemeral     │      Persistent Storage    │  │    │
│  │  │   Root (/)      │        (/persist)          │  │    │
│  │  │   [tmpfs]       │     [ZFS Dataset]          │  │    │
│  │  │                 │                             │  │    │
│  │  │ • System files  │ • User data                 │  │    │
│  │  │ • Application   │ • Configuration files      │  │    │
│  │  │   state         │ • SSH keys                  │  │    │
│  │  │ • Temporary     │ • Application data          │  │    │
│  │  │   files         │ • System state              │  │    │
│  │  │                 │                             │  │    │
│  │  │ [WIPED ON       │ [SURVIVES REBOOTS]          │  │    │
│  │  │  EVERY BOOT]    │                             │  │    │
│  │  └─────────────────┴─────────────────────────────┘  │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### ZFS Pool Structure
```
rpool (main pool)
├── rpool/local (non-replicated datasets)
│   ├── rpool/local/root (ephemeral root, rolled back on boot)
│   └── rpool/local/nix (Nix store, persistent)
├── rpool/safe (replicated/backed up datasets)
│   ├── rpool/safe/home (user home directories)
│   └── rpool/safe/persist (persistent system state)
└── rpool/reserved (reserved space for performance)
```

## Key Configuration Components

### Impermanence Module Configuration
Located in `modules/nixos/impermanence.nix`, this module configures:

#### ZFS Rollback Service
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

**Purpose**: Automatically rolls back the root filesystem to a blank snapshot on every boot, ensuring a clean system start.

#### Persistent Directory Configuration
```nix
environment.persistence."/persist" = {
  directories = [
    # System directories that must survive reboots
    "/var/lib/nixos"           # NixOS system state
    "/var/lib/systemd/coredump" # System crash dumps
    "/etc/NetworkManager/system-connections" # Network configs
    "/var/lib/bluetooth"       # Bluetooth pairings
    "/var/lib/fprint"         # Fingerprint data
    "/var/log"                # System logs
  ];
  
  files = [
    # Critical system files
    "/etc/machine-id"         # Unique machine identifier
    "/etc/ssh/ssh_host_ed25519_key"     # SSH host keys
    "/etc/ssh/ssh_host_ed25519_key.pub"
    "/etc/ssh/ssh_host_rsa_key"
    "/etc/ssh/ssh_host_rsa_key.pub"
  ];
  
  users.${username} = {
    directories = [
      # User directories to persist
      "Documents"
      "Downloads" 
      "Music"
      "Pictures"
      "Videos"
      "Projects"
      ".ssh"                  # User SSH keys
      ".gnupg"                # GPG keys
      ".config/1Password"     # 1Password configuration
    ];
    
    files = [
      # User files to persist
      ".gitconfig"            # Git configuration
    ];
  };
};
```

### ZFS Configuration

#### Pool Properties and Features
```nix
# ZFS pool configuration (typically in hardware/disko-zfs.nix)
pool = {
  name = "rpool";
  type = "zpool";
  
  # Performance and reliability settings
  options = {
    ashift = "12";              # 4K sector alignment
    autotrim = "on";           # Automatic TRIM for SSDs
    compression = "zstd";       # ZSTD compression for space/performance
    atime = "off";             # Disable access time updates
    xattr = "sa";              # Extended attributes in system attributes
    dnodesize = "auto";        # Dynamic dnode sizing
    normalization = "formD";    # Unicode normalization
    relatime = "on";           # Relative access time updates
    canmount = "off";          # Pool root not mountable
    mountpoint = "/";          # Default mount point
  };
};
```

#### Dataset Configuration
```nix
datasets = {
  # Ephemeral root dataset
  "rpool/local/root" = {
    type = "zfs_fs";
    mountpoint = "/";
    options = {
      compression = "zstd";
      mountpoint = "/";
      canmount = "noauto";      # Manual mounting during boot
    };
  };
  
  # Nix store dataset  
  "rpool/local/nix" = {
    type = "zfs_fs";
    mountpoint = "/nix";
    options = {
      compression = "zstd";
      atime = "off";            # Nix store doesn't need access times
      canmount = "on";
    };
  };
  
  # Persistent data dataset
  "rpool/safe/persist" = {
    type = "zfs_fs";
    mountpoint = "/persist";
    options = {
      compression = "zstd";
      canmount = "on";
    };
  };
  
  # Home directories dataset
  "rpool/safe/home" = {
    type = "zfs_fs";
    mountpoint = "/home";
    options = {
      compression = "zstd";
      canmount = "on";
    };
  };
};
```

## Security Features

### LUKS Encryption Layer
- **Full Disk Encryption**: All data encrypted at rest using LUKS2
- **Strong Key Derivation**: PBKDF2 with high iteration count
- **Secure Boot Integration**: Unlocked during initrd boot process
- **Key Management**: Secure passphrase handling and key file options

### Ephemeral Root Benefits
- **Malware Protection**: Any persistent malware is wiped on reboot
- **System Cleanliness**: No accumulation of temporary files or cruft
- **Configuration Drift Prevention**: System always starts from known state
- **Easy Recovery**: Simple reboot fixes most system issues
- **Forensic Protection**: Reduces persistent evidence of activity

### ZFS Security Features
- **Data Integrity**: Built-in checksumming detects and corrects corruption
- **Snapshot Immutability**: Snapshots cannot be modified once created
- **Encryption Support**: Native ZFS encryption (additional to LUKS)
- **Access Controls**: Fine-grained permissions and access controls

## Performance Optimization

### ZFS Performance Tuning
```nix
# ARC (Adaptive Replacement Cache) tuning
boot.kernel.sysctl = {
  # Limit ZFS ARC to 50% of RAM (adjust based on system)
  "vm.swappiness" = 1;
  # ZFS ARC tuning
  "vm.vfs_cache_pressure" = 50;
};

# ZFS kernel module parameters
boot.extraModprobeConfig = ''
  # Limit ARC size (in bytes) - adjust for your system
  options zfs zfs_arc_max=8589934592  # 8GB
  options zfs zfs_arc_min=1073741824  # 1GB
'';
```

### Dataset Record Size Optimization
- **Small files**: Use 64K-128K record size for better compression
- **Large files**: Use 1M record size for better sequential performance
- **Mixed workloads**: Use default 128K record size as compromise
- **Database workloads**: Consider 8K-32K record size

### Compression Algorithms
- **ZSTD**: Best overall compression and performance (recommended)
- **LZ4**: Faster compression, less space savings
- **GZIP**: Higher compression ratio, more CPU intensive
- **Off**: No compression for already compressed data

## Troubleshooting Guide

### Common ZFS Issues

#### Pool Import Failures
**Symptoms**: System won't boot, "cannot import pool" errors
**Diagnosis**:
```bash
# From NixOS ISO rescue environment
zpool import                    # List importable pools
zpool import -f rpool          # Force import pool
zpool status -v                # Check pool health
zfs list                       # Verify datasets
```

**Solutions**:
- **Corrupted pool**: Use `zpool import -F rpool` (may cause data loss)
- **Missing devices**: Check disk connections and device paths
- **Metadata corruption**: Restore from backup or use recovery options
- **Cache issues**: Clear ZFS cache with `rm /etc/zfs/zpool.cache`

#### Snapshot and Rollback Issues
**Symptoms**: Cannot rollback, snapshot errors, boot failures
**Diagnosis**:
```bash
zfs list -t snapshot            # List all snapshots
zfs list -t snapshot rpool/local/root  # Check root snapshots
zfs get all rpool/local/root@blank     # Check blank snapshot properties
```

**Solutions**:
- **Missing blank snapshot**: Create with `zfs snapshot rpool/local/root@blank`
- **Rollback failures**: Use `zfs rollback -r -f rpool/local/root@blank`
- **Snapshot corruption**: Delete and recreate blank snapshot
- **Service ordering**: Check systemd service dependencies in initrd

#### Performance Issues
**Symptoms**: Slow boot, high I/O wait, system lag
**Diagnosis**:
```bash
zpool iostat -v 1              # Monitor pool I/O
arc_summary                    # Check ARC usage
zfs get compression,compressratio  # Check compression stats
```

**Solutions**:
- **High ARC usage**: Tune `zfs_arc_max` parameter
- **Poor compression**: Adjust compression algorithm per dataset
- **Fragmentation**: Consider `zpool defragment` (newer ZFS versions)
- **I/O bottleneck**: Check underlying disk performance

### Impermanence Issues

#### Missing Persistent Files
**Symptoms**: Configuration lost after reboot, applications fail to start
**Diagnosis**:
```bash
# Check persistence configuration
ls -la /persist/               # Verify persistent storage structure
systemctl status create-needed-for-boot-dirs.service  # Check bind mounts
mount | grep persist           # Verify mounts
```

**Solutions**:
- **Add to persistence**: Update `environment.persistence."/persist"` configuration
- **Manual recovery**: Copy files from backup or previous generation
- **Bind mount issues**: Check systemd services for proper mounting
- **Permissions**: Verify file ownership and permissions in `/persist`

#### Boot Process Failures
**Symptoms**: System hangs during boot, initrd issues, mount failures
**Diagnosis**:
```bash
# Boot from NixOS ISO and check
journalctl -b                  # Check boot logs
systemctl --failed             # Check failed services
zfs mount                      # Check ZFS mount status
```

**Solutions**:
- **Service ordering**: Fix systemd service dependencies
- **Mount issues**: Verify dataset mount points and properties  
- **Initrd problems**: Check initrd systemd configuration
- **Rollback service**: Verify ZFS rollback service configuration

## Maintenance and Best Practices

### Regular Maintenance Tasks

#### Snapshot Management
```bash
# Create periodic snapshots (automated via systemd timers)
zfs snapshot rpool/safe/home@$(date +%Y%m%d-%H%M%S)
zfs snapshot rpool/safe/persist@$(date +%Y%m%d-%H%M%S)

# Clean old snapshots (keep last 30 days)
zfs list -H -t snapshot | awk '{print $1}' | grep -E '@[0-9]{8}-[0-9]{6}$' | head -n -30 | xargs -r zfs destroy

# Verify snapshot integrity
zfs scrub rpool
```

#### Pool Health Monitoring
```bash
# Weekly scrub (automated)
zpool scrub rpool

# Check pool health
zpool status -v
zpool list -v

# Monitor compression ratios
zfs get compressratio rpool -r
```

#### Performance Monitoring
```bash
# Monitor ARC efficiency
arc_summary | grep "Hit Rates"

# Check dataset usage
zfs list -o space

# Monitor I/O patterns
zpool iostat -v 5 12
```

### Security Best Practices

#### Access Controls
- **Restrict ZFS commands**: Limit access to ZFS administrative commands
- **Audit snapshots**: Regular audit of snapshot access and usage
- **Encrypt sensitive datasets**: Use ZFS native encryption for sensitive data
- **Monitor access**: Log and monitor ZFS administrative operations

#### Backup Strategies
- **Off-site replication**: Use `zfs send/receive` for remote backups
- **Snapshot retention**: Implement proper snapshot retention policies
- **Recovery testing**: Regular testing of backup and recovery procedures
- **Key management**: Secure backup of encryption keys and passphrases

### Advanced Configuration Patterns

#### Multi-Pool Setup
```nix
# Example: Separate pools for different purposes
pools = {
  rpool = {
    # System and fast storage
    devices = [ "/dev/disk/by-id/nvme-fast-ssd" ];
    options.ashift = "12";
  };
  
  data = {
    # Large data storage
    devices = [ "/dev/disk/by-id/sata-large-hdd1" "/dev/disk/by-id/sata-large-hdd2" ];
    type = "mirror";
    options.ashift = "12";
  };
};
```

#### Encrypted Dataset Configuration
```nix
# Native ZFS encryption (in addition to LUKS)
"rpool/safe/encrypted" = {
  type = "zfs_fs";
  options = {
    encryption = "aes-256-gcm";
    keyformat = "passphrase";
    keylocation = "prompt";
    compression = "zstd";
  };
};
```

This comprehensive documentation should enable agents to understand, configure, troubleshoot, and maintain the ZFS and impermanence setup effectively.