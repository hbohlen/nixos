# desktop.nix - User Desktop Environment Configuration

**Location:** `modules/home-manager/desktop.nix`

## Purpose

Provides user-level desktop environment configuration using Hyprland Wayland compositor with a complete desktop experience including window management, status bar, application launcher, notifications, and theming. Designed for modern Wayland-based desktop workflows.

## Dependencies

- **External Flakes:** `inputs.hyprland.homeManagerModules.default`
- **System Requirements:** Wayland support, graphics drivers
- **Integration:** Works with system-level desktop.nix module

## Features

### Hyprland Window Manager

#### Core Hyprland Configuration
```nix
wayland.windowManager.hyprland = {
  enable = true;
  extraConfig = ''
    # Start wallpaper daemon
    exec-once = swww-daemon &
    exec-once = swww img ~/.config/wallpaper.png
    
    # Start status bar
    exec-once = waybar
    
    # Source theme configuration
    source = ~/.config/hypr/theme.conf
  '';
};
```

#### Window Manager Settings
```nix
settings = {
  monitor = ",preferred,auto,1";    # Automatic monitor configuration
  
  # Input device configuration
  input = {
    kb_layout = "us";
    follow_mouse = 1;
    touchpad = {
      natural_scroll = true;
    };
  };
  
  # Visual appearance
  general = {
    gaps_in = 5;
    gaps_out = 10;
    border_size = 2;
    "col.active_border" = "rgb(cba6f7)";      # Catppuccin Mauve
    "col.inactive_border" = "rgb(45475a)";    # Catppuccin Surface0
    layout = "dwindle";
  };
  
  # Window decorations
  decoration = {
    rounding = 10;
    blur = {
      enabled = true;
      size = 3;
      passes = 1;
    };
  };
};
```

### Window Management Keybindings

#### Core Navigation
```nix
"$mainMod" = "SUPER";
bind = [
  # Application launching
  "$mainMod, Return, exec, alacritty"         # Terminal
  "$mainMod, R, exec, wofi --show drun"       # Application launcher
  "$mainMod, E, exec, dolphin"                # File manager
  
  # Window management
  "$mainMod, Q, killactive,"                  # Close window
  "$mainMod, M, exit,"                        # Exit Hyprland
  "$mainMod, V, togglefloating,"             # Toggle floating
  "$mainMod, J, togglesplit,"                # Toggle split
  
  # Focus movement
  "$mainMod, left, movefocus, l"
  "$mainMod, right, movefocus, r"
  "$mainMod, up, movefocus, u"
  "$mainMod, down, movefocus, d"
  
  # Workspace switching (1-10)
  "$mainMod, 1, workspace, 1"
  "$mainMod, 2, workspace, 2"
  # ... up to 10
  
  # Move windows to workspaces
  "$mainMod SHIFT, 1, movetoworkspace, 1"
  "$mainMod SHIFT, 2, movetoworkspace, 2"
  # ... up to 10
  
  # Screenshots
  ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"     # Area screenshot
  "SHIFT, Print, exec, grim - | wl-copy"                # Full screenshot
];
```

### Status Bar (Waybar)

#### Waybar Configuration
```nix
programs.waybar = {
  enable = true;
  settings = {
    mainBar = {
      layer = "top";
      position = "top";
      height = 30;
      
      # Module layout
      modules-left = [ "hyprland/workspaces" "hyprland/window" ];
      modules-center = [ "clock" ];
      modules-right = [ "battery" "disk" "pulseaudio" "network" "cpu" "memory" "tray" ];
      
      # Module configurations
      "hyprland/workspaces" = {
        format = "{icon}";
        format-icons = {
          "1" = "1"; "2" = "2"; "3" = "3"; "4" = "4"; "5" = "5";
          "6" = "6"; "7" = "7"; "8" = "8"; "9" = "9"; "10" = "10";
        };
      };
      
      clock = {
        format = "{:%Y-%m-%d %H:%M:%S}";
        interval = 1;
      };
      
      battery = {
        format = "{capacity}% {icon}";
        format-icons = [ "" "" "" "" "" ];
      };
      
      cpu = {
        format = "{usage}% 🖥️";
      };
      
      memory = {
        format = "{percentage}% 🧠";
      };
    };
  };
};
```

#### Waybar Styling
```nix
style = ''
  * {
    border: none;
    font-family: "JetBrainsMono Nerd Font";
    font-size: 14px;
  }
  
  window#waybar {
    background-color: rgba(30, 30, 46, 0.8);    # Catppuccin Base
    color: #cdd6f4;                             # Catppuccin Text
  }
  
  #workspaces button {
    padding: 0 5px;
    background-color: transparent;
    color: #cdd6f4;
  }
  
  #workspaces button.active {
    background-color: #cba6f7;                  # Catppuccin Mauve
    color: #1e1e2e;
  }
'';
```

### Application Launcher (Wofi)

#### Wofi Configuration
```nix
programs.wofi = {
  enable = true;
  style = ''
    window {
      margin: 5px;
      border: 2px solid #cba6f7;
      background-color: #1e1e2e;
      border-radius: 15px;
    }
    
    #input {
      margin: 5px;
      border: 2px solid #cba6f7;
      border-radius: 10px;
      background-color: #313244;
      color: #cdd6f4;
    }
    
    #entry:selected {
      background-color: #cba6f7;
      color: #1e1e2e;
      border-radius: 10px;
    }
  '';
};
```

### Notifications (Dunst)

#### Notification Daemon Configuration
```nix
services.dunst = {
  enable = true;
  settings = {
    global = {
      font = "JetBrainsMono Nerd Font 10";
      format = "<b>%s</b>\\n%b";
      frame_width = 2;
      frame_color = "#cba6f7";
      corner_radius = 10;
      offset = "10x10";
    };
    
    urgency_low = {
      background = "#313244";          # Catppuccin Surface0
      foreground = "#cdd6f4";          # Catppuccin Text
      timeout = 10;
    };
    
    urgency_normal = {
      background = "#1e1e2e";          # Catppuccin Base
      foreground = "#cdd6f4";          # Catppuccin Text
      frame_color = "#cba6f7";         # Catppuccin Mauve
      timeout = 10;
    };
    
    urgency_critical = {
      background = "#f38ba8";          # Catppuccin Red
      foreground = "#1e1e2e";          # Catppuccin Base
      frame_color = "#f38ba8";         # Catppuccin Red
      timeout = 0;
    };
  };
};
```

### Screen Lock (Swaylock)

#### Lock Screen Configuration
```nix
programs.swaylock = {
  enable = true;
  package = pkgs.swaylock-effects;
  settings = {
    clock = true;
    indicator = true;
    screenshots = true;
    effect-blur = "7x5";
    effect-vignette = "0.5:0.5";
    color = "#1e1e2e";
    font = "JetBrainsMono Nerd Font";
    font-size = 16;
    ring-color = "#cba6f7";
    key-hl-color = "#f38ba8";
    inside-color = "#313244";
    separator-color = "#cdd6f4";
  };
};
```

### Theming and Appearance

#### GTK Theme Configuration
```nix
gtk = {
  enable = true;
  theme = {
    name = "adw-gtk3";
    package = pkgs.adw-gtk3;
  };
  iconTheme = {
    name = "Papirus-Dark";
    package = pkgs.papirus-icon-theme;
  };
  cursorTheme = {
    name = "Catppuccin-Mocha-Lavender-Cursors";
    package = pkgs.catppuccin-cursors;
    size = 24;
  };
};
```

#### Catppuccin Color Scheme
```nix
xdg.configFile."hypr/theme.conf".text = ''
  # Catppuccin Mocha theme for Hyprland
  $rosewater = rgb(f5e0dc)
  $flamingo  = rgb(f2cdcd)
  $pink      = rgb(f5c2e7)
  $mauve     = rgb(cba6f7)
  $red       = rgb(f38ba8)
  $maroon    = rgb(eba0ac)
  $peach     = rgb(fab387)
  $yellow    = rgb(f9e2af)
  $green     = rgb(a6e3a1)
  $teal      = rgb(94e2d5)
  $sky       = rgb(89dceb)
  $sapphire  = rgb(74c7ec)
  $blue      = rgb(89b4fa)
  $lavender  = rgb(b4befe)
  $text      = rgb(cdd6f4)
  $subtext1  = rgb(bac2de)
  $subtext0  = rgb(a6adc8)
  $overlay2  = rgb(9399b2)
  $overlay1  = rgb(7f849c)
  $overlay0  = rgb(6c7086)
  $surface2  = rgb(585b70)
  $surface1  = rgb(45475a)
  $surface0  = rgb(313244)
  $base      = rgb(1e1e2e)
  $mantle    = rgb(181825)
  $crust     = rgb(11111b)
'';
```

### Essential Desktop Applications

#### Core Application Suite
```nix
home.packages = with pkgs; [
  # Terminal emulator
  alacritty
  
  # File managers
  kdePackages.dolphin          # GUI file manager
  nnn                          # Terminal file manager
  ranger                       # Terminal file manager
  
  # Web browser
  firefox
  
  # Screenshot tools
  grim                         # Screenshot utility
  slurp                        # Area selection
  swappy                       # Screenshot editing
  
  # Image viewer
  imv
  
  # Wallpaper management
  swaybg                       # Static wallpapers
  swww                         # Animated wallpapers
  
  # Clipboard management
  wl-clipboard                 # Wayland clipboard
  cliphist                     # Clipboard history
  
  # Notification system
  libnotify
  
  # Terminal utilities
  ripgrep                      # Text search
  fd                           # File find
  bat                          # Cat replacement
  eza                          # Ls replacement
  zoxide                       # Directory navigation
  fzf                          # Fuzzy finder
  tmux                         # Terminal multiplexer
  zellij                       # Modern terminal multiplexer
  lazygit                      # Git TUI
  
  # Development environment
  direnv                       # Environment management
  nix-direnv                   # Nix integration for direnv
  
  # Fonts
  nerd-fonts.jetbrains-mono    # Programming font
  
  # Theme components
  swaylock-effects             # Lock screen
  adw-gtk3                     # GTK theme
  catppuccin-cursors          # Cursor theme
];
```

## Usage Examples

### Basic User Configuration
```nix
{ pkgs, inputs, ... }:
{
  imports = [
    ../../modules/home-manager/desktop.nix
  ];
  
  # Desktop module provides complete Hyprland environment
  # No additional configuration needed for basic setup
}
```

### Developer Desktop Setup
```nix
{ pkgs, inputs, ... }:
{
  imports = [
    ../../modules/home-manager/desktop.nix
  ];
  
  # Add development-specific applications
  home.packages = with pkgs; [
    # Code editors
    vscode
    neovim
    
    # Development tools
    git
    gh                           # GitHub CLI
    docker-compose
    
    # Terminal tools
    httpie                       # HTTP client
    jq                           # JSON processor
    tree                         # Directory tree
  ];
  
  # Custom Hyprland keybindings for development
  wayland.windowManager.hyprland.settings.bind = [
    "$mainMod, C, exec, code"                    # Launch VS Code
    "$mainMod SHIFT, G, exec, alacritty -e lazygit"  # Git interface
  ];
}
```

### Gaming and Entertainment Setup
```nix
{ pkgs, inputs, ... }:
{
  imports = [
    ../../modules/home-manager/desktop.nix
  ];
  
  # Gaming and media applications
  home.packages = with pkgs; [
    # Gaming
    steam
    lutris
    gamemode
    
    # Media
    mpv                          # Video player
    spotify                      # Music streaming
    discord                      # Communication
    
    # Screenshot/recording for gaming
    obs-studio                   # Streaming/recording
    gpu-screen-recorder          # Hardware-accelerated recording
  ];
  
  # Gaming-optimized Hyprland settings
  wayland.windowManager.hyprland.settings = {
    # Disable animations for better gaming performance
    animations.enabled = false;
    
    # Gaming-specific workspace
    bind = [
      "$mainMod, G, workspace, 5"              # Gaming workspace
      "$mainMod, S, exec, steam"               # Launch Steam
    ];
  };
}
```

### Multi-Monitor Configuration
```nix
{ pkgs, inputs, ... }:
{
  imports = [
    ../../modules/home-manager/desktop.nix
  ];
  
  # Multi-monitor Hyprland configuration
  wayland.windowManager.hyprland.settings = {
    # Configure multiple monitors
    monitor = [
      "eDP-1,1920x1080@60,0x0,1"               # Laptop screen
      "DP-2,2560x1440@144,1920x0,1"            # External monitor
    ];
    
    # Workspace-to-monitor assignments
    workspace = [
      "1, monitor:eDP-1"                       # Workspace 1 on laptop screen
      "2, monitor:eDP-1"
      "3, monitor:DP-2"                        # Workspace 3 on external monitor
      "4, monitor:DP-2"
    ];
  };
  
  # Multi-monitor tools
  home.packages = with pkgs; [
    wlr-randr                    # Wayland display management
    kanshi                       # Automatic display configuration
  ];
}
```

## Advanced Customization

### Custom Hyprland Animations
```nix
{ pkgs, inputs, ... }:
{
  imports = [
    ../../modules/home-manager/desktop.nix
  ];
  
  # Enhanced animations
  wayland.windowManager.hyprland.settings.animations = {
    enabled = true;
    bezier = [
      "myBezier, 0.05, 0.9, 0.1, 1.05"
      "linear, 0.0, 0.0, 1.0, 1.0"
      "wind, 0.05, 0.9, 0.1, 1.05"
    ];
    animation = [
      "windows, 1, 6, wind, slide"
      "windowsOut, 1, 5, wind, slide"
      "border, 1, 1, linear"
      "fade, 1, 10, default"
      "workspaces, 1, 5, wind"
    ];
  };
}
```

### Advanced Waybar Configuration
```nix
{ pkgs, inputs, ... }:
{
  imports = [
    ../../modules/home-manager/desktop.nix
  ];
  
  # Extended Waybar modules
  programs.waybar.settings.mainBar = {
    modules-right = [
      "custom/weather"
      "custom/vpn"
      "bluetooth"
      "network"
      "pulseaudio"
      "battery" 
      "clock"
      "tray"
    ];
    
    # Custom modules
    "custom/weather" = {
      exec = "curl -s 'https://wttr.in/?format=1'";
      interval = 3600;
      format = "{}";
    };
    
    "custom/vpn" = {
      exec = "echo VPN";
      exec-if = "test -d /proc/sys/net/ipv4/conf/tun0";
      format = "🔒 {}";
      interval = 5;
    };
    
    bluetooth = {
      format = " {status}";
      format-connected = " {device_alias}";
      format-connected-battery = " {device_alias} {device_battery_percentage}%";
      on-click = "blueman-manager";
    };
  };
}
```

### Custom Application Shortcuts
```nix
{ pkgs, inputs, ... }:
{
  imports = [
    ../../modules/home-manager/desktop.nix
  ];
  
  # Extended keybindings
  wayland.windowManager.hyprland.settings.bind = [
    # Media controls
    ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
    ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
    ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    
    # Brightness controls
    ", XF86MonBrightnessUp, exec, brightnessctl set 10%+"
    ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"
    
    # Custom application launches
    "$mainMod, B, exec, firefox"
    "$mainMod, F, exec, dolphin"
    "$mainMod, D, exec, discord"
    "$mainMod, S, exec, spotify"
    
    # Screenshot variants
    "$mainMod, P, exec, grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"
    "$mainMod SHIFT, P, exec, grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"
    
    # Clipboard history
    "$mainMod, X, exec, cliphist list | wofi -dmenu | cliphist decode | wl-copy"
  ];
}
```

## Integration with System Configuration

### With System Desktop Module
The Home Manager desktop module complements the system desktop.nix:
- **System:** Provides Hyprland, fonts, and base desktop services
- **User:** Configures user-specific Hyprland settings, applications, and theming

### Wallpaper Management
```nix
# Automatic wallpaper setup
xdg.configFile."wallpaper.png".source = pkgs.fetchurl {
  url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/wallpapers/nix-wallpaper-simple-dark-gray_bottom.png";
  sha256 = "254cb37fd7584722d09b124f2a9b43c572fbc91a8016de6e3340bd72b924118e";
};
```

### Application Persistence
When used with impermanence, important user data should be persisted:
```nix
# In system impermanence configuration
environment.persistence."/persist".users.${username} = {
  directories = [
    ".config/hypr"              # Hyprland user config
    ".config/waybar"            # Waybar configuration
    ".config/wofi"              # Application launcher history
    ".local/share/applications" # Custom desktop entries
  ];
};
```

## Troubleshooting

### Hyprland Issues

#### Window Manager Not Starting
```bash
# Check Hyprland logs
journalctl --user -u hyprland -f

# Test Hyprland configuration
hyprland --config ~/.config/hypr/hyprland.conf

# Check graphics support
glxinfo | grep -i renderer
```

#### Keyboard/Mouse Not Working
```bash
# Check input devices
hyprctl devices

# Test input configuration
hyprctl keyword input:kb_layout us

# Check udev rules
ls -la /dev/input/
```

### Waybar Issues

#### Bar Not Appearing
```bash
# Check Waybar logs
journalctl --user -u waybar -f

# Test Waybar configuration
waybar -c ~/.config/waybar/config -s ~/.config/waybar/style.css

# Check module errors
waybar --debug
```

### Application Issues

#### Applications Not Starting
```bash
# Check desktop file
desktop-file-validate ~/.local/share/applications/app.desktop

# Test application directly
alacritty
firefox
dolphin

# Check environment variables
env | grep -i wayland
```

#### Font Problems
```bash
# Check available fonts
fc-list | grep -i jetbrains

# Rebuild font cache
fc-cache -fv

# Test font rendering
echo "Test" | pango-view --font="JetBrains Mono 12" /dev/stdin
```

### Performance Issues

#### High CPU Usage
```bash
# Check Hyprland performance
hyprctl monitors

# Disable effects temporarily
hyprctl keyword decoration:blur:enabled false
hyprctl keyword animations:enabled false

# Check system resources
htop
```

#### Memory Leaks
```bash
# Monitor memory usage
watch -n 1 'ps aux --sort=-%mem | head -10'

# Check for memory leaks
valgrind --tool=memcheck hyprland
```

## Performance Optimization

### Reducing Resource Usage
```nix
# Performance-focused configuration
wayland.windowManager.hyprland.settings = {
  # Reduce decorations
  decoration = {
    rounding = 0;
    blur.enabled = false;
    drop_shadow = false;
  };
  
  # Minimal animations
  animations = {
    enabled = true;
    animation = [
      "global, 1, 2, default"     # Faster animations
    ];
  };
  
  # Performance tweaks
  misc = {
    force_default_wallpaper = 0;  # Disable default wallpaper
    disable_hyprland_logo = true; # Remove logo
  };
};
```

### Laptop Optimization
```nix
# Battery-friendly settings
wayland.windowManager.hyprland.settings = {
  decoration.blur = {
    enabled = false;              # Disable blur to save battery
  };
  
  misc = {
    vfr = true;                   # Variable refresh rate
    vrr = 1;                      # Variable refresh rate
  };
};
```

## Security Considerations

### Wayland Security
- **Screen sharing:** Wayland provides better isolation for screen capture
- **Input isolation:** Better protection against keyloggers
- **Window isolation:** Applications can't spy on other windows

### Application Sandboxing
```nix
# Enable additional security
home.packages = with pkgs; [
  bubblewrap                    # Application sandboxing
  firejail                      # Additional sandboxing
];
```

The desktop module provides a complete, modern Wayland-based desktop environment focused on productivity, aesthetics, and performance while maintaining the flexibility to customize for specific workflows and preferences.