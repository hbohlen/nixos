# NixOS Configuration Troubleshooting Guide

## Table of Contents
- [Overview](#overview)
- [Quick Reference Commands](#quick-reference-commands)
- [Emergency Recovery Procedures](#emergency-recovery-procedures)
- [Build and Configuration Issues](#build-and-configuration-issues)
- [Home Manager Issues](#home-manager-issues)
- [Installation Troubleshooting](#installation-troubleshooting)
- [Hardware and Driver Issues](#hardware-and-driver-issues)
- [System and Service Problems](#system-and-service-problems)
- [ZFS and Storage Issues](#zfs-and-storage-issues)
- [Network and Connectivity Problems](#network-and-connectivity-problems)
- [Performance and Optimization](#performance-and-optimization)
- [Security and Recovery](#security-and-recovery)
- [Debugging Techniques](#debugging-techniques)
- [Advanced Diagnostic Tools](#advanced-diagnostic-tools)

## Overview

This comprehensive troubleshooting guide provides step-by-step procedures for diagnosing and resolving common issues in the NixOS configuration. It covers system-level problems, module-specific issues, recovery procedures, and debugging techniques.

The guide is organized from critical emergency procedures to specific troubleshooting scenarios, with diagnostic commands and solutions for each category.

## Quick Reference Commands

### System Status and Diagnostics
```bash
# Check system status
systemctl status
systemctl --failed
journalctl -f                    # Follow system logs
journalctl -u service-name       # Service-specific logs
journalctl -b                    # Boot logs
journalctl -p err                # Error-level logs only

# NixOS configuration
nix flake check                  # Validate flake syntax
nixos-rebuild build --flake .#hostname  # Test build without activation
nixos-rebuild dry-activate --flake .#hostname  # Preview changes

# System information
nixos-version                    # NixOS version info
nix-info -m                      # Detailed system info
lspci                           # PCI devices
lsusb                           # USB devices
dmesg | tail -50                # Kernel messages
```

### ZFS and Storage
```bash
# ZFS status
zpool status                     # Pool health
zfs list                        # Dataset listing
zpool list                      # Pool usage
zpool events -v                 # Pool events
zfs get all                     # All properties

# Disk and filesystem
lsblk -f                        # Block devices with filesystems
df -h                           # Disk usage
findmnt                         # Mounted filesystems
cryptsetup status               # LUKS status
```

### Network Diagnostics
```bash
# Network status
ip addr show                    # Interface addresses
ip route show                   # Routing table
nmcli device status            # NetworkManager status
ss -tuln                       # Open ports
ping -c4 8.8.8.8              # Connectivity test
```

## Emergency Recovery Procedures

### Boot Recovery (System Won't Boot)

#### 1. Boot from NixOS Live Environment
```bash
# Boot from NixOS installation medium
# Select "NixOS live environment" from boot menu
sudo -i  # Switch to root
```

#### 2. Unlock Encrypted Storage (LUKS)
```bash
# List available block devices
lsblk

# Unlock LUKS encryption (adjust device path)
cryptsetup luksOpen /dev/nvme0n1p2 cryptroot

# Verify LUKS container is open
ls -la /dev/mapper/
```

#### 3. Import ZFS Pool
```bash
# Import the ZFS pool
zpool import rpool

# If pool won't import normally, force import
zpool import -f rpool

# Check pool status
zpool status rpool
```

#### 4. Mount Filesystems
```bash
# Create mount point
mkdir -p /mnt

# Mount root filesystem
mount /dev/mapper/rpool-local-root /mnt

# Mount boot partition (EFI)
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot

# Mount persistent storage
mkdir -p /mnt/persist
mount /dev/mapper/rpool-safe-persist /mnt/persist

# Verify mounts
findmnt /mnt
```

#### 5. Enter Recovery Environment
```bash
# Bind mount system directories
for dir in dev proc sys run; do
  mount --bind /$dir /mnt/$dir
done

# Enter chroot environment
chroot /mnt /bin/bash

# Source environment
source /etc/profile
```

#### 6. System Recovery Options

**Rollback to Previous Generation:**
```bash
# List available generations
nix-env -p /nix/var/nix/profiles/system --list-generations

# Rollback to previous generation
nixos-rebuild switch --rollback

# Or activate specific generation
/nix/var/nix/profiles/system-42-link/bin/switch-to-configuration switch
```

**Emergency ZFS Rollback:**
```bash
# List snapshots
zfs list -t snapshot rpool/local/root

# Rollback to blank snapshot (nuclear option)
zfs rollback -r -f rpool/local/root@blank

# Or rollback to specific snapshot
zfs rollback rpool/local/root@snapshot-name
```

**Exit Recovery Environment:**
```bash
# Exit chroot
exit

# Unmount filesystems
umount -R /mnt

# Export ZFS pool
zpool export rpool

# Close LUKS container
cryptsetup luksClose cryptroot

# Reboot
reboot
```

### Emergency Boot Options

#### Accessing GRUB Menu
```bash
# During boot, press and hold Shift or Esc to access GRUB menu
# Select an older generation from the menu
# Or press 'e' to edit boot parameters temporarily
```

#### Boot with Single User Mode
```bash
# In GRUB, edit the kernel line and add:
systemd.unit=rescue.target

# Or for even more minimal boot:
systemd.unit=emergency.target
```

## Build and Configuration Issues

**Using the Enhanced Rebuild Script:**
The repository includes an enhanced `scripts/rebuild.sh` script with comprehensive error handling and debugging options:

```bash
# Use the enhanced rebuild script for better error reporting
./scripts/rebuild.sh --verbose     # Detailed output for debugging
./scripts/rebuild.sh dry-run       # Preview changes without building
./scripts/rebuild.sh build         # Build without activation (safer testing)
./scripts/rebuild.sh --rollback    # Emergency rollback to previous generation
./scripts/rebuild.sh --help        # Show all available options
```

### Flake Configuration Problems

#### Flake Check Failures
**Symptoms:** `nix flake check` fails with syntax or evaluation errors

**Diagnosis:**
```bash
# Check flake syntax with detailed errors
nix flake check --show-trace

# Evaluate specific outputs
nix eval .#nixosConfigurations.hostname.config.system.build.toplevel

# Check flake inputs
nix flake metadata
nix flake lock --update-input nixpkgs  # Update specific input
```

**Solutions:**
- **Syntax Errors:** Fix Nix syntax in configuration files
- **Missing Imports:** Verify all module imports exist and are correct
- **Option Conflicts:** Resolve conflicting option definitions using `lib.mkForce`
- **Type Errors:** Ensure options have correct types and values

#### Module Import Errors
**Symptoms:** Module not found or import path errors

**Diagnosis:**
```bash
# Trace module evaluation
nix eval --show-trace .#nixosConfigurations.hostname.config.imports

# Check file existence
ls -la modules/nixos/module-name.nix
```

**Solutions:**
```nix
# Use correct relative paths
imports = [
  ./hardware/disko-zfs.nix
  ../../modules/nixos/desktop.nix
];

# Ensure module files exist and are properly structured
{ config, pkgs, lib, inputs, ... }:
{
  # Module content
}
```

### Build Failures

#### Package Build Errors
**Symptoms:** Package compilation failures, missing dependencies

**Diagnosis:**
```bash
# Build specific package to isolate issue
nix build nixpkgs#package-name

# Check build logs
nix log /nix/store/hash-package-name

# Search for available packages
nix search nixpkgs package-name

# Check package info
nix eval nixpkgs#package-name.meta
```

**Solutions:**
- **Update Packages:** Run `nix flake update` to update package versions
- **Check Availability:** Verify package exists in current nixpkgs version
- **Alternative Packages:** Use alternative packages or build from source
- **Overlays:** Create package overlay if custom build needed

#### Dependency Conflicts
**Symptoms:** Conflicting package versions or missing dependencies

**Diagnosis:**
```bash
# Check dependency tree
nix why-depends /run/current-system package-name

# Show dependency graph
nix-store --query --graph /run/current-system | dot -Tpng > deps.png
```

**Solutions:**
```nix
# Use nixpkgs overlays for version conflicts
nixpkgs.overlays = [
  (final: prev: {
    package-name = prev.package-name.overrideAttrs (old: {
      version = "specific-version";
    });
  })
];

# Pin specific packages
environment.systemPackages = with pkgs; [
  (package-name.override { dependency = specific-version; })
];
```

#### Memory Issues During Build
**Symptoms:** Build fails with out-of-memory errors

**Solutions:**
```bash
# Increase swap space temporarily
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Build with fewer parallel jobs
nixos-rebuild build --flake .#hostname --option max-jobs 1

# Use remote builder or binary cache
```

## Home Manager Issues

### Home Manager Build Failures

#### Configuration Conflicts
**Symptoms:** Home Manager build fails with option conflicts or type errors

**Diagnosis:**
```bash
# Build Home Manager configuration separately
home-manager build

# Check Home Manager configuration
home-manager edit

# Debug specific module
nix eval --show-trace .#homeConfigurations.username.config.programs.module-name
```

**Solutions:**
```nix
# Resolve option conflicts with proper priorities
programs.git = {
  enable = true;
  userName = lib.mkDefault "default-name";  # Lower priority
  userEmail = lib.mkForce "forced@email.com";  # Higher priority
};

# Check for duplicate module imports
imports = [
  # Remove duplicate imports
  ./modules/git.nix  # Keep only one
];
```

#### Service Activation Failures
**Symptoms:** Home Manager services fail to start or activate

**Diagnosis:**
```bash
# Check Home Manager services
systemctl --user status
systemctl --user --failed

# Check specific service
systemctl --user status service-name
journalctl --user -u service-name

# Test service manually
systemctl --user restart service-name
```

**Solutions:**
```bash
# Reload user services
systemctl --user daemon-reload

# Reset failed services
systemctl --user reset-failed

# Check service dependencies
systemctl --user list-dependencies service-name
```

#### Package Installation Issues
**Symptoms:** Home Manager packages don't install or aren't available

**Diagnosis:**
```bash
# Check package availability
nix search nixpkgs package-name

# Build specific package
nix build nixpkgs#package-name

# Check package derivation
nix show-derivation nixpkgs#package-name
```

**Solutions:**
- Update nixpkgs input: `nix flake update nixpkgs`
- Use unfree packages configuration if needed
- Check package name spelling and availability
- Use package overlays for custom versions

### Home Manager State Issues

#### Profile Corruption
**Symptoms:** Home Manager can't switch generations or profile is corrupted

**Diagnosis:**
```bash
# Check Home Manager generations
home-manager generations

# List profiles
nix-env --list-generations --profile ~/.local/state/nix/profiles/home-manager

# Check profile link
ls -la ~/.nix-profile
```

**Solutions:**
```bash
# Remove corrupted profile
rm ~/.local/state/nix/profiles/home-manager*

# Rebuild Home Manager profile
home-manager switch

# Or rollback to previous generation
home-manager switch --rollback
```

#### Dotfile Conflicts
**Symptoms:** Configuration files conflict with existing dotfiles

**Diagnosis:**
```bash
# Check for conflicting files
ls -la ~/.config/
ls -la ~/.bashrc ~/.zshrc

# Find Home Manager managed files
find ~/.nix-profile/home-files -type f
```

**Solutions:**
```bash
# Backup existing dotfiles
mkdir ~/dotfiles-backup
mv ~/.config/conflicting-config ~/dotfiles-backup/

# Or use Home Manager's backup feature
home-manager switch --backup-extension .backup
```

## Installation Troubleshooting

### Installation Script Errors

#### Script-Based Installation Issues
**Reference:** The repository includes comprehensive installation scripts with built-in error handling. See `scripts/install.sh` for the full installation automation.

**Common Script Errors:**

#### Disk Detection Issues
**Symptoms:** Script can't find target disk or wrong disk selected

**Diagnosis:**
```bash
# List all block devices
lsblk -f

# Show disk details
fdisk -l

# Check disk by ID (more reliable)
ls -la /dev/disk/by-id/

# Check disk model and serial
hdparm -i /dev/sdX
```

**Solutions:**
- Update `INSTALL_DISK_DEVICE` environment variable
- Use disk by-id path for reliability: `/dev/disk/by-id/nvme-Samsung_SSD_980_1TB_*`
- Verify disk is not mounted before installation

#### LUKS Setup Failures
**Symptoms:** Encryption setup fails or password issues

**Diagnosis:**
```bash
# Check if LUKS header exists
cryptsetup luksDump /dev/sdX2

# Test LUKS unlock
cryptsetup luksOpen /dev/sdX2 test-crypt

# Check available LUKS slots
cryptsetup luksDump /dev/sdX2 | grep "Key Slot"
```

**Solutions:**
```bash
# Wipe existing LUKS header if corrupted
cryptsetup luksErase /dev/sdX2

# Create new LUKS container
cryptsetup luksFormat /dev/sdX2

# Add backup key slot
cryptsetup luksAddKey /dev/sdX2
```

#### ZFS Pool Creation Issues
**Symptoms:** ZFS pool creation fails or import errors

**Diagnosis:**
```bash
# Check if pool already exists
zpool list
zpool status

# Check for pool on different devices
zpool import

# Force import if pool was exported improperly
zpool import -f rpool

# Check ZFS module loading
lsmod | grep zfs
```

**Solutions:**
```bash
# Destroy existing pool if needed
zpool destroy rpool

# Export pool before recreating
zpool export rpool

# Create pool with force flag
zpool create -f rpool /dev/mapper/cryptroot
```

### Disko Configuration Issues

#### Partition Layout Errors
**Symptoms:** Disko fails to create partitions as specified

**Diagnosis:**
```bash
# Check current partition table
parted /dev/sdX print

# Validate disko configuration
nix eval .#nixosConfigurations.hostname.config.disko.devices

# Test disko in dry-run mode (if available)
disko --dry-run --mode disko ./hosts/hostname/hardware/disko-layout.nix
```

**Solutions:**
- Ensure disk is completely unmounted before running disko
- Check device path in disko configuration matches actual hardware
- Use `wipefs -a /dev/sdX` to clear existing filesystem signatures

### Mount Point Issues
**Symptoms:** Filesystems don't mount or wrong mount options

**Diagnosis:**
```bash
# Check mount status
findmnt
mount | grep rpool

# Test manual mounting
mount -t zfs rpool/local/root /mnt

# Check filesystem options
zfs get all rpool/local/root
```

**Solutions:**
- Verify ZFS mountpoint properties are correct
- Check /etc/fstab for conflicting entries
- Ensure required directories exist before mounting

## Hardware and Driver Issues

### Graphics and Display Problems

#### NVIDIA Driver Issues
**Symptoms:** No graphics acceleration, black screen, or display artifacts

**Diagnosis:**
```bash
# Check NVIDIA driver loading
lsmod | grep nvidia
nvidia-smi

# Check graphics capabilities
glxinfo | grep -i renderer
vulkaninfo | head -20

# Check X11/Wayland logs
journalctl -u display-manager
cat /var/log/Xorg.0.log | grep -i error
```

**Solutions:**
```nix
# In configuration.nix
services.xserver.videoDrivers = [ "nvidia" ];
hardware.nvidia = {
  modesetting.enable = true;
  powerManagement.enable = true;
  open = false;  # Use proprietary driver
  nvidiaSettings = true;
  package = config.boot.kernelPackages.nvidiaPackages.stable;
};

# For hybrid graphics (laptop)
hardware.nvidia.prime = {
  sync.enable = true;
  intelBusId = "PCI:0:2:0";
  nvidiaBusId = "PCI:1:0:0";
};
```

#### Wayland/Hyprland Issues
**Symptoms:** Compositor crashes, display artifacts, input problems

**Diagnosis:**
```bash
# Check Hyprland logs
journalctl --user -u hyprland

# Test compositor directly
Hyprland --config /dev/null

# Check Wayland environment
echo $WAYLAND_DISPLAY
echo $XDG_SESSION_TYPE

# Check graphics capabilities
glxinfo | grep -i renderer
```

**Solutions:**
```nix
# Environment variables for Hyprland
environment.sessionVariables = {
  WLR_NO_HARDWARE_CURSORS = "1";  # For NVIDIA
  NIXOS_OZONE_WL = "1";           # For Electron apps
};

# NVIDIA-specific settings
hardware.nvidia.modesetting.enable = true;
```

### Audio Issues

#### PipeWire/ALSA Problems
**Symptoms:** No audio output, incorrect device selection

**Diagnosis:**
```bash
# Check audio devices
pactl list sinks
aplay -l
lspci | grep -i audio

# Check PipeWire status
systemctl --user status pipewire
systemctl --user status wireplumber

# Test audio output
speaker-test -t sine -f 1000 -l 1
```

**Solutions:**
```nix
# Enable PipeWire
security.rtkit.enable = true;
services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;
  pulse.enable = true;
  jack.enable = true;
};
```

### Power Management Issues (Laptops)

#### Battery and Thermal Management
**Symptoms:** Poor battery life, overheating, throttling

**Diagnosis:**
```bash
# Check power profiles
powerprofilesctl list
powerprofilesctl get

# Monitor power consumption
powertop

# Check thermal status
cat /sys/class/thermal/thermal_zone*/temp
sensors

# Check CPU frequency scaling
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
cpupower frequency-info
```

**Solutions:**
```nix
# Power management
services.power-profiles-daemon.enable = true;
services.thermald.enable = true;
powerManagement.enable = true;
powerManagement.cpuFreqGovernor = "powersave";

# For Intel CPUs
services.auto-cpufreq.enable = true;

# For AMD CPUs
boot.kernelModules = [ "amd-pstate" ];
boot.kernelParams = [ "amd_pstate=passive" ];
```

#### WiFi and Bluetooth Issues
**Symptoms:** No connectivity, poor signal, connection drops

**Diagnosis:**
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

# Check firmware loading
dmesg | grep -i firmware
```

**Solutions:**
```nix
# WiFi firmware
hardware.enableRedistributableFirmware = true;

# Bluetooth
hardware.bluetooth.enable = true;
hardware.bluetooth.powerOnBoot = true;

# Specific WiFi drivers
boot.extraModulePackages = with config.boot.kernelPackages; [
  rtl8814au  # Example for specific USB WiFi adapter
];
```

## System and Service Problems

### SystemD Service Issues

#### Service Startup Failures
**Symptoms:** Services fail to start or crash immediately

**Diagnosis:**
```bash
# Check service status
systemctl status service-name
systemctl --failed

# View service logs
journalctl -u service-name
journalctl -u service-name -f  # Follow logs

# Check service dependencies
systemctl list-dependencies service-name

# Test service manually
systemd-analyze verify service-name.service
```

**Solutions:**
```bash
# Restart failed services
systemctl restart service-name

# Reset failed state
systemctl reset-failed service-name

# Edit service temporarily
systemctl edit service-name

# Reload systemd configuration
systemctl daemon-reload
```

#### Boot Process Issues
**Symptoms:** Slow boot, services timeout, boot hangs

**Diagnosis:**
```bash
# Analyze boot performance
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain

# Check boot logs
journalctl -b
journalctl -b -p err

# Plot boot timeline
systemd-analyze plot > boot-chart.svg
```

**Solutions:**
- Disable unnecessary services at boot
- Increase service timeouts if needed
- Check for hardware detection delays
- Use `systemd-analyze` to identify bottlenecks

## ZFS and Storage Issues

### ZFS Pool Health Problems

#### Pool Degradation and Errors
**Symptoms:** Pool shows DEGRADED status, checksum errors

**Diagnosis:**
```bash
# Check detailed pool status
zpool status -v
zpool list -v

# Check pool events
zpool events -v
zpool history

# Check for disk errors
dmesg | grep -i error
smartctl -a /dev/sdX
```

**Solutions:**
```bash
# Scrub the pool
zpool scrub rpool

# Clear transient errors
zpool clear rpool

# Replace failed device
zpool replace rpool /dev/old-disk /dev/new-disk

# Check scrub progress
zpool status
```

#### Dataset Mount Issues
**Symptoms:** ZFS datasets won't mount or wrong mountpoints

**Diagnosis:**
```bash
# Check dataset properties
zfs get all dataset-name
zfs get mountpoint dataset-name

# List all datasets
zfs list -r rpool

# Check mount status
zfs mount  # Show mounted datasets
```

**Solutions:**
```bash
# Set correct mountpoint
zfs set mountpoint=/desired/path dataset-name

# Force mount dataset
zfs mount dataset-name

# Unmount and remount
zfs umount dataset-name
zfs mount dataset-name
```

### Impermanence Issues

#### Persistent Data Problems
**Symptoms:** Data lost after reboot, configurations not persisting

**Diagnosis:**
```bash
# Check persistent directories
ls -la /persist
df -h /persist

# Check impermanence configuration
cat /etc/nixos/modules/nixos/impermanence.nix

# Verify symlinks
ls -la /etc/nixos
ls -la ~/.config
```

**Solutions:**
- Ensure critical directories are in `/persist`
- Check impermanence module configuration
- Verify bind mounts are working
- Add missing directories to persistence configuration

## Network and Connectivity Problems

### NetworkManager Issues

#### Connection Failures
**Symptoms:** No network connectivity, DNS resolution fails

**Diagnosis:**
```bash
# Check NetworkManager status
nmcli general status
nmcli device show

# Check connections
nmcli connection show
nmcli connection show --active

# DNS resolution
nslookup google.com
dig google.com
cat /etc/resolv.conf
```

**Solutions:**
```bash
# Restart NetworkManager
systemctl restart NetworkManager

# Reset network configuration
nmcli connection delete connection-name
nmcli device disconnect interface-name
nmcli device connect interface-name

# Fix DNS issues
nmcli connection modify connection-name ipv4.dns "8.8.8.8,1.1.1.1"
```

#### WiFi Problems
**Symptoms:** Cannot connect to WiFi, authentication issues

**Diagnosis:**
```bash
# Scan for networks
nmcli device wifi list

# Check WiFi interface status
iw dev
iwconfig

# Check authentication
wpa_supplicant -i wlan0 -c /etc/wpa_supplicant.conf -d
```

**Solutions:**
```bash
# Connect to WiFi
nmcli device wifi connect "SSID" password "password"

# Forget and reconnect
nmcli connection delete "connection-name"
nmcli device wifi connect "SSID" password "password"
```

### SSH and Remote Access Issues

#### SSH Service Problems
**Symptoms:** Cannot connect via SSH, authentication failures

**Diagnosis:**
```bash
# Check SSH service status
systemctl status sshd

# Check SSH configuration
sshd -T  # Test configuration
ssh -vvv user@host  # Verbose connection attempt

# Check firewall
iptables -L
nft list ruleset
```

**Solutions:**
```nix
# Enable SSH service
services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "no";
  };
  ports = [ 22 ];
};

# Configure firewall
networking.firewall.allowedTCPPorts = [ 22 ];
```

## Performance and Optimization

### System Performance Issues

#### High Memory Usage
**Symptoms:** System slowness, OOM kills, swap usage

**Diagnosis:**
```bash
# Check memory usage
free -h
top
htop

# Check for memory leaks
ps aux --sort=-%mem | head
systemd-cgtop

# Check swap usage
swapon -s
cat /proc/swaps
```

**Solutions:**
- Increase swap space
- Identify memory-hungry processes
- Configure systemd service memory limits
- Enable zswap for better memory compression

#### Disk I/O Bottlenecks
**Symptoms:** High I/O wait times, slow filesystem operations

**Diagnosis:**
```bash
# Monitor I/O
iotop
iostat -x 1

# Check disk usage
df -h
du -sh /*

# ZFS ARC statistics
arc_summary.py
cat /proc/spl/kstat/zfs/arcstats
```

**Solutions:**
- Tune ZFS ARC size
- Use faster storage devices
- Optimize ZFS dataset properties
- Configure appropriate recordsize for workload

## Security and Recovery

### Security Auditing

#### System Security Checks
```bash
# Check for security updates
nixos-rebuild build --upgrade

# Audit system files
aide --check

# Check open ports
ss -tuln
nmap localhost

# Check running processes
ps auxf
systemctl list-units --type=service --state=running
```

#### Log Analysis
```bash
# Check authentication logs
journalctl -u systemd-logind
last
w

# Check failed login attempts
journalctl | grep "Failed password"

# System integrity
debsums -c  # If available
```

### Backup and Recovery

#### Configuration Backup
```bash
# Backup NixOS configuration
tar -czf nixos-config-$(date +%Y%m%d).tar.gz /etc/nixos

# Backup ZFS datasets
zfs send rpool/safe/home@snapshot | gzip > home-backup.gz

# Create system snapshot
zfs snapshot rpool/local/root@backup-$(date +%Y%m%d)
```

#### Emergency Access
```bash
# Add temporary user with sudo access
useradd -m -G wheel emergency-user
passwd emergency-user

# Reset user password from rescue mode
passwd username

# Enable emergency SSH access (temporarily)
systemctl edit sshd
# Add:
# [Service]
# ExecStart=
# ExecStart=/usr/bin/sshd -D -o PermitRootLogin=yes
```

## Debugging Techniques

### Advanced Debugging Tools

#### System Tracing
```bash
# Trace system calls
strace -f -p PID

# Network debugging
tcpdump -i interface
wireshark

# Kernel debugging
dmesg -w
cat /proc/kmsg
```

#### NixOS-Specific Debugging
```bash
# Show derivation dependencies
nix show-derivation /nix/store/hash-package

# Debug build issues
nix build --keep-failed package-name
# Check /tmp/nix-build-* directories

# Profile evaluation performance
nix eval --json .#nixosConfigurations.hostname.config 2>&1 | grep "evaluating"
```

### Performance Profiling
```bash
# System performance
perf top
perf record -g command
perf report

# Memory profiling
valgrind --tool=massif command
heaptrack command

# Boot performance
bootchart2
systemd-analyze plot
```

### Environment Testing
```bash
# Test configuration changes safely
nixos-rebuild build --flake .#hostname
nixos-rebuild test --flake .#hostname  # Temporary activation

# Create test environment
nix-shell -p package1 package2

# Test in VM
nixos-rebuild build-vm --flake .#hostname
```

## Advanced Diagnostic Tools

### System Information and Analysis

#### System Info Tools
```bash
# Comprehensive system information
nix run nixpkgs#neofetch
nix run nixpkgs#uwufetch  # Alternative system info

# Hardware information
lshw -short
inxi -Fxz
hwinfo --short

# CPU and memory details
cat /proc/cpuinfo
cat /proc/meminfo
lscpu
free -h --si
```

#### Nix Store Analysis
```bash
# Analyze Nix store usage
nix path-info -rSh /run/current-system | sort -nk2
du -sh /nix/store

# Find largest store paths
nix path-info -rS /run/current-system | sort -nk2 | tail -20

# Check store integrity
nix store verify --all
nix store repair --all
```

#### Dependency Analysis
```bash
# Show package dependencies
nix why-depends /run/current-system package-name

# Generate dependency graph
nix-store --query --graph /run/current-system > deps.dot
dot -Tpng deps.dot > dependencies.png

# Show reverse dependencies
nix-store --query --referrers /nix/store/hash-package
```

### Emergency Access and Recovery

#### Emergency Mode Access
**Configure emergency access in initrd:**
```nix
# In configuration.nix
boot.initrd.systemd.emergencyAccess = true;  # Unauthenticated access
# Or for authenticated access:
boot.initrd.systemd.emergencyAccess = "$6$hashed$password";

# Enable emergency mode for failed mounts
systemd.enableEmergencyMode = true;
```

**Access emergency mode:**
```bash
# During boot failure, you'll be dropped into emergency shell
# Or force emergency mode by adding to kernel parameters:
systemd.unit=emergency.target

# In emergency mode:
systemctl list-units --failed
journalctl -xb
mount -o remount,rw /
```

#### Crash Dump Analysis
```nix
# Enable crash dumps in configuration
boot.crashDump.enable = true;
```

```bash
# After a crash, analyze dump
crash /proc/vmcore /boot/vmlinux
# Or
makedumpfile -l /proc/vmcore
```

### Performance Analysis Tools

#### System Performance Monitoring
```bash
# Real-time system monitoring
htop
iotop
nethogs  # Network usage per process
iftop    # Network bandwidth usage

# System call tracing
strace -f -p PID
ltrace command  # Library call tracing

# Performance profiling
perf top
perf record -g command
perf report
```

#### Boot Performance Analysis
```bash
# Detailed boot analysis
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain
systemd-analyze plot > boot-chart.svg

# Service startup times
systemd-analyze time
systemd-analyze dump
```

#### Memory Analysis
```bash
# Memory usage breakdown
smem -tk
pmap -x PID
cat /proc/PID/smaps

# Memory leaks detection
valgrind --leak-check=full command
```

### Network Diagnostics

#### Advanced Network Analysis
```bash
# Network interface statistics
cat /proc/net/dev
ethtool interface-name

# Network connections and processes
netstat -tulnp
ss -tulnp

# Network packet analysis
tcpdump -i interface -w capture.pcap
tshark -i interface -f "filter"
```

#### DNS and Connectivity Testing
```bash
# DNS resolution testing
dig domain.com
nslookup domain.com
host domain.com

# Connectivity testing
mtr domain.com  # Traceroute with statistics
traceroute domain.com
nc -zv host port  # Port testing
```

### Hardware Diagnostics

#### Hardware Health Monitoring
```bash
# Temperature and fan monitoring
sensors
watch -n1 sensors

# Disk health
smartctl -a /dev/sdX
badblocks -v /dev/sdX

# Memory testing (run from live environment)
memtest86+
# Or from running system:
memtester 1G 5  # Test 1GB memory 5 times
```

#### GPU Diagnostics
```bash
# NVIDIA GPU monitoring
nvidia-smi
watch -n1 nvidia-smi

# Intel GPU information
intel_gpu_top
cat /sys/kernel/debug/dri/0/i915_frequency_info

# AMD GPU monitoring
radeontop
cat /sys/class/drm/card0/device/power_state
```

### Log Analysis and Monitoring

#### Centralized Log Analysis
```bash
# Follow all system logs
journalctl -f

# Filter by service
journalctl -u service-name -f

# Filter by priority
journalctl -p err..alert

# Boot-specific logs
journalctl -b
journalctl -b -1  # Previous boot

# User session logs
journalctl --user

# Log statistics
journalctl --disk-usage
journalctl --vacuum-time=7d  # Clean logs older than 7 days
```

#### Custom Log Monitoring
```bash
# Monitor specific log files
tail -f /var/log/specific.log

# Search logs with context
grep -B5 -A5 "error pattern" /var/log/messages

# Real-time log filtering
journalctl -f | grep -i error
```

This troubleshooting guide provides comprehensive coverage of common NixOS issues and their solutions. Always start with the basic diagnostic commands and work through the solutions systematically. When in doubt, consult the NixOS manual and community resources for additional help.