# desktop.nix - Desktop Environment Configuration

**Location:** `modules/nixos/desktop.nix`

## Purpose

Provides comprehensive desktop environment setup with support for both GNOME and Hyprland window managers, multimedia support, and essential desktop applications. Includes system-wide fonts, audio configuration, and desktop services.

## Dependencies

- **Variables:** Requires `username` parameter from host configuration
- **External:** nixpkgs desktop packages, X11/Wayland display systems
- **Integration:** Often used with development.nix and laptop.nix modules

## Configuration Options

### `desktop.enable`
- **Type:** `boolean` (enable option)
- **Default:** N/A (must be explicitly enabled)
- **Description:** Enable desktop environment configuration

### `desktop.environment`
- **Type:** `enum [ "gnome" "hyprland" "both" ]`
- **Default:** `"both"`
- **Description:** Choose which desktop environment(s) to enable

## Features

### Display Server and Window Managers

#### X11 and Wayland Support
```nix
# Enable X11 server for XWayland compatibility
services.xserver.enable = true;

# Display Manager and Desktop Environment
services.displayManager.gdm.enable = true;
services.desktopManager.gnome.enable = true;

# Enable Wayland and Hyprland
programs.hyprland.enable = true;
xdg.portal = {
  enable = true;
  extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
};
```

#### Available Configurations
- **GNOME:** Full-featured traditional desktop environment
- **Hyprland:** Modern tiling Wayland compositor
- **Both:** Dual setup allowing choice at login

### Font Configuration

#### System-Wide Font Installation
```nix
fonts.packages = with pkgs; [
  noto-fonts              # Google Noto font family
  noto-fonts-cjk-sans     # CJK (Chinese, Japanese, Korean) support
  noto-fonts-emoji        # Emoji support
  nerd-fonts.jetbrains-mono  # Programming font with icons
  nerd-fonts.fira-code    # Alternative programming font
  source-code-pro         # Adobe Source Code Pro
];
```

#### Font Configuration
```nix
fonts.fontconfig = {
  enable = true;
  defaultFonts = {
    serif = [ "Noto Serif" ];
    sansSerif = [ "Noto Sans" ];
    monospace = [ "JetBrains Mono" ];
    emoji = [ "Noto Color Emoji" ];
  };
};
```

### Audio System

#### PipeWire Audio Configuration
```nix
# Audio configuration using PipeWire
security.rtkit.enable = true;
services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;    # 32-bit audio support
  pulse.enable = true;          # PulseAudio compatibility
  jack.enable = true;           # JACK audio support
};

# Disable PulseAudio to avoid conflicts
services.pulseaudio.enable = false;
```

### Hardware Support

#### Bluetooth Configuration
```nix
hardware.bluetooth.enable = true;
services.blueman.enable = true;
```

#### Printing Support
```nix
services.printing.enable = true;
services.avahi = {
  enable = true;
  nssmdns4 = true;
  openFirewall = true;
};
```

### Essential Desktop Applications

#### Browsers and Productivity
```nix
environment.systemPackages = with pkgs; [
  # Browsers
  firefox               # Primary web browser
  
  # Development IDEs and editors
  zed-editor           # Modern code editor
  vscode               # Visual Studio Code
  
  # Productivity and office
  affine               # Note-taking and planning
  
  # File management
  nautilus             # GNOME file manager
  
  # System monitoring
  gnome-system-monitor # System resource monitor
  
  # Screenshot tools
  flameshot           # Screenshot utility
  
  # Archive tools
  zip
  unzip
  rar
  
  # Document viewers
  evince              # PDF viewer
  
  # Audio tools
  pavucontrol         # PulseAudio volume control
  easyeffects         # Audio effects and processing
];
```

### Security and Authentication

#### 1Password GUI Configuration
```nix
programs._1password-gui = {
  enable = true;
  polkitPolicyOwners = [ username ];
};
```

#### System Security
```nix
security = {
  # Polkit for privilege escalation
  polkit.enable = true;
  
  # AppArmor for application sandboxing
  apparmor.enable = true;
};
```

### Desktop Services

#### GNOME Services
```nix
services = {
  # GNOME keyring for credential storage
  gnome.gnome-keyring.enable = true;
  
  # Location services
  geoclue2.enable = true;
  
  # User directories
  desktopManager.gnome.extraGSettingsOverridePackages = [ pkgs.gnome-settings-daemon ];
};
```

#### Configuration Management
```nix
programs = {
  # DConf for GNOME settings
  dconf.enable = true;
};
```

## Usage Examples

### Basic Desktop Setup
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/common.nix
    ../../modules/nixos/desktop.nix
  ];
  
  # Enable desktop environment
  desktop.enable = true;
  # Uses default "both" environment (GNOME + Hyprland)
}
```

### GNOME-Only Configuration
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/desktop.nix
  ];
  
  desktop = {
    enable = true;
    environment = "gnome";
  };
}
```

### Hyprland-Only Configuration
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/desktop.nix
  ];
  
  desktop = {
    enable = true;
    environment = "hyprland";
  };
  
  # Additional Wayland-specific configuration
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";      # Enable Wayland for Chromium/Electron
    MOZ_ENABLE_WAYLAND = "1";  # Enable Wayland for Firefox
  };
}
```

### Gaming Desktop Setup
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/nvidia-rog.nix  # For gaming hardware
  ];
  
  desktop.enable = true;
  
  # Gaming-specific additions
  environment.systemPackages = with pkgs; [
    # Gaming platforms
    steam
    lutris
    heroic
    
    # Gaming utilities
    gamemode
    gamescope
    mangohud
    
    # Communication
    discord
    teamspeak_client
  ];
  
  # Gaming services
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  
  programs.gamemode.enable = true;
}
```

### Content Creation Setup
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/desktop.nix
  ];
  
  desktop.enable = true;
  
  # Content creation applications
  environment.systemPackages = with pkgs; [
    # Image editing
    gimp
    inkscape
    krita
    
    # Video editing
    kdenlive
    openshot-qt
    davinci-resolve
    
    # Audio editing
    audacity
    reaper
    
    # 3D modeling
    blender
    
    # Screen recording
    obs-studio
    simplescreenrecorder
  ];
}
```

### Development Desktop
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/development.nix
  ];
  
  desktop.enable = true;
  development.enable = true;
  
  # Development-focused desktop applications
  environment.systemPackages = with pkgs; [
    # Additional editors and IDEs
    jetbrains.idea-ultimate
    jetbrains.pycharm-professional
    android-studio
    
    # Database tools
    dbeaver
    pgadmin4
    
    # API testing
    postman
    insomnia
    
    # Design tools
    figma-linux
    
    # Documentation
    zeal  # Offline documentation browser
  ];
}
```

## Advanced Configuration

### Custom GNOME Extensions
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/desktop.nix
  ];
  
  desktop.enable = true;
  
  # GNOME Shell extensions
  environment.systemPackages = with pkgs.gnomeExtensions; [
    appindicator
    dash-to-dock
    workspace-indicator
    vitals
    blur-my-shell
    pop-shell  # Tiling functionality
  ];
}
```

### Wayland-Specific Optimizations
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/desktop.nix
  ];
  
  desktop.enable = true;
  desktop.environment = "hyprland";
  
  # Wayland environment variables
  environment.sessionVariables = {
    # Enable Wayland for applications
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    GDK_BACKEND = "wayland";
    
    # XWayland fallback
    CLUTTER_BACKEND = "wayland";
    SDL_VIDEODRIVER = "wayland";
  };
  
  # Additional Wayland tools
  environment.systemPackages = with pkgs; [
    wl-clipboard      # Wayland clipboard utilities
    wlr-randr        # Display configuration
    wayland-utils    # Wayland debugging tools
    xwayland         # X11 compatibility layer
  ];
}
```

### Multi-Monitor Setup
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/desktop.nix
  ];
  
  desktop.enable = true;
  
  # Multi-monitor support tools
  environment.systemPackages = with pkgs; [
    arandr           # GUI display configuration
    autorandr        # Automatic display configuration
    ddcutil          # Monitor control via DDC/CI
  ];
  
  # Enable DDC/CI support
  boot.kernelModules = [ "ddcci_backlight" ];
  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';
  
  # Add user to i2c group
  users.users.${username}.extraGroups = [ "i2c" ];
}
```

## Integration with Other Modules

### With Laptop Module
Desktop + laptop combination enables:
- Power management for desktop applications
- Brightness control for external monitors
- Battery-aware desktop behavior

### With NVIDIA Module
When combined with NVIDIA hardware:
- Hardware acceleration for desktop effects
- GPU-accelerated applications
- Gaming performance optimizations

### With Development Module
Development + desktop provides:
- GUI development tools and IDEs
- Desktop applications for development workflows
- Integration between CLI and GUI tools

## Troubleshooting

### Display Issues

#### Wayland Problems
```bash
# Check Wayland session
echo $XDG_SESSION_TYPE

# Test Wayland applications
wayland-info

# Check for X11 fallback
xrandr --listmonitors
```

#### GNOME Issues
```bash
# Reset GNOME settings
dconf reset -f /org/gnome/

# Check GNOME Shell version
gnome-shell --version

# Restart GNOME Shell (X11 only)
Alt+F2, type 'r', press Enter
```

### Audio Problems

#### PipeWire Debugging
```bash
# Check PipeWire status
systemctl --user status pipewire

# List audio devices
pactl list short sinks
pactl list short sources

# Test audio
speaker-test -c2 -t wav
```

#### Audio Service Conflicts
```bash
# Ensure PulseAudio is disabled
systemctl --user status pulseaudio
systemctl --user disable pulseaudio

# Restart audio services
systemctl --user restart pipewire
```

### Application Issues

#### Font Problems
```bash
# Rebuild font cache
fc-cache -fv

# Check available fonts
fc-list | grep -i "jetbrains\|noto"

# Test font rendering
echo "Font test: 123 ABC abc" | pango-view --font="JetBrains Mono 12" /dev/stdin
```

#### 1Password Integration
```bash
# Check 1Password service
systemctl --user status 1password

# Test CLI integration
op --version

# Check browser integration
ls ~/.mozilla/native-messaging-hosts/
```

## Performance Optimization

### Graphics Performance
```nix
# Enable hardware acceleration
hardware.opengl = {
  enable = true;
  driSupport = true;
  driSupport32Bit = true;
};

# Optimize for specific GPU
# (NVIDIA configuration in nvidia-rog.nix)
# (AMD configuration)
hardware.opengl.extraPackages = with pkgs; [
  amdvlk
  rocm-opencl-icd
];
```

### Memory Management
```nix
# Optimize for desktop workloads
boot.kernel.sysctl = {
  "vm.swappiness" = 10;           # Reduce swap usage
  "vm.vfs_cache_pressure" = 50;   # Balance file system cache
  "kernel.sched_autogroup_enabled" = 1;  # Better desktop responsiveness
};
```

### Desktop Services Optimization
```nix
# Disable unnecessary GNOME services
services.gnome = {
  tracker-miners.enable = false;    # File indexing
  tracker.enable = false;           # Search functionality
  evolution-data-server.enable = false;  # Calendar/contacts
};
```

## Security Considerations

### Desktop Security
- **AppArmor:** Provides application sandboxing for desktop applications
- **Polkit:** Manages privilege escalation for desktop operations
- **1Password:** Secure credential management with GUI integration

### Network Security
- **Firewall:** Desktop applications may require specific firewall rules
- **Bluetooth:** Can be disabled if not needed for security
- **Location services:** Geoclue2 can be configured or disabled as needed

### Application Sandboxing
```nix
# Enhanced sandboxing with Flatpak
services.flatpak.enable = true;

# AppArmor profiles for additional applications
security.apparmor.packages = with pkgs; [
  apparmor-profiles
];
```

## Accessibility Features

### Accessibility Support
```nix
# Enable accessibility services
services.gnome.at-spi2-core.enable = true;

# Screen reader support
environment.systemPackages = with pkgs; [
  orca              # GNOME screen reader
  espeak-ng         # Text-to-speech
];

# High contrast themes and large fonts
services.xserver.displayManager.gdm.extraConfig = ''
  [org/gnome/desktop/interface]
  high-contrast=true
  text-scaling-factor=1.25
'';
```

### Input Accessibility
```nix
# On-screen keyboard
environment.systemPackages = with pkgs; [
  onboard           # Virtual keyboard
  florence          # Alternative virtual keyboard
];

# Mouse accessibility
services.xserver.libinput = {
  enable = true;
  mouse = {
    accelProfile = "adaptive";
    accelSpeed = "0.5";
  };
};
```