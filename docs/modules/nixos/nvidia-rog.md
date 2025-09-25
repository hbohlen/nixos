# nvidia-rog.nix - NVIDIA Graphics and ASUS ROG Support

**Location:** `modules/nixos/nvidia-rog.nix`

## Purpose

Provides NVIDIA proprietary driver configuration optimized for ASUS ROG (Republic of Gamers) laptops with hybrid graphics setups. Includes power management, PRIME configuration, and hardware-specific optimizations.

## Dependencies

- **Hardware:** NVIDIA GPU with Intel integrated graphics (hybrid setup)
- **Integration:** Typically used with desktop.nix and laptop.nix modules
- **External:** NVIDIA proprietary drivers, kernel modules

## Features

### NVIDIA Driver Configuration

#### Kernel Module Loading
```nix
boot = {
  # Blacklist nouveau to prevent conflicts
  blacklistedKernelModules = [ "nouveau" ];
  
  # Load NVIDIA drivers early in boot process
  initrd.kernelModules = [ "nvidia" "nvidia_drm" "nvidia_modeset" ];
  
  # NVIDIA-specific kernel parameters
  kernelParams = [
    "nvidia-drm.modeset=1"                              # DRM modesetting
    "nvidia-drm.fbdev=1"                               # Framebuffer device
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"    # Preserve VRAM
  ];
};
```

### Graphics Hardware Configuration

#### OpenGL and Hardware Acceleration
```nix
hardware.graphics = {
  enable = true;
  enable32Bit = true;    # 32-bit application support
};
```

#### NVIDIA Driver Settings
```nix
hardware.nvidia = {
  # Enable modesetting for proper functionality
  modesetting.enable = true;
  
  # NVIDIA settings GUI
  nvidiaSettings = true;
  
  # Open-source kernel modules (for RTX/GTX 16xx and newer)
  open = false;    # Set to false for older GPUs
  
  # Power management for laptops
  powerManagement = {
    enable = true;
    finegrained = true;    # Fine-grained power management
  };
  
  # Dynamic boost for performance
  dynamicBoost.enable = true;
  
  # Force full composition pipeline
  forceFullCompositionPipeline = true;
};
```

### PRIME Hybrid Graphics Configuration

#### Offload Configuration
```nix
hardware.nvidia.prime = {
  offload = {
    enable = true;
    enableOffloadCmd = true;    # Enable nvidia-offload command
  };
  
  # Bus IDs for hybrid graphics setup
  # Note: These need to be adjusted based on your hardware
  # Run 'lspci | grep -i nvidia' and 'lspci | grep -i vga' to find correct IDs
  intelBusId = "PCI:0:2:0";     # Intel integrated graphics
  nvidiaBusId = "PCI:1:0:0";    # NVIDIA discrete GPU
};
```

### Hardware-Specific Optimizations

#### UDEV Rules for Power Management
```nix
services.udev.extraRules = ''
  # NVIDIA GPU power management
  ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", ATTR{power/control}="auto"
  
  # ASUS keyboard backlight and device fixes
  ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0b05", ATTR{idProduct}=="19b6", ATTR{power/autosuspend}="-1"
'';
```

#### X Server Configuration
```nix
services.xserver.videoDrivers = [ "nvidia" ];
```

## Usage Examples

### Basic Gaming Laptop Setup
```nix
{ config, lib, pkgs, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/common.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/laptop.nix
    ../../modules/nixos/nvidia-rog.nix
  ];
  
  desktop.enable = true;
  
  # Gaming-specific packages
  environment.systemPackages = with pkgs; [
    steam
    lutris
    gamemode
    gamescope
  ];
  
  programs.steam.enable = true;
}
```

### Content Creation Workstation
```nix
{ config, lib, pkgs, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/development.nix
    ../../modules/nixos/nvidia-rog.nix
  ];
  
  desktop.enable = true;
  development.enable = true;
  
  # GPU-accelerated content creation tools
  environment.systemPackages = with pkgs; [
    # Video editing
    davinci-resolve
    kdenlive
    obs-studio
    
    # 3D modeling and rendering
    blender
    
    # AI/ML development
    python3Packages.torch
    python3Packages.tensorflow-gpu
    
    # CUDA development
    cudatoolkit
    nvidia-docker
  ];
  
  # Enable CUDA support
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.cudaSupport = true;
}
```

### Development with GPU Computing
```nix
{ config, lib, pkgs, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/development.nix
    ../../modules/nixos/nvidia-rog.nix
  ];
  
  development.enable = true;
  
  # GPU development environment
  environment.systemPackages = with pkgs; [
    # CUDA development
    cudatoolkit
    cudnn
    
    # Machine learning frameworks
    python3Packages.torch
    python3Packages.tensorflow-gpu
    python3Packages.cupy
    
    # GPU monitoring
    nvtop
    nvidia-smi
    
    # Container support with GPU
    nvidia-docker
  ];
  
  # Enable container GPU support
  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
  };
}
```

### Hybrid Graphics Optimization
```nix
{ config, lib, pkgs, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/nvidia-rog.nix
  ];
  
  # Optimize for battery life with hybrid graphics
  hardware.nvidia.prime = {
    offload.enable = true;
    offload.enableOffloadCmd = true;
    
    # Custom bus IDs for specific hardware
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };
  
  # Power management scripts
  environment.systemPackages = with pkgs; [
    # GPU switching utilities
    nvidia-offload
    optimus-manager  # Alternative GPU switching
    
    # Power monitoring
    powertop
    nvtop
  ];
  
  # Custom nvidia-offload script
  environment.etc."nvidia-offload.sh" = {
    text = ''
      #!/bin/sh
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec "$@"
    '';
    mode = "0755";
  };
}
```

## Advanced Configuration

### Custom GPU Performance Profiles
```nix
{ config, lib, pkgs, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/nvidia-rog.nix
  ];
  
  # GPU performance management
  systemd.services.nvidia-performance = {
    description = "NVIDIA GPU Performance Management";
    wantedBy = [ "graphical.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "nvidia-performance" ''
        # Set GPU performance mode
        ${pkgs.nvidia-x11}/bin/nvidia-smi -pm 1
        
        # Set power limit (adjust based on your GPU)
        ${pkgs.nvidia-x11}/bin/nvidia-smi -pl 200
        
        # Set GPU clocks (adjust based on your GPU)
        ${pkgs.nvidia-x11}/bin/nvidia-smi -ac 4000,1500
      '';
    };
  };
  
  # Temperature monitoring and fan control
  systemd.services.nvidia-thermal = {
    description = "NVIDIA Thermal Management";
    wantedBy = [ "graphical.target" ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      ExecStart = pkgs.writeShellScript "nvidia-thermal" ''
        while true; do
          TEMP=$(${pkgs.nvidia-x11}/bin/nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
          if [ "$TEMP" -gt 80 ]; then
            echo "GPU temperature high: $TEMP°C"
            # Reduce GPU clocks if overheating
            ${pkgs.nvidia-x11}/bin/nvidia-smi -ac 3000,1200
          fi
          sleep 30
        done
      '';
    };
  };
}
```

### Multi-Monitor Configuration
```nix
{ config, lib, pkgs, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/nvidia-rog.nix
  ];
  
  desktop.enable = true;
  
  # Multi-monitor setup with NVIDIA
  services.xserver = {
    screenSection = ''
      Option "metamodes" "DP-2: 2560x1440_144 +2560+0, eDP-1: 1920x1080_60 +0+360"
      Option "SLI" "Off"
      Option "MultiGPU" "Off"
      Option "BaseMosaic" "off"
    '';
    
    # Additional monitor configuration
    config = ''
      Section "Monitor"
          Identifier "eDP-1"
          Option "Primary" "true"
      EndSection
      
      Section "Monitor"  
          Identifier "DP-2"
          Option "RightOf" "eDP-1"
      EndSection
    '';
  };
  
  # Display management tools
  environment.systemPackages = with pkgs; [
    arandr          # GUI display configuration
    autorandr       # Automatic display profiles
    nvidia-settings # NVIDIA control panel
  ];
}
```

### Gaming Optimization
```nix
{ config, lib, pkgs, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/nvidia-rog.nix
  ];
  
  # Gaming-specific NVIDIA configuration
  hardware.nvidia = {
    # Use latest driver for gaming
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    
    # Gaming optimizations
    powerManagement.finegrained = false;  # Disable for gaming performance
  };
  
  # Gaming packages and tools
  environment.systemPackages = with pkgs; [
    # Gaming platforms
    steam
    lutris
    heroic
    bottles
    
    # Performance tools
    gamemode
    gamescope
    mangohud
    goverlay
    
    # GPU monitoring
    nvtop
    gpu-screen-recorder
    
    # Overclocking tools (use with caution)
    # msi-afterburner-linux
  ];
  
  # Gaming services
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  
  programs.gamemode.enable = true;
  
  # Gaming-specific environment variables
  environment.sessionVariables = {
    # NVIDIA-specific gaming optimizations
    "__GL_SHADER_DISK_CACHE" = "1";
    "__GL_SHADER_DISK_CACHE_PATH" = "/tmp/nvidia-shader-cache";
    "__GL_SHADER_DISK_CACHE_SKIP_CLEANUP" = "1";
    
    # Vulkan optimizations
    "VK_ICD_FILENAMES" = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json";
  };
}
```

## Hardware Compatibility

### Bus ID Configuration
To find your specific bus IDs:
```bash
# Find NVIDIA GPU bus ID
lspci | grep -i nvidia

# Find Intel integrated graphics bus ID  
lspci | grep -i vga

# Example output:
# 00:02.0 VGA compatible controller: Intel Corporation UHD Graphics 630
# 01:00.0 3D controller: NVIDIA Corporation GeForce GTX 1650 Ti
```

Update the configuration accordingly:
```nix
hardware.nvidia.prime = {
  intelBusId = "PCI:0:2:0";    # From 00:02.0
  nvidiaBusId = "PCI:1:0:0";   # From 01:00.0
};
```

### ASUS ROG Specific Features
```nix
{ config, lib, pkgs, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/nvidia-rog.nix
  ];
  
  # ASUS ROG laptop support
  services.supergfxd.enable = true;    # GPU switching daemon
  services.asusd.enable = true;        # ASUS system daemon
  
  # ROG-specific packages
  environment.systemPackages = with pkgs; [
    asusctl         # ASUS control utility
    supergfxctl     # GPU switching control
    rog-control-center  # ROG gaming center
  ];
  
  # ROG keyboard RGB lighting
  services.udev.extraRules = ''
    # ASUS ROG laptop keyboard
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0b05", ATTRS{idProduct}=="1866", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0b05", ATTRS{idProduct}=="19b6", TAG+="uaccess"
  '';
}
```

## Troubleshooting

### Driver Issues

#### NVIDIA Driver Problems
```bash
# Check NVIDIA driver version
nvidia-smi

# Check loaded modules
lsmod | grep nvidia

# Test OpenGL support
glxinfo | grep -i nvidia

# Check Vulkan support
vulkaninfo | grep -i nvidia
```

#### Module Loading Issues
```bash
# Check kernel messages
dmesg | grep -i nvidia

# Manually load modules
sudo modprobe nvidia
sudo modprobe nvidia_drm
sudo modprobe nvidia_modeset

# Check module dependencies
modinfo nvidia
```

### Performance Issues

#### GPU Not Being Used
```bash
# Check which GPU is active
nvidia-smi

# Test GPU offload
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo | grep -i nvidia

# Monitor GPU usage
watch nvidia-smi
```

#### Power Management Problems
```bash
# Check power state
cat /proc/driver/nvidia/gpus/*/power

# Check PRIME configuration
prime-run nvidia-smi

# Monitor power consumption
nvidia-smi -q -d POWER
```

### Display Issues

#### Multi-Monitor Problems
```bash
# Check connected displays
xrandr --listmonitors

# Test NVIDIA settings
nvidia-settings

# Check X11 configuration
cat /etc/X11/xorg.conf
```

#### Wayland Compatibility
```bash
# Check Wayland session
echo $XDG_SESSION_TYPE

# Enable NVIDIA Wayland support
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
```

### Gaming Issues

#### Steam/Gaming Performance
```bash
# Check Steam runtime
steam-runtime-check-requirements

# Test GPU in games
mangohud glxgears

# Check game-specific GPU usage
nvidia-smi -l 1
```

#### Compatibility Problems
```bash
# Test 32-bit OpenGL
glxinfo32 | grep -i nvidia

# Check Vulkan 32-bit support
vulkaninfo32 | grep -i nvidia

# Test DXVK (DirectX to Vulkan)
DXVK_LOG_LEVEL=info wine your-game.exe
```

## Performance Optimization

### GPU Memory Management
```nix
# Optimize GPU memory allocation
environment.variables = {
  "__GL_SHADER_DISK_CACHE_SIZE" = "1073741824";  # 1GB shader cache
  "__GL_SHADER_DISK_CACHE_PATH" = "/tmp/nvidia-shader-cache";
};

# Kernel parameters for performance
boot.kernelParams = [
  "nvidia.NVreg_DynamicPowerManagement=0x02"    # Enable dynamic power management
  "nvidia.NVreg_EnableGpuFirmware=1"            # Enable GPU firmware
];
```

### Thermal Management
```nix
# Custom thermal configuration
systemd.services.nvidia-thermal-management = {
  description = "NVIDIA Thermal Management";
  wantedBy = [ "graphical.target" ];
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
    ExecStart = pkgs.writeShellScript "nvidia-thermal" ''
      # Set temperature limit (adjust for your GPU)
      ${pkgs.nvidia-x11}/bin/nvidia-smi -gtt 83
      
      # Set power limit for thermal management
      ${pkgs.nvidia-x11}/bin/nvidia-smi -pl 180
    '';
  };
};
```

## Security Considerations

### Driver Security
- **Proprietary drivers:** Regular updates important for security patches
- **Kernel modules:** Signed modules provide better security
- **Container isolation:** GPU containers need careful permission management

### Power Management Security
- **Dynamic clocking:** Can be exploited for side-channel attacks
- **Memory isolation:** GPU memory should be properly isolated
- **Firmware updates:** Keep GPU firmware updated

## Integration Notes

### With Desktop Module
NVIDIA + desktop combination provides:
- Hardware-accelerated desktop effects
- Multi-monitor support with proper scaling
- Gaming and multimedia acceleration

### With Laptop Module
NVIDIA + laptop optimization includes:
- Hybrid graphics power management
- Battery-aware GPU switching
- Thermal management integration

### With Development Module
Development + NVIDIA enables:
- CUDA development environment
- AI/ML framework support
- GPU-accelerated computing workflows

### With Impermanence
NVIDIA configuration persistence considerations:
- Driver configuration files
- GPU performance profiles  
- Shader cache directories
- Gaming save data and settings