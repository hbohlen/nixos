# boot.nix - Boot Loader Configuration

**Location:** `modules/nixos/boot.nix`

## Purpose

Configures the boot loader, kernel parameters, and firmware management for secure and optimized system startup. Uses systemd-boot with EFI for modern UEFI systems.

## Dependencies

- **External:** NixOS boot system, kernel modules, firmware packages

## Features

### Boot Loader Configuration

#### systemd-boot with EFI
```nix
boot.loader = {
  systemd-boot = {
    enable = true;
    editor = false;  # Disabled for security
  };
  efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };
  timeout = 5;  # Boot menu timeout
};
```

### Kernel Configuration

#### Essential Modules
```nix
boot.kernelModules = [
  "v4l2loopback"  # Virtual camera support
];
```

#### Kernel Parameters
```nix
boot.kernelParams = [
  "quiet"                      # Suppress boot messages
  "splash"                     # Show splash screen
  "loglevel=3"                 # Minimal kernel logging
  "rd.systemd.show_status=false"  # Hide systemd status
  "rd.udev.log_level=3"        # Minimal udev logging
];
```

### System Initialization

#### Temporary Filesystem
- **Clean /tmp on boot:** Ensures clean temporary filesystem
- **Verbose initrd:** Disabled for cleaner boot process

### Firmware Management

#### Firmware Updates
```nix
services.fwupd.enable = true;
```
Enables automatic firmware updates for supported hardware.

## Integration with Other Modules

### With impermanence.nix
The boot module works seamlessly with the impermanence module:
- Boot configuration persists across ephemeral root resets
- Kernel parameters support ZFS and rollback operations

### With hardware configurations
Boot parameters are often extended by hardware-specific configurations:
- NVIDIA modules may add GPU-related parameters
- Laptop modules may add power management parameters

## Usage Examples

### Basic Host Integration
```nix
{ config, lib, ... }:
{
  imports = [
    ../../modules/nixos/boot.nix
  ];
  
  # Boot module is automatically configured
  # No additional configuration needed for most cases
}
```

### Custom Kernel Parameters
```nix
{ config, lib, ... }:
{
  imports = [
    ../../modules/nixos/boot.nix
  ];
  
  # Add host-specific kernel parameters
  boot.kernelParams = [
    "intel_iommu=on"    # Enable IOMMU for virtualization
    "amd_iommu=on"      # AMD equivalent
  ];
}
```

### Extended Boot Timeout
```nix
{ config, lib, ... }:
{
  imports = [
    ../../modules/nixos/boot.nix
  ];
  
  # Override boot timeout for debugging
  boot.loader.timeout = lib.mkForce 10;
}
```

### Additional Kernel Modules
```nix
{ config, lib, ... }:
{
  imports = [
    ../../modules/nixos/boot.nix
  ];
  
  # Add hardware-specific modules
  boot.kernelModules = [
    "kvm-intel"         # Intel virtualization
    "vfio-pci"          # GPU passthrough
  ];
}
```

## Customization Options

### Boot Loader Customization
```nix
# Enable boot editor for recovery (less secure)
boot.loader.systemd-boot.editor = true;

# Change boot timeout
boot.loader.timeout = 10;

# Configure console settings
boot.loader.systemd-boot.consoleMode = "auto";
```

### Kernel Parameter Additions
Common additional parameters by use case:

#### Security Hardening
```nix
boot.kernelParams = [
  "slab_nomerge"               # Prevent slab merging
  "init_on_alloc=1"            # Zero memory on allocation
  "init_on_free=1"             # Zero memory on free
  "page_alloc.shuffle=1"       # Randomize page allocations
  "randomize_kstack_offset=on" # Randomize kernel stack
];
```

#### Performance Tuning
```nix
boot.kernelParams = [
  "mitigations=off"            # Disable security mitigations for performance
  "transparent_hugepage=always" # Enable transparent huge pages
];
```

#### Hardware Support
```nix
boot.kernelParams = [
  "acpi_backlight=native"      # Native backlight control
  "i915.enable_psr=1"          # Intel power saving
  "amdgpu.si_support=1"        # AMD GPU support
];
```

### InitramFS Configuration
```nix
# Enable debugging
boot.initrd.verbose = true;

# Add custom modules to initramFS
boot.initrd.kernelModules = [ "dm-snapshot" ];

# Include additional programs
boot.initrd.extraUtilsCommands = ''
  copy_bin_and_libs ${pkgs.cryptsetup}/bin/cryptsetup
'';
```

## Security Considerations

### Boot Security
- **Editor disabled:** Prevents unauthorized kernel parameter modification
- **Secure boot:** Can be enabled with additional configuration
- **Boot timeout:** Limited to prevent unauthorized access delay

### Kernel Hardening
The module includes basic kernel hardening through minimal logging and secure defaults. Additional hardening can be added per host requirements.

## Hardware Compatibility

### UEFI Systems
This module is designed for modern UEFI systems with:
- GPT partition table
- EFI System Partition mounted at `/boot`
- systemd-boot compatible firmware

### Legacy Systems
For BIOS/Legacy systems, override the boot loader:
```nix
boot.loader = {
  grub = {
    enable = true;
    device = "/dev/sda";  # Specify boot device
  };
  systemd-boot.enable = lib.mkForce false;
};
```

## Troubleshooting

### Boot Failures
1. **Check boot logs:** `journalctl -b` for current boot messages
2. **Verify EFI variables:** Ensure `efivarfs` is mounted
3. **Test kernel parameters:** Remove custom parameters if boot fails

### Firmware Issues
1. **Update firmware:** Use `fwupdmgr update` or system update
2. **Check compatibility:** Verify hardware supports firmware updates
3. **Manual firmware:** Install vendor-specific firmware packages

### Module Loading Issues
1. **Check available modules:** `lsmod` to see loaded modules
2. **Test manual loading:** `modprobe module-name`
3. **Verify module exists:** Check `/lib/modules/$(uname -r)/`

## Integration Notes

### With ZFS (via impermanence.nix)
When used with ZFS, additional considerations:
- ZFS modules loaded automatically by impermanence module
- Kernel parameters may need adjustment for ZFS performance
- Boot datasets must be configured in disko configuration

### With Secure Boot
For secure boot support:
```nix
boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
boot.lanzaboote = {
  enable = true;
  pkiBundle = "/etc/secureboot";
};
```

### Performance Impact
- **Boot time:** Minimal impact with optimized parameters
- **Memory usage:** v4l2loopback module adds minimal overhead
- **Security vs Performance:** Balance achieved through selective hardening