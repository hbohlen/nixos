# NixOS Configuration Troubleshooting Guide

## Overview
This guide provides comprehensive troubleshooting procedures for common issues in the NixOS configuration. It covers system-level problems, module-specific issues, and recovery procedures.

## Emergency Recovery Procedures

### Boot Recovery (Critical Issues)

#### System Won't Boot
1. **Boot from NixOS ISO**:
   ```bash
   # Insert NixOS installation medium and boot
   # Select "NixOS live environment" from boot menu
   ```

2. **Unlock Encrypted Storage**:
   ```bash
   # Find encrypted device
   lsblk
   # Unlock LUKS encryption (replace sdX with actual device)
   cryptsetup luksOpen /dev/sdX crypt-root
   ```

3. **Import ZFS Pool**:
   ```bash
   # Import the ZFS pool
   zpool import rpool
   # Check pool status
   zpool status
   ```

4. **Mount Filesystems**:
   ```bash
   # Mount root and other filesystems
   mkdir -p /mnt
   mount /dev/mapper/crypt-root /mnt  # If using LUKS on root
   # Or for ZFS root:
   zfs set mountpoint=/mnt rpool/local/root
   zfs mount rpool/local/root
   
   # Mount other important filesystems
   mount /dev/sdX1 /mnt/boot  # EFI system partition
   zfs mount rpool/safe/persist
   zfs mount rpool/safe/home
   ```

5. **Enter Recovery Environment**:
   ```bash
   # Bind mount necessary directories
   for dir in dev proc sys run; do
     mount --bind /$dir /mnt/$dir
   done
   
   # Enter chroot
   chroot /mnt /bin/bash
   ```

#### Rollback to Previous Generation
```bash
# List available generations
ls -la /nix/var/nix/profiles/system*

# Rollback to previous generation
nixos-rebuild switch --rollback

# Or manually activate specific generation
/nix/var/nix/profiles/system-42-link/bin/switch-to-configuration switch
```

#### Emergency ZFS Rollback
```bash
# Rollback to blank snapshot (nuclear option)
zfs rollback -r -f rpool/local/root@blank

# Or rollback to specific snapshot
zfs list -t snapshot rpool/local/root
zfs rollback rpool/local/root@snapshot-name
```

## Build and Configuration Issues

### Flake Configuration Problems

#### Flake Check Failures
**Symptoms**: `nix flake check` fails with syntax or evaluation errors
**Diagnosis**:
```bash
# Check flake syntax with detailed errors
nix flake check --show-trace

# Evaluate specific outputs
nix eval .#nixosConfigurations.hostname.config.system.build.toplevel
```

**Common Solutions**:
- **Syntax errors**: Fix Nix syntax in configuration files
- **Missing imports**: Verify all module imports exist and are correct
- **Option conflicts**: Resolve conflicting option definitions
- **Type errors**: Ensure options have correct types and values

#### Module Import Errors
**Symptoms**: "file not found" or "module does not exist" errors
**Diagnosis**:
```bash
# Check file paths and permissions
ls -la modules/nixos/
# Verify module syntax
nix-instantiate --parse modules/nixos/problematic-module.nix
```

**Solutions**:
- **Fix paths**: Use correct relative paths (e.g., `./modules/nixos/module.nix`)
- **Check permissions**: Ensure files are readable
- **Module structure**: Verify proper module structure with options and config
- **Circular imports**: Check for circular import dependencies

### Build Failures

#### Package Build Errors
**Symptoms**: Package compilation failures, missing dependencies
**Diagnosis**:
```bash
# Build specific package to isolate issue
nix build nixpkgs#package-name

# Check build logs
nix log /nix/store/hash-package-name

# Search for available packages
nix search nixpkgs package-name
```

**Solutions**:
- **Update packages**: Run `nix flake update` to update package versions
- **Check availability**: Verify package exists in current nixpkgs version
- **Alternative packages**: Use alternative packages or build from source
- **Overlays**: Create package overlay if custom build needed

#### Dependency Conflicts
**Symptoms**: Version conflicts, incompatible dependencies
**Diagnosis**:
```bash
# Check dependency tree
nix why-depends /run/current-system package-name

# Show package dependencies
nix-store -q --tree /run/current-system
```

**Solutions**:
- **Pin versions**: Pin specific package versions in flake
- **Override packages**: Use package overrides to resolve conflicts
- **Alternative sources**: Use different package sources or channels
- **Modular approach**: Split conflicting packages into different profiles

## Installation and Bootstrap Issues

### NixOS Installation Problems

#### Firmware License Errors During Installation
**Symptom**: `nixos-install` fails with error about `hardware.enableAllFirmware` requiring `allowUnfree = true`
**Root Cause**: WiFi module was configured to enable all firmware (including proprietary) by default

**Error Message**:
```
Failed assertions:
- the list of hardware.enableAllFirmware contains non-redistributable licensed firmware files.
  This requires nixpkgs.config.allowUnfree to be true.
  An alternative is to use the hardware.enableRedistributableFirmware option.
```

**Solutions**:
1. **Use redistributable firmware only** (recommended for installation):
   ```nix
   wifi = {
     enable = true;
     enableFirmware = true;                 # Redistributable firmware only
     enableProprietaryFirmware = false;     # Disable proprietary firmware
   };
   ```

2. **Enable proprietary firmware post-installation** (if specific hardware requires it):
   ```nix
   wifi = {
     enable = true;
     enableFirmware = true;
     enableProprietaryFirmware = true;      # Enable after installation
   };
   ```

3. **Temporary workaround for installation**:
   ```bash
   # During installation, edit the configuration to disable all firmware
   # In /mnt/etc/nixos/configuration.nix or host config:
   hardware.enableAllFirmware = lib.mkForce false;
   hardware.enableRedistributableFirmware = true;
   ```

**Prevention**: The WiFi module now defaults to redistributable firmware only, preventing this installation issue while maintaining WiFi functionality.

#### Disk Partitioning Issues
**Symptoms**: Disko fails, partition creation errors
**Diagnosis**:
```bash
# Check disk status
lsblk -f
sgdisk --print /dev/sdX

# Check for existing partitions or filesystems
wipefs -a /dev/sdX  # Use with caution - destroys data
```

**Solutions**:
- **Clean disk**: Ensure target disk is clean of existing partitions
- **Check device path**: Verify correct device path in disko configuration
- **UEFI/BIOS compatibility**: Ensure EFI partition configuration matches boot mode

## Hardware and Driver Issues

### Graphics and Display Problems

#### NVIDIA Driver Issues
**Symptoms**: No display, poor performance, driver crashes
**Diagnosis**:
```bash
# Check NVIDIA driver status
nvidia-smi
lsmod | grep nvidia

# Check X11/Wayland logs
journalctl -u display-manager
cat /var/log/Xorg.0.log
```

**Solutions**:
- **Update drivers**: Ensure latest NVIDIA drivers in configuration
- **Kernel compatibility**: Verify driver compatibility with kernel version
- **Module loading**: Check if nvidia modules load properly
- **Alternative drivers**: Try nouveau (open source) drivers for testing

#### Wayland/Hyprland Issues
**Symptoms**: Compositor crashes, display artifacts, input problems
**Diagnosis**:
```bash
# Check Hyprland logs
journalctl --user -u hyprland

# Test compositor directly
Hyprland --config /dev/null

# Check graphics capabilities
glxinfo | grep -i renderer
```

**Solutions**:
- **Graphics drivers**: Ensure proper graphics drivers installed
- **Compositor config**: Check Hyprland configuration syntax
- **Environment variables**: Verify Wayland environment variables
- **Fallback to X11**: Temporarily use X11 for testing

### Power Management Issues (Laptops)

#### Battery and Thermal Problems
**Symptoms**: Poor battery life, overheating, throttling
**Diagnosis**:
```bash
# Check TLP status and configuration
tlp-stat -s
tlp-stat -b  # Battery information
tlp-stat -t  # Temperature information

# Monitor CPU frequency and temperature
watch -n 1 "cat /proc/cpuinfo | grep MHz; sensors"

# Check power consumption
powertop
```

**Solutions**:
- **TLP configuration**: Adjust TLP settings in `modules/nixos/laptop.nix`
- **CPU governors**: Configure appropriate CPU frequency governors
- **Thermal management**: Check thermal-related kernel modules
- **Hardware issues**: Verify fan operation and thermal paste condition

#### WiFi and Bluetooth Issues
**Symptoms**: No connectivity, poor signal, connection drops
**Diagnosis**:
```bash
# Check network interfaces
ip link show
nmcli device status

# Check WiFi drivers
lspci | grep -i network
lsmod | grep iwl

# Bluetooth status
bluetoothctl show
systemctl status bluetooth
```

**Solutions**:
- **Driver updates**: Ensure latest wireless drivers installed
- **Firmware**: Install appropriate firmware packages
- **Power management**: Disable USB/wireless power management if needed
- **Hardware switches**: Check physical wireless switches on laptop

## Service and System Issues

### SystemD Service Problems

#### Service Startup Failures
**Symptoms**: Services fail to start, boot hangs, system instability
**Diagnosis**:
```bash
# Check failed services
systemctl --failed

# Check service status and logs
systemctl status service-name
journalctl -u service-name -f

# Check service dependencies
systemctl list-dependencies service-name
```

**Solutions**:
- **Dependencies**: Ensure proper service dependencies defined
- **Timing issues**: Adjust service startup timing and ordering
- **Configuration**: Verify service configuration files
- **Permissions**: Check file permissions and ownership

#### Boot Process Issues
**Symptoms**: Long boot times, hanging during boot, service timeouts
**Diagnosis**:
```bash
# Analyze boot performance
systemd-analyze blame
systemd-analyze critical-chain

# Check boot logs
journalctl -b
systemd-analyze plot > bootchart.svg
```

**Solutions**:
- **Service optimization**: Disable unnecessary services
- **Parallel startup**: Configure services for parallel startup
- **Dependencies**: Optimize service dependency chains
- **Hardware issues**: Check for failing hardware components

### Network and Connectivity Issues

#### NetworkManager Problems
**Symptoms**: No network connectivity, DNS issues, connection failures
**Diagnosis**:
```bash
# Check NetworkManager status
nmcli general status
nmcli device show

# Check network configuration
cat /etc/NetworkManager/NetworkManager.conf
systemctl status NetworkManager
```

**Solutions**:
- **Service restart**: Restart NetworkManager service
- **Configuration reset**: Reset network configuration
- **DNS configuration**: Check and fix DNS settings
- **Firewall**: Verify firewall isn't blocking connections

#### SSH and Remote Access Issues
**Symptoms**: Cannot connect via SSH, authentication failures
**Diagnosis**:
```bash
# Check SSH service
systemctl status sshd
journalctl -u sshd -f

# Test SSH configuration
sshd -t
ssh -vvv user@localhost
```

**Solutions**:
- **SSH keys**: Verify SSH key configuration and permissions
- **Firewall**: Check firewall rules for SSH port
- **Authentication**: Review SSH authentication methods
- **Network**: Verify network connectivity and routing

## Storage and Filesystem Issues

### ZFS-Specific Problems

#### Pool Health Issues
**Symptoms**: Degraded pools, checksum errors, performance issues
**Diagnosis**:
```bash
# Check pool health
zpool status -v
zpool list -v

# Check for errors
zpool events -v
dmesg | grep -i zfs
```

**Solutions**:
- **Scrub pools**: Run `zpool scrub rpool` to check data integrity
- **Replace devices**: Replace failing drives in pool
- **Clear errors**: Use `zpool clear` for transient errors
- **Import/export**: Try pool export/import cycle

#### Snapshot and Dataset Issues
**Symptoms**: Cannot create snapshots, rollback failures, mount issues
**Diagnosis**:
```bash
# List snapshots and datasets
zfs list -t snapshot
zfs list -o space

# Check dataset properties
zfs get all dataset-name
```

**Solutions**:
- **Space issues**: Free up space or increase pool size
- **Permissions**: Check dataset permissions and ownership
- **Mount points**: Verify dataset mount point configuration
- **Snapshot cleanup**: Remove old snapshots to free space

### Impermanence Issues

#### Persistent State Problems
**Symptoms**: Configuration lost after reboot, missing files
**Diagnosis**:
```bash
# Check persistence configuration
cat /etc/nixos/modules/nixos/impermanence.nix
ls -la /persist/

# Check bind mounts
mount | grep persist
systemctl status create-needed-for-boot-dirs.service
```

**Solutions**:
- **Add persistence**: Add missing files/directories to persistence config
- **Fix permissions**: Correct ownership and permissions in `/persist`
- **Service issues**: Fix bind mount service configuration
- **Manual recovery**: Manually copy important files to `/persist`

## Performance and Optimization Issues

### System Performance Problems

#### High Memory Usage
**Symptoms**: System slowdown, OOM kills, excessive swapping
**Diagnosis**:
```bash
# Check memory usage
free -h
htop
ps aux --sort=-%mem | head -20

# Check ZFS ARC usage
arc_summary
```

**Solutions**:
- **ZFS ARC tuning**: Limit ZFS ARC size with kernel parameters
- **Service optimization**: Identify and optimize memory-heavy services
- **Swap configuration**: Configure appropriate swap size and priority
- **Memory leaks**: Identify and fix applications with memory leaks

#### Disk I/O Issues
**Symptoms**: High disk usage, slow file operations, system lag
**Diagnosis**:
```bash
# Monitor disk I/O
iotop
iostat -x 1

# Check ZFS I/O
zpool iostat -v 1
```

**Solutions**:
- **ZFS optimization**: Tune ZFS parameters for workload
- **Disk health**: Check disk health with SMART tools
- **Filesystem tuning**: Optimize filesystem parameters
- **Storage upgrade**: Consider faster storage solutions

### Network Performance Issues

#### Slow Network Performance
**Symptoms**: Slow downloads, high latency, connection timeouts
**Diagnosis**:
```bash
# Test network speed
iperf3 -c server-address
speedtest-cli

# Check network statistics
netstat -i
ss -s
```

**Solutions**:
- **Driver optimization**: Update network drivers and firmware
- **TCP tuning**: Optimize TCP buffer sizes and parameters
- **DNS optimization**: Use faster DNS servers
- **QoS configuration**: Configure Quality of Service settings

## Recovery and Backup Procedures

### Data Recovery

#### Accidental File Deletion
1. **Check ZFS snapshots**:
   ```bash
   zfs list -t snapshot | grep recent
   zfs mount snapshot-name /mnt/recovery
   ```

2. **Restore from snapshots**:
   ```bash
   cp -a /mnt/recovery/path/to/file /original/location
   ```

3. **Rollback dataset** (if recent):
   ```bash
   zfs rollback dataset@snapshot-name
   ```

#### System Configuration Recovery
1. **Identify working generation**:
   ```bash
   ls -la /nix/var/nix/profiles/system*
   ```

2. **Rollback configuration**:
   ```bash
   nixos-rebuild switch --rollback
   # Or specific generation:
   /nix/var/nix/profiles/system-N-link/bin/switch-to-configuration switch
   ```

3. **Recover from git history**:
   ```bash
   git log --oneline
   git checkout commit-hash -- file-to-recover
   ```

### Backup and Restore Procedures

#### Create System Backup
```bash
# Create comprehensive snapshot
zfs snapshot rpool@backup-$(date +%Y%m%d)

# Send to remote location
zfs send rpool@backup-date | ssh backup-server 'zfs receive backup-pool/system'

# Backup configuration repository
git bundle create nixos-config-backup.bundle --all
```

#### Restore from Backup
```bash
# Restore ZFS from remote
ssh backup-server 'zfs send backup-pool/system@snapshot' | zfs receive rpool-restore

# Restore configuration
git clone nixos-config-backup.bundle nixos-restored
```

This comprehensive troubleshooting guide should help agents diagnose and resolve most common issues they might encounter while working with the NixOS configuration.