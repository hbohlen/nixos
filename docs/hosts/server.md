# Server Host Configuration

## Overview

The server host configuration is designed for headless operation with emphasis on stability, security, performance, and minimal resource consumption. This configuration is optimized for service hosting, containerized applications, and always-on server workloads without desktop environment overhead.

## Hardware Profile

### Target Hardware
- **Form Factor**: Standard server hardware, mini PCs, or repurposed desktop systems
- **CPU**: Any modern x86_64 processor (Intel/AMD)
- **RAM**: 8GB minimum, 16GB+ recommended for containerized workloads
- **Storage**: SATA SSD/HDD or NVMe (SATA preferred for cost efficiency)
- **Network**: Gigabit Ethernet (minimum), 10GbE or higher for high-throughput services
- **Power**: Focus on power efficiency and 24/7 operation capability

### Supported Configurations
- **Bare Metal Servers**: Physical dedicated server hardware
- **Mini PCs**: Intel NUC, Beelink, or similar compact systems
- **Repurposed Hardware**: Desktop systems converted for server use  
- **Virtual Machines**: When used as base system in VM environments
- **Container Hosts**: Optimized for Docker/Podman container orchestration

## Storage Configuration

### Server-Optimized ZFS Layout
The server configuration prioritizes reliability and data integrity over performance:

**Disk Partitioning (`hardware/disko-layout.nix`)**:
- **ESP**: 1GB EFI System Partition for boot reliability
- **Swap**: 4GB minimal encrypted swap (server workloads typically use less swap)
- **LUKS**: Full disk encryption for data security
- **ZFS Pool**: Single `rpool` optimized for server reliability

**ZFS Dataset Configuration**:
```nix
zpool.options = {
  ashift = "12";                    # 4K sector alignment for modern drives
  autotrim = "on";                  # Automatic TRIM for SSD longevity
};

rootFsOptions = {
  compression = "zstd";             # Excellent compression for server data
  acltype = "posixacl";            # POSIX ACL support for services
  xattr = "sa";                     # Extended attributes in System Attribute
  relatime = "on";                  # Reduced metadata writes
  mountpoint = "none";              # No automatic mounting
};

datasets = {
  "local/root" = {
    recordsize = "1M";              # System files optimization
    compression = "zstd";           # Reduce storage usage
    mountpoint = "legacy";          # Impermanence integration
  };
  
  "local/nix" = {
    recordsize = "1M";              # Large files (Nix packages)
    compression = "zstd";
    "com.sun:auto-snapshot" = "false"; # No snapshots for Nix store
  };
  
  "safe/persist" = {
    recordsize = "128K";            # Mixed server data optimization
    compression = "zstd";           # Compress persistent data
  };
  
  "safe/home" = {
    recordsize = "128K";            # User files (minimal on servers)
    compression = "zstd";
  };
};
```

**Server Storage Benefits**:
- **Data Integrity**: ZFS checksums protect against silent corruption
- **Compression**: Reduces storage requirements for logs and data
- **Snapshots**: Easy backup and recovery for server data
- **Encryption**: Full disk encryption protects sensitive server data

## Performance and Resource Optimization

### CPU Performance Tuning
Server-specific kernel parameters for optimal performance:

```nix
boot.kernelParams = [
  "nohz_full=1-15"                  # CPU isolation for better performance
  "rcu_nocbs=1-15"                  # RCU callback offloading
  "tsc=reliable"                    # Trust TSC clock source
  "processor.max_cstate=1"          # Limit C-states for lower latency
  "idle=poll"                       # Use idle=poll for low latency
];
```

**CPU Optimization Features**:
- **CPU Isolation**: Dedicates CPU cores for critical server processes
- **RCU Offloading**: Reduces kernel overhead on application CPUs
- **Low Latency**: Minimized CPU sleep states for consistent performance
- **Reliable Timing**: Optimized clock sources for server applications

### Memory Management
```nix
systemd.settings.Manager = {
  DefaultLimitNOFILE = 65536;       # Higher file descriptor limits
  DefaultLimitNPROC = 32768;        # Higher process limits
};
```

**Server Memory Features**:
- **Resource Limits**: Appropriate limits for server applications
- **File Descriptors**: Support for high-connection server applications
- **Process Limits**: Handle multiple concurrent server processes
- **Memory Overcommit**: Conservative settings for server stability

### Storage I/O Optimization
- **Minimal Swap**: 4GB swap reduces I/O overhead
- **ZFS Compression**: Reduces actual disk writes and network transfer
- **Optimized Record Sizes**: Balanced for server workload patterns
- **Automatic TRIM**: Maintains SSD performance over time

## Security Configuration

### Network Security
```nix
networking.firewall = {
  enable = true;                    # Enable firewall protection
  allowedTCPPorts = [ 22 ];        # SSH access only by default
  allowedUDPPorts = [ ];           # No UDP ports open by default
  trustedInterfaces = [ ];          # Configure per-host as needed
};
```

**Security Features**:
- **Minimal Attack Surface**: Only SSH port open by default
- **Fail2Ban**: Automatic IP blocking for failed SSH attempts
- **SSH Key Authentication**: Password authentication disabled after setup
- **Host-Based Firewall**: iptables-based filtering

### Access Control
```nix
# SSH Key Configuration (Security - CRITICAL for servers)
# users.sshKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... your-key" ];
# users.enablePasswordAuth = false;  # Disable after SSH keys configured
```

**Authentication Security**:
- **SSH Keys Only**: Disable password authentication for production
- **Key Management**: Secure SSH key distribution and management
- **User Access**: Minimal user accounts for reduced attack surface
- **Privilege Escalation**: Controlled sudo access for administration

### Data Protection
- **Full Disk Encryption**: LUKS encryption protects data at rest
- **Encrypted Swap**: Prevents sensitive data in swap files
- **ZFS Encryption**: Additional encryption layer for sensitive datasets
- **Secure Boot**: Optional secure boot chain validation

## System Services and Monitoring

### Core Server Services
```nix
environment.systemPackages = with pkgs; [
  # Essential system tools
  htop btop                         # System monitoring
  iotop nethogs                     # I/O and network monitoring  
  ncdu                             # Disk usage analysis
  
  # Network tools
  wget curl                        # HTTP clients
  bind netcat-gnu                  # Network diagnostics
  tcpdump wireshark-cli           # Network analysis
  
  # System administration
  vim neovim                       # Text editors
  tmux screen                      # Terminal multiplexers
  rsync                           # File synchronization
  
  # Compression and archival
  gzip bzip2 xz zip unzip         # Archive tools
  
  # Security tools  
  fail2ban                        # Intrusion prevention
  borgbackup restic               # Backup solutions
  
  # Container runtime
  podman docker-compose           # Container management
  
  # Virtualization (optional)
  qemu libvirt                    # VM hosting capabilities
  
  # Database clients (optional)
  postgresql mysql-client redis   # Database connectivity
  
  # Development tools (minimal)
  gcc python3 go                  # Basic development stack
];
```

### Automatic System Management
```nix
system.autoUpgrade = {
  enable = true;                    # Automatic security updates
  dates = "daily";                  # Update schedule
  allowReboot = false;              # Manual reboot control
};
```

**Automated Maintenance**:
- **Security Updates**: Daily automatic updates for security patches
- **Log Management**: Automatic log rotation and cleanup
- **Service Monitoring**: Systemd service health monitoring
- **Resource Cleanup**: Automatic cleanup of old system generations

### Logging and Monitoring
```nix
services.journald.extraConfig = ''
  SystemMaxUse=1G                   # Limit journal size
  SystemKeepFree=2G                 # Keep free space
  RuntimeMaxUse=256M                # Runtime journal size
  RuntimeKeepFree=512M              # Runtime free space
  MaxFileSec=1month                 # Log retention period
'';
```

**Monitoring Capabilities**:
- **Centralized Logging**: systemd journal with size limits
- **Resource Monitoring**: Built-in system monitoring tools
- **Network Monitoring**: Network traffic and connection monitoring
- **Performance Metrics**: CPU, memory, disk, and network metrics

## Container and Virtualization Support

### Container Runtime
The server includes comprehensive container support:

```nix
# Container support
podman                              # Rootless containers
docker-compose                      # Multi-container applications

# Virtualization
qemu libvirt virt-manager          # Full virtualization stack
```

**Container Features**:
- **Podman**: Rootless containers for security
- **Docker Compatibility**: Docker-compatible API and CLI
- **Compose Support**: Multi-container application orchestration
- **Registry Access**: Support for public and private container registries

### Virtualization Capabilities
- **KVM/QEMU**: Full hardware virtualization support
- **libvirt**: VM management and orchestration
- **Nested Virtualization**: Support for VMs running containers
- **Network Isolation**: Advanced networking for VMs and containers

## Network Configuration

### Server Networking
```nix
networking = {
  # Server-specific network settings
  useDHCP = false;                  # Static IP recommended for servers
  useNetworkd = true;               # systemd-networkd for reliability
  
  # Firewall configuration
  firewall.enable = true;           # Essential for server security
  
  # Host identification
  hostName = "server";              # Must match flake.nix
  hostId = "facefeed";             # Required for ZFS (unique 8-char hex)
};
```

**Network Features**:
- **Static IP Configuration**: Preferred for server reliability
- **IPv6 Support**: Full dual-stack IPv4/IPv6 capability
- **Network Bridges**: Support for VM and container networking
- **Advanced Routing**: Policy routing and traffic shaping capabilities

### Service Discovery
- **mDNS/DNS-SD**: Avahi for local service discovery
- **Static DNS**: Reliable DNS configuration for server services
- **Network Time**: NTP synchronization for accurate timestamps
- **Network Monitoring**: Built-in network performance monitoring

## Backup and Data Management

### Backup Solutions
The server includes multiple backup options:

```nix
# Backup tools included in system packages
borgbackup                          # Deduplicating backup program  
restic                             # Cross-platform backup tool
rsync                              # Incremental file synchronization
```

**Backup Strategies**:
- **ZFS Snapshots**: Instant filesystem-level snapshots
- **Borg Backup**: Deduplicating encrypted backups
- **Restic**: Cloud-native backup with encryption
- **Rsync**: Incremental synchronization for replication

### Data Integrity
- **ZFS Checksums**: Automatic data integrity verification
- **Scrub Operations**: Regular filesystem consistency checks
- **SMART Monitoring**: Drive health monitoring and alerting
- **Redundancy**: Support for ZFS mirroring and RAID-Z configurations

## Performance Characteristics

### Server Performance Profile
**Optimized For**:
- **24/7 Operation**: Continuous availability and reliability
- **Service Hosting**: Web services, databases, application servers
- **Container Workloads**: Multiple containerized applications
- **Network Services**: High-throughput network applications
- **Batch Processing**: Background processing and computation

**Performance Metrics**:
- **CPU Utilization**: Optimized for sustained load rather than peak performance
- **Memory Usage**: Efficient memory management for long-running processes
- **I/O Performance**: Balanced read/write performance for server workloads
- **Network Throughput**: Optimized for concurrent network connections

### Resource Allocation
- **CPU Scheduling**: CFS scheduler optimized for server workloads
- **Memory Management**: Conservative memory overcommit for stability  
- **I/O Scheduling**: Deadline scheduler for predictable I/O latency
- **Network Stack**: Tuned for high connection counts and throughput

## Installation and Deployment

### Pre-Installation Planning
1. **Hardware Requirements**:
   - Verify CPU virtualization support for containers/VMs
   - Confirm network adapter compatibility
   - Ensure adequate cooling for 24/7 operation
   - Plan storage capacity for services and data

2. **Network Planning**:
   - Static IP address assignment
   - DNS configuration and hostname registration
   - Firewall rules and port planning
   - VPN access if needed for remote management

### Installation Process
1. **Disk Configuration**: Update device path in `hardware/disko-layout.nix`
2. **Network Setup**: Configure static IP and DNS settings
3. **Security Setup**: Generate and deploy SSH keys
4. **Service Planning**: Identify services to be hosted
5. **Backup Planning**: Configure backup destinations and schedules

### Post-Installation Hardening
1. **SSH Security**:
   ```bash
   # Disable password authentication
   users.enablePasswordAuth = false;
   # Add SSH keys
   users.sshKeys = [ "your-ssh-public-key" ];
   ```

2. **Firewall Configuration**:
   - Open only necessary service ports
   - Configure fail2ban for intrusion prevention
   - Set up monitoring and alerting

3. **Service Security**:
   - Run services as non-root users when possible
   - Configure SELinux/AppArmor policies if needed
   - Regular security updates and monitoring

## Service Deployment

### Container Services
The server is optimized for hosting containerized applications:

```bash
# Example service deployment with Podman
podman run -d \
  --name web-service \
  --restart unless-stopped \
  -p 8080:80 \
  nginx:alpine

# Docker Compose for multi-container applications  
docker-compose up -d
```

### System Services
Native systemd services for better integration:
- **Database Services**: PostgreSQL, MySQL, Redis
- **Web Services**: Nginx, Apache, reverse proxies
- **Monitoring**: Prometheus, Grafana, logging services
- **Backup Services**: Automated backup scheduling

## Maintenance and Operations

### Regular Maintenance Tasks
1. **Security Updates**:
   - Automatic daily security updates enabled
   - Manual review of system updates monthly
   - Container image updates as needed

2. **System Monitoring**:
   - Daily system health checks
   - Weekly performance review
   - Monthly capacity planning review

3. **Backup Verification**:
   - Daily backup completion verification
   - Weekly backup restoration testing
   - Monthly backup retention cleanup

### Performance Monitoring
```bash
# System monitoring commands
htop                                # Real-time system monitor
iotop                              # I/O usage monitoring  
nethogs                            # Network usage by process
ncdu /                             # Disk usage analysis
journalctl -f                      # Real-time log monitoring
```

### Troubleshooting Tools
- **System Analysis**: `systemctl`, `journalctl`, `dmesg`
- **Network Debugging**: `ss`, `netstat`, `tcpdump`
- **Performance Analysis**: `perf`, `strace`, `ltrace`
- **Storage Debugging**: `zpool status`, `zfs list`, `smartctl`

## Limitations and Considerations

### Hardware Limitations
- **Single Point of Failure**: Single-server configuration lacks redundancy
- **Scaling Limits**: Vertical scaling limited by hardware constraints
- **Network Dependency**: Relies on network infrastructure availability
- **Power Dependency**: No built-in redundant power supplies

### Software Limitations
- **No Desktop Environment**: Headless operation only
- **Service Dependencies**: Limited isolation between services
- **Update Windows**: Updates may require service interruption
- **Recovery Complexity**: Disaster recovery requires technical expertise

### Operational Considerations
- **24/7 Operations**: Requires reliable power and cooling
- **Remote Management**: SSH-only access requires network connectivity  
- **Backup Management**: Regular testing and verification required
- **Security Monitoring**: Continuous security monitoring recommended

### Cost Considerations
- **Power Consumption**: 24/7 operation electricity costs
- **Maintenance**: Regular hardware and software maintenance needs
- **Backup Storage**: External backup storage requirements
- **Network Costs**: Static IP and bandwidth costs

## Migration and Scaling

### Migration Strategies
- **Blue-Green Deployment**: Parallel system deployment for zero-downtime migration
- **Service Migration**: Individual service migration with load balancers  
- **Data Migration**: ZFS send/receive for efficient data transfer
- **Container Migration**: Container image portability for service migration

### Scaling Options
- **Vertical Scaling**: Hardware upgrades (CPU, RAM, storage)
- **Horizontal Scaling**: Multiple server deployment with load balancing
- **Container Orchestration**: Kubernetes or Docker Swarm for multi-node setups
- **Cloud Migration**: Migration to cloud platforms when needed