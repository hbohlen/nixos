# Boot Configuration Module - Agent Documentation

## Module Purpose
The `boot.nix` module configures the system boot process, including the boot loader (systemd-boot), kernel parameters, initrd configuration, and early-boot services. This is a critical system component that determines how the system starts and initializes.

## Configuration Options

### Boot Loader Settings
- **`boot.loader.systemd-boot.enable`**: Enables systemd-boot EFI boot loader
- **`boot.loader.systemd-boot.editor`**: Controls boot menu editor access (security setting)
- **`boot.loader.efi.canTouchEfiVariables`**: Allows modification of EFI boot variables
- **`boot.loader.efi.efiSysMountPoint`**: EFI system partition mount point (typically `/boot`)
- **`boot.loader.timeout`**: Boot menu timeout in seconds

### Kernel Configuration  
- **`boot.kernelModules`**: Kernel modules to load during boot
- **`boot.kernelParams`**: Kernel command line parameters
- **`boot.supportedFilesystems`**: Filesystems to support (e.g., "zfs", "ext4")
- **`boot.tmp.cleanOnBoot`**: Whether to clean `/tmp` directory on boot

### Initrd Configuration
- **`boot.initrd.availableKernelModules`**: Kernel modules available in initrd
- **`boot.initrd.kernelModules`**: Kernel modules to force-load in initrd
- **`boot.initrd.systemd.enable`**: Enable systemd in initrd for advanced service management

## Effects and Behavior

### System Boot Process
1. **EFI Firmware** loads systemd-boot from EFI system partition
2. **systemd-boot** presents boot menu with available NixOS generations
3. **Kernel** loads with specified parameters and modules
4. **Initrd** initializes hardware, unlocks encrypted drives, imports ZFS pools
5. **Root filesystem** is mounted and system services begin

### Security Considerations
- **Editor disabled**: Prevents unauthorized kernel parameter modification
- **EFI variables**: Allows system to manage boot entries automatically
- **Module security**: Only necessary kernel modules are loaded
- **Clean /tmp**: Removes potentially sensitive temporary files

### ZFS Integration
- ZFS support must be enabled in `boot.supportedFilesystems`
- ZFS pool import happens during initrd phase
- Proper initrd systemd ordering ensures ZFS availability before root mount

## Troubleshooting

### Common Boot Issues

#### Boot Loader Problems
**Symptoms**: System won't boot, missing boot menu, EFI errors
**Diagnosis**:
```bash
# Check EFI boot entries
efibootmgr -v
# Verify EFI system partition
lsblk -f | grep vfat
# Check systemd-boot installation
bootctl status
```
**Solutions**:
- Reinstall boot loader: `nixos-rebuild switch`
- Manual EFI repair: Boot from NixOS ISO, mount ESP, run `bootctl install`
- Check EFI system partition integrity

#### Kernel Module Issues
**Symptoms**: Hardware not detected, filesystem mount failures
**Diagnosis**:
```bash
# Check loaded modules
lsmod | grep <module_name>
# Check available modules
modinfo <module_name>
# Check kernel messages
dmesg | grep -i error
```
**Solutions**:
- Add required modules to `boot.initrd.availableKernelModules`
- Force module loading with `boot.initrd.kernelModules`
- Update kernel with `boot.kernelPackages`

#### Filesystem Mount Failures
**Symptoms**: Cannot mount root, ZFS import failures, encryption unlock issues
**Diagnosis**:
```bash
# Check ZFS pool status
zpool status
# Check LUKS devices
cryptsetup status
# Check filesystem types
blkid
```
**Solutions**:
- Verify `boot.supportedFilesystems` includes required filesystems
- Check ZFS pool import configuration
- Verify LUKS keyfile configuration
- Ensure proper initrd module loading

### Emergency Recovery

#### Boot from NixOS ISO
1. Boot from NixOS installation medium
2. Unlock encrypted drives: `cryptsetup luksOpen /dev/device crypt-root`
3. Import ZFS pool: `zpool import rpool`
4. Mount root: `mount /dev/mapper/crypt-root /mnt`
5. Enter chroot: `nixos-enter --root /mnt`

#### Rollback to Previous Generation
1. Select older generation from systemd-boot menu
2. Or use: `nixos-rebuild switch --rollback`
3. Or manually: `/nix/var/nix/profiles/system-N-link/bin/switch-to-configuration switch`

#### Kernel Parameter Recovery
If system won't boot due to kernel parameters:
1. Edit boot entry in systemd-boot menu (if editor enabled)
2. Remove problematic parameters temporarily
3. Boot and fix configuration permanently

## Best Practices

### Configuration Guidelines
- **Minimal modules**: Only include necessary kernel modules for security
- **Test changes**: Use `nixos-rebuild build` before switching
- **Backup config**: Ensure bootable system before major changes
- **Document hardware**: Note specific hardware requirements in host configs
- **Security first**: Keep boot editor disabled in production systems

### Performance Optimization
- **Fast boot**: Minimize initrd modules and services
- **Parallel loading**: Use systemd in initrd for parallel initialization
- **Module loading**: Use `availableKernelModules` instead of force-loading when possible
- **Kernel selection**: Choose appropriate kernel version for hardware

### Hardware Compatibility
- **Check support**: Verify kernel module availability for hardware
- **Test thoroughly**: Boot test on actual hardware, not just VM
- **Document quirks**: Note any hardware-specific requirements
- **Update regularly**: Keep kernel updated for latest hardware support

## Integration Notes

### Module Dependencies
- **Hardware configs**: Must work with host-specific hardware-configuration.nix
- **Filesystem modules**: Integrates with impermanence.nix and disko configurations
- **Security modules**: Coordinates with LUKS encryption setup
- **Network boot**: May need special configuration for PXE or network boot

### Host-Specific Considerations
- **Desktop**: May need NVIDIA or graphics-specific kernel parameters
- **Laptop**: Often requires additional power management modules
- **Server**: Minimal module set for security and performance
- **VM**: Different requirements for virtualized environments

This module is fundamental to system operation - always test changes carefully and maintain backup boot options.