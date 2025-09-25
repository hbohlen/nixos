# NixOS Configuration

A modern, declarative NixOS system configuration built on the "Erase Your Darlings" philosophy, featuring ephemeral root filesystem with selective persistence.

## Repository Overview

This repository provides a comprehensive NixOS configuration that combines several advanced technologies to create a robust, reproducible, and secure computing environment:

- **Ephemeral Root**: The root filesystem is reset to a pristine state on each boot
- **Selective Persistence**: Only explicitly chosen files and directories survive reboots
- **Declarative Everything**: From disk partitioning to application themes, everything is defined as code
- **Multi-Host Support**: Configurations for desktop, laptop, and server environments
- **Modern Desktop**: Hyprland Wayland compositor with integrated theming
- **Secret Management**: Runtime secret injection via 1Password integration

## Prerequisites

### Required NixOS Version
- NixOS 23.11 or later (configuration targets 25.05)
- Nix with flakes experimental feature enabled

### Required System Dependencies
- UEFI-compatible system (not BIOS/Legacy)
- At least 8GB RAM (for ZFS and desktop environment)
- Modern CPU with hardware encryption support (recommended)
- Internet connection for initial setup and package downloads

### Hardware Compatibility
- **CPU**: Intel processors (with latest microcode updates)
- **GPU**: Nvidia graphics cards (with proprietary driver support)
- **Laptop**: ASUS ROG Zephyrus M16 GU603ZW (or similar models)
- **Desktop**: MSI motherboards with Intel CPU + Nvidia GPU combinations
- **Memory**: Minimum 8GB RAM (ZFS ARC cache requires adequate memory)
- **Storage**: NVMe SSD recommended for optimal ZFS performance
- Works best with modern UEFI systems that have good Linux hardware support

## Installation from LiveISO

### Quick Installation (Recommended)

For a fully automated installation, you can use either method:

**Option 1: One-line web install**
```bash
# Boot from NixOS LiveISO and run:
sudo -i
curl -L https://raw.githubusercontent.com/hbohlen/nixos/main/scripts/bootstrap.sh | bash
```

**Option 2: Clone and install**
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
- Prompt for hostname, username, and target disk
- Handle disko partitioning with ZFS+LUKS
- Set up impermanence with persistent directories  
- Mount all filesystems correctly
- Install NixOS with your configuration
- Provide comprehensive error handling and cleanup

⚠️ **Warning**: This will destroy all data on the target disk!

### Manual Installation (Advanced)

For manual installation or troubleshooting, follow the detailed steps below.

### Prerequisites
- NixOS LiveISO (latest stable version)
- Internet connection  
- Target system with Intel CPU and Nvidia GPU
- At least 8GB RAM (for ZFS and desktop environment)
- UEFI-compatible system (not BIOS/Legacy)

### Step-by-Step Installation

#### 1. Boot from LiveISO
- Boot the target system from the NixOS LiveISO
- Select "NixOS" from the boot menu
- Wait for the system to reach the command line

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

# Example output shows stable identifiers:
# /dev/disk/by-id/nvme-Micron_2450_MTFDKBA1T0TFK_ABC123
# /dev/disk/by-id/ata-Samsung_SSD_870_QVO_1TB_S5XYYYY

# Set your target disk (replace with your actual disk ID)
export DISK=/dev/disk/by-id/nvme-YOUR_DISK_ID
```

#### 4. Clone Configuration Repository  
```bash
# Clone this repository
git clone https://github.com/hbohlen/nixos.git /tmp/nixos-config
cd /tmp/nixos-config
```

#### 5. Partition and Setup ZFS with Disko
```bash
# IMPORTANT: This will DESTROY all data on the target disk
# Double-check the device path before proceeding

# Run Disko to partition disk and create ZFS pool
sudo nix run --extra-experimental-features 'nix-command flakes' \
  github:nix-community/disko -- --mode disko \
  --argstr device "$DISK" \
  ./disko-layout.nix
```

#### 6. Verify ZFS Setup
```bash
# Verify the ZFS pool was created correctly
zpool status rpool
zfs list

# Check that filesystems are mounted
findmnt -t zfs
# You should see:
# /mnt                    rpool/local/root
# /mnt/nix               rpool/local/nix  
# /mnt/persist           rpool/safe/persist
# /mnt/home              rpool/safe/home
# /mnt/boot              /dev/disk/by-partlabel/disk-main-ESP (vfat)
```

#### 7. Copy Configuration to Target
```bash
# Copy the configuration to the target system
sudo cp -r /tmp/nixos-config/* /mnt/etc/nixos/
sudo chown -R root:root /mnt/etc/nixos
```

#### 8. Generate and Update Hardware Configuration
```bash
# Generate hardware configuration for your specific hardware
sudo nixos-generate-config --root /mnt --dir /tmp/hardware

# Copy relevant hardware details (but keep our custom configs)
# You may need to merge some hardware-specific settings
```

#### 9. Install NixOS
```bash
# Install the system (choose your hostname: desktop, laptop, or server)
sudo nixos-install --flake .#desktop

# If you see bootloader installation errors, ensure /mnt/boot is properly mounted:
# sudo mount /dev/disk/by-partlabel/disk-main-ESP /mnt/boot

# Set root password when prompted, then reboot
sudo reboot
```

#### 10. Post-Installation Verification
```bash
# After reboot, verify the ephemeral root system is working
# Root should be mounted from tmpfs or ZFS dataset
mount | grep "on / "

# Verify ZFS mounts are correct
zfs list
mount | grep zfs

# Check that persistent directories exist
ls -la /persist
ls -la /persist/etc/ssh  # SSH keys should be here

# Verify impermanence is working - root filesystem changes don't persist
sudo touch /test-file
sudo reboot
# After reboot, /test-file should be gone but /persist data remains
```

### Troubleshooting Installation

#### Common Issues and Solutions

**Bootloader Install Failed: `efiSysMountPoint = '/boot' is not a mounted partition`**
1. Re-run Disko to ensure partitions are created and mounted:
   ```bash
   sudo nix run --extra-experimental-features 'nix-command flakes' \
     github:nix-community/disko -- --mode disko \
     --argstr device "$DISK" ./disko-layout.nix
   ```

2. If already partitioned, just mount everything:
   ```bash
   sudo nix run --extra-experimental-features 'nix-command flakes' \
     github:nix-community/disko -- --mode mount \
     --argstr device "$DISK" ./disko-layout.nix
   ```

3. Verify mounts (you should see /mnt/boot):
   ```bash
   findmnt -R /mnt | grep -E '/mnt$|/mnt/(boot|nix|persist|home)'
   ```

4. If /mnt/boot is missing, mount ESP manually:
   ```bash
   sudo mkdir -p /mnt/boot
   sudo mount -o umask=0077 /dev/disk/by-partlabel/disk-main-ESP /mnt/boot
   ```

**ZFS Pool Import Failed**
```bash
# Force import the pool if it exists
sudo zpool import -f rpool

# If pool is degraded, check disk connections
zpool status rpool
```

**Build Failures**
```bash
# Check flake configuration
nix flake check

# Test build without installing
nixos-rebuild build --flake .#hostname

# For debugging, add --show-trace to see full error details
nixos-rebuild build --flake .#hostname --show-trace
```

### Hardware-Specific Notes

**For ASUS ROG Zephyrus M16 GU603ZW:**
- The configuration automatically imports nixos-hardware profile for gu603h (closest match)
- Nvidia/Intel hybrid graphics are configured
- ROG-specific features (keyboard backlight, power management) are enabled

**For MSI Desktop Systems:**
- Intel CPU microcode updates are enabled
- Nvidia proprietary drivers are configured
- General desktop hardware optimizations applied

## Installation/Usage (Alternative Quick Setup)

If you already have a working NixOS system, you can also use the simpler approach:

### Making Changes

1. **Clone this repository**:
   ```bash
   git clone https://github.com/hbohlen/nixos.git
   cd nixos
   ```

2. **Test your changes**:
   ```bash
   nixos-rebuild build --flake .#hostname
   ```

3. **Apply changes**:
   ```bash
   sudo nixos-rebuild switch --flake .#hostname
   ```
   Or use the convenient script:
   ```bash
   ./scripts/rebuild.sh
   ```

## Structure Overview

This configuration follows a modular architecture that promotes reusability and maintainability:

### Directory Structure

- **`flake.nix`** - Central entry point defining all inputs, outputs, and host configurations
- **`hosts/`** - Machine-specific configurations
  - `desktop/` - High-performance desktop with Intel/Nvidia hardware support
    - `hardware/` - Hardware-specific disk and device configurations
  - `laptop/` - Power-optimized portable configuration  
    - `hardware/` - Hardware-specific disk and device configurations
  - `server/` - Minimal headless server configuration
    - `hardware/` - Hardware-specific disk and device configurations
- **`modules/`** - Reusable configuration modules
  - `nixos/` - System-level modules (disk, impermanence, hardware, development)
  - `home-manager/` - User-level modules (desktop, applications)
- **`users/`** - Individual user account and Home Manager configurations
- **`scripts/`** - Utility scripts for system management and formatting
- **`secrets/`** - Placeholder for runtime secret injection (never commit actual secrets)
- **`docs/`** - Comprehensive documentation and troubleshooting guides

### Key Components

- **Disko Integration**: Declarative disk partitioning with ZFS on LUKS
- **Impermanence System**: Ephemeral root with selective persistence
- **Home Manager**: Declarative user environment management
- **Hyprland Desktop**: Modern Wayland compositor with integrated theming
- **Secret Management**: Runtime injection via Opnix and 1Password

## Customization Guide

### Hardware Configuration

Each host now has hardware-specific configurations in the `hardware/` subdirectory:

- **`disko-layout.nix`**: Host-specific disk partitioning and ZFS layout
- **`disko-zfs.nix`**: Disko module integration

**Important**: Update the device path in each host's `hardware/disko-layout.nix`:
```nix
{ device ? "/dev/disk/by-id/your-actual-disk-id", ... }:
```

Find your device ID with:
```bash
lsblk -f
ls -la /dev/disk/by-id/
```

### Development Tools

Development packages are now organized by host type:
- **Desktop/Laptop**: Include development tools via `development.enable = true`
- **Server**: No development tools by default (cleaner system)

The development module includes: gcc, clang, python3, nodejs, go, rust, and container support.

### Adding a New Host

1. **Create host directory**:
   ```bash
   mkdir -p hosts/new-hostname
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
       ../../modules/nixos/common.nix
       ../../modules/nixos/impermanence.nix
       ../../modules/nixos/disko-zfs.nix
     ];
     
     networking.hostName = "new-hostname";
     networking.hostId = "12345678"; # Unique 8-character hex
     
     # Add host-specific configuration here
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

### Adding New Modules

1. **System modules** go in `modules/nixos/`
2. **User modules** go in `modules/home-manager/`
3. **Follow existing patterns** for options and configuration structure
4. **Import modules** in appropriate host or user configurations

### Customizing Persistence

Edit `modules/nixos/impermanence.nix` to add files or directories that should survive reboots:

```nix
environment.persistence."/persist" = {
  directories = [
    # Add system directories here
    "/var/lib/your-service"
  ];
  files = [
    # Add system files here
    "/etc/your-config-file"
  ];
  users.username = {
    directories = [
      # Add user directories here
      ".config/your-app"
    ];
  };
};
```

## Troubleshooting

- Bootloader install failed: If you see an error like `bootctl --esp-path=/boot install` failed, ensure the EFI System Partition (ESP) exists, is formatted as vfat, and mounted at `/boot` during install. With this repo, Disko creates and mounts the ESP at `/boot`. If you ran Disko without specifying the correct device, re-run with the proper `--argstr device /dev/disk/by-id/<id>`.
- Wrong device path: Avoid `/dev/nvme0n1` short names; prefer stable `/dev/disk/by-id/<id>` paths to prevent surprises when device enumeration changes.

### Fix: `efiSysMountPoint = '/boot' is not a mounted partition`

This means the ESP was not mounted at `/mnt/boot` when `nixos-install` tried to install systemd-boot.

1) Re-run Disko to ensure partitions are created and mounted (replace the device):

```bash
sudo nix run --extra-experimental-features 'nix-command flakes' \
  github:nix-community/disko -- --mode disko \
  --argstr device /dev/disk/by-id/nvme-WDS100T3X0C-00SJG0_190670800068 \
  ./disko-layout.nix

```

2) If you have already partitioned the disk, just mount everything:

```bash
sudo nix run --extra-experimental-features 'nix-command flakes' \
  github:nix-community/disko -- --mode mount \
  --argstr device /dev/disk/by-id/nvme-WDS100T3X0C-00SJG0_190670800068 \
  ./disko-layout.nix
```

3) Verify mounts (you should see `/mnt/boot`):

NixOS Root on ZFS

Customization

Unless stated otherwise, it is not recommended to customize system configuration before reboot.

UEFI support only

Only UEFI is supported by this guide. Make sure your computer is booted in UEFI mode.
Preparation

    Download NixOS Live Image and boot from it.

    sha256sum -c ./nixos-*.sha256

    dd if=input-file of=output-file bs=1M

    Connect to the Internet.

    Set root password or /root/.ssh/authorized_keys.

    Start SSH server

    systemctl restart sshd

    Connect from another computer

    ssh root@192.168.1.91

    Target disk

    List available disks with

    find /dev/disk/by-id/

    If virtio is used as disk bus, power off the VM and set serial numbers for disk. For QEMU, use -drive format=raw,file=disk2.img,serial=AaBb. For libvirt, edit domain XML. See this page for examples.

    Declare disk array

    DISK='/dev/disk/by-id/ata-FOO /dev/disk/by-id/nvme-BAR'

    For single disk installation, use

    DISK='/dev/disk/by-id/disk1'

    Set a mount point

    MNT=$(mktemp -d)

    Set partition size:

    Set swap size in GB, set to 1 if you don’t want swap to take up too much space

    SWAPSIZE=4

    Set how much space should be left at the end of the disk, minimum 1GB

    RESERVE=1

System Installation

    Partition the disks.

    Note: you must clear all existing partition tables and data structures from target disks.

    For flash-based storage, this can be done by the blkdiscard command below:

    partition_disk () {
     local disk="${1}"
     blkdiscard -f "${disk}" || true

     parted --script --align=optimal  "${disk}" -- \
     mklabel gpt \
     mkpart EFI 1MiB 4GiB \
     mkpart rpool 4GiB -$((SWAPSIZE + RESERVE))GiB \
     mkpart swap  -$((SWAPSIZE + RESERVE))GiB -"${RESERVE}"GiB \
     set 1 esp on \

     partprobe "${disk}"
    }

    for i in ${DISK}; do
       partition_disk "${i}"
    done

    Setup temporary encrypted swap for this installation only. This is useful if the available memory is small:

    for i in ${DISK}; do
       cryptsetup open --type plain --key-file /dev/random "${i}"-part3 "${i##*/}"-part3
       mkswap /dev/mapper/"${i##*/}"-part3
       swapon /dev/mapper/"${i##*/}"-part3
    done

    LUKS only: Setup encrypted LUKS container for root pool:

    for i in ${DISK}; do
       # see PASSPHRASE PROCESSING section in cryptsetup(8)
       printf "YOUR_PASSWD" | cryptsetup luksFormat --type luks2 "${i}"-part2 -
       printf "YOUR_PASSWD" | cryptsetup luksOpen "${i}"-part2 luks-rpool-"${i##*/}"-part2 -
    done

    Create root pool

        Unencrypted

        # shellcheck disable=SC2046
        zpool create \
            -o ashift=12 \
            -o autotrim=on \
            -R "${MNT}" \
            -O acltype=posixacl \
            -O canmount=off \
            -O dnodesize=auto \
            -O normalization=formD \
            -O relatime=on \
            -O xattr=sa \
            -O mountpoint=none \
            rpool \
            mirror \
           $(for i in ${DISK}; do
              printf '%s ' "${i}-part2";
             done)

        LUKS encrypted

        # shellcheck disable=SC2046
        zpool create \
            -o ashift=12 \
            -o autotrim=on \
            -R "${MNT}" \
            -O acltype=posixacl \
            -O canmount=off \
            -O dnodesize=auto \
            -O normalization=formD \
            -O relatime=on \
            -O xattr=sa \
            -O mountpoint=none \
            rpool \
            mirror \
           $(for i in ${DISK}; do
              printf '/dev/mapper/luks-rpool-%s ' "${i##*/}-part2";
             done)

    If not using a multi-disk setup, remove mirror.

    Create root system container:

        zfs create -o canmount=noauto -o mountpoint=legacy rpool/root

    Create system datasets, manage mountpoints with mountpoint=legacy

    zfs create -o mountpoint=legacy rpool/home
    mount -o X-mount.mkdir -t zfs rpool/root "${MNT}"
    mount -o X-mount.mkdir -t zfs rpool/home "${MNT}"/home

    Format and mount ESP. Only one of them is used as /boot, you need to set up mirroring afterwards

    for i in ${DISK}; do
     mkfs.vfat -n EFI "${i}"-part1
    done

    for i in ${DISK}; do
     mount -t vfat -o fmask=0077,dmask=0077,iocharset=iso8859-1,X-mount.mkdir "${i}"-part1 "${MNT}"/boot
     break
    done

System Configuration

    Generate system configuration:

    nixos-generate-config --root "${MNT}"

    Edit system configuration:

    nano "${MNT}"/etc/nixos/hardware-configuration.nix

    Set networking.hostId:

    networking.hostId = "abcd1234";

    If using LUKS, add the output from following command to system configuration

    tee <<EOF
      boot.initrd.luks.devices = {
    EOF

    for i in ${DISK}; do echo \"luks-rpool-"${i##*/}-part2"\".device = \"${i}-part2\"\; ; done

    tee <<EOF
    };
    EOF

    Install system and apply configuration

    nixos-install  --root "${MNT}"

    Wait for the root password reset prompt to appear.

    Unmount filesystems

    cd /
    umount -Rl "${MNT}"
    zpool export -a

    Reboot

    reboot

    Set up networking, desktop and swap.

    Mount other EFI system partitions then set up a service for syncing their contents.


findmnt -R /mnt | grep -E '/mnt$|/mnt/(boot|nix|persist|home)'
```

4) If `/mnt/boot` is still missing, mount ESP manually (careful: format only if needed):

```bash
# Identify the ESP by GPT partlabel created by Disko
ls -l /dev/disk/by-partlabel/disk-main-ESP

# If not formatted (only do this on the correct ESP; data loss otherwise)
# sudo mkfs.vfat -F32 -n ESP /dev/disk/by-partlabel/disk-main-ESP

# Mount ESP at the target root
sudo mkdir -p /mnt/boot
sudo mount -o umask=0077 /dev/disk/by-partlabel/disk-main-ESP /mnt/boot
```

5) Re-run the install:

```bash
sudo nixos-install --flake .#desktop
```

If you see a warning about `/boot/loader/random-seed` being world-accessible, ensure `/boot` is mounted with a restrictive umask. The Disko layout now sets `umask=0077` automatically. If needed during a manual session:

```bash
sudo mount -o remount,umask=0077 /mnt/boot
```

A modern, declarative, and ephemeral NixOS system with ZFS, Impermanence, and Hyprland.

## Architecture Overview

This is a modern, declarative NixOS system built on the "Erase Your Darlings" philosophy. The architecture combines:

- **Nix Flakes**: For reproducible, hermetic system definition
- **Disko**: For declarative partitioning
- **ZFS with LUKS encryption**: For advanced filesystem features
- **Impermanence**: For ephemeral root filesystem
- **Hyprland**: Wayland compositor for a modern desktop experience
- **Opnix**: For runtime secret injection via 1Password

## Project Structure

- `flake.nix`: Central entry point for all configuration
- `hosts/`: Machine-specific configurations
  - `laptop/`: Laptop-specific settings
  - `desktop/`: Desktop-specific settings
  - `server/`: Server-specific settings
- `modules/`: Reusable modules
  - `nixos/`: System-level modules
    - `common.nix`: Shared system configurations
    - `disko-zfs.nix`: Disk partitioning and ZFS setup
    - `impermanence.nix`: Ephemeral root configuration
  - `home-manager/`: User-level modules
    - `desktop.nix`: Hyprland and desktop applications
    - `opnix.nix`: Secret management
- `users/`: User accounts and Home Manager configurations
- `secrets/`: Placeholder for encrypted secrets
- `scripts/`: Helper scripts for system management

## Build Commands

- **Full system rebuild**: `./scripts/rebuild.sh` (auto-detects hostname)
- **Manual rebuild**: `sudo nixos-rebuild switch --flake .#hostname`
- **Test build**: `nixos-rebuild build --flake .#hostname`
- **Dry run**: `nixos-rebuild dry-activate --flake .#hostname`
- **Check configuration**: `nix flake check`

## Formatting

- `npm run fmt`: Formats all files using Prettier with `prettier-plugin-alejandra` for `.nix`.
- `npm run fmt:check`: Checks formatting without writing changes.
- `./scripts/format.sh`: Smart wrapper that prefers Prettier, falls back to `nix fmt` or Alejandra.
- `nix fmt`: Uses the flake's `formatter` (currently `nixfmt-rfc-style`).

## Getting Started

1. Clone this repository
2. Customize `hosts/laptop/hardware-configuration.nix` for your hardware
3. Provision the disk with Disko using your by-id path (see above)
4. Set your username and preferences in the `users` directory
5. Build or install: `nixos-rebuild build --flake .#desktop` or `sudo nixos-install --flake .#desktop`

## Key Features

- **Declarative System**: Everything from disk partitioning to application themes is defined as code
- **Ephemeral Root**: The root filesystem is reset to a pristine state on each boot
- **Persistent State**: Specific files and directories can be opted into persistence
- **Modern Desktop**: Hyprland Wayland compositor with a cohesive theme
- **Secret Management**: 1Password integration for secure runtime secret injection

## Customization

- Add new host configurations in the `hosts/` directory
- Create additional user configurations in the `users/` directory
- Extend functionality with new modules in the `modules/` directory
- Adjust the disk layout in `modules/nixos/disko-zfs.nix`
- Modify persistence rules in `modules/nixos/impermanence.nix`

## Troubleshooting

### Common Issues and Solutions

#### Boot Failures
- **Symptom**: System fails to boot or drops to emergency shell
- **Solution**: Boot from an older generation in GRUB menu, check `/var/log/boot.log`
- **Prevention**: Always test with `nixos-rebuild build` before `switch`

#### ZFS Import Failures
- **Symptom**: `failed to import pool 'rpool'`
- **Solution**: Check disk connections, verify pool status with `zpool status`
- **Prevention**: Use stable `/dev/disk/by-id/` paths instead of `/dev/sdX`

#### SSH Service Failures
- **Symptom**: SSH host keys missing or service won't start
- **Solution**: Ensure SSH host keys are in persistence configuration
- **Check**: Verify `/etc/ssh/ssh_host_*` files are persisted in `impermanence.nix`

#### Home Manager Build Failures
- **Symptom**: `collision between` package conflicts or `buildEnv error: two given paths contain a conflicting subpath`
- **Solution**: Check for duplicate package definitions between system and user configs
- **Fix**: Use `programs.package.enable = true` instead of adding to `home.packages`
- **Example**: For Node.js conflicts, centralize to system development module instead of duplicating in user config
- **See**: `docs/package-conflicts.md` for detailed resolution examples

#### Package Not Found Errors
- **Symptom**: `attribute 'package' does not exist`
- **Solution**: Check package name in [NixOS Search](https://search.nixos.org/)
- **Alternative**: Use `nix-env -qaP package-name` to find correct attribute path

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
```

## Contributing

### Guidelines for Contributing

1. **Follow existing patterns** - Study the current structure before making changes
2. **Test thoroughly** - Always build and test configurations before submitting
3. **Document changes** - Update documentation for any new features or significant changes
4. **Use proper formatting** - Run `npm run fmt` to format all files consistently

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
- **Module structure**: Use standard `{ config, pkgs, lib, ... }:` signature
- **Naming**: kebab-case for files, camelCase for options, snake_case for string variables
- **Imports**: Use relative paths, group by type
- **Security**: Never commit secrets, use runtime injection instead

### Pull Request Process

1. Fork the repository
2. Create a feature branch from `main`
3. Make your changes following the guidelines above
4. Test your changes thoroughly
5. Update documentation if needed
6. Submit a pull request with clear description of changes

### Reporting Issues

When reporting issues, please include:
- Host configuration affected (desktop/laptop/server)
- Steps to reproduce the problem
- Error messages or logs
- System information (`nixos-version`, hardware details)
- Whether the issue occurs on fresh install or after changes

## References

- [NixOS Documentation](https://nixos.org/manual/nixos/stable/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [Disko](https://github.com/nix-community/disko)
- [Impermanence](https://github.com/nix-community/impermanence)
- [Hyprland](https://hyprland.org/)
- [Opnix](https://github.com/brizzbuzz/opnix)