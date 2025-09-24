
{ pkgs, inputs, ... }:

{
  # ...existing code...

  # GTK and cursor theme
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

  # Swaylock-effects configuration
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
  imports = [
    # Import the official Hyprland Home Manager module.
    inputs.hyprland.homeManagerModules.default
  ];

  # Install essential desktop applications.
  home.packages = with pkgs; [
    # Terminal emulator
    alacritty
    # File manager
    kdePackages.dolphin
    nnn
    ranger
    # Browser
    firefox
    # Screenshot tool
    grim
    slurp
    swappy
    # Image viewer
    imv
    # Wallpaper
    swaybg
    # Clipboard manager
    wl-clipboard
    cliphist
    # Notification daemon (configured below)
    libnotify
    # Terminal utilities
    ripgrep
    fd
    bat
    eza
    zoxide
    fzf
    tmux
    zellij
    lazygit
    # Dev environment tools
    direnv
    nix-direnv
    # Fonts
    nerd-fonts.jetbrains-mono
    swww # Animated wallpaper daemon
    swaylock-effects # Stylish lock screen
    adw-gtk3 # GTK theme
    catppuccin-cursors # Cursor theme
    # Add more packages as needed
  ];

  # Hyprland configuration
  wayland.windowManager.hyprland = {
    enable = true;
    # extraConfig allows for raw hyprland.conf syntax.
    extraConfig = ''
      # Start swww for animated/rotating wallpapers
      exec-once = swww-daemon &
      exec-once = swww img ~/.config/wallpaper.png
      # Start Waybar
      exec-once = waybar

      # Source a file for colors and themes.
      source = ~/.config/hypr/theme.conf
    '';
    settings = {
      # See https://wiki.hyprland.org/Configuring/Variables/ for all options
      monitor = ",preferred,auto,1";

      # Input devices
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
        };
      };

      # General settings
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgb(cba6f7)"; # Catppuccin Mauve
        "col.inactive_border" = "rgb(45475a)"; # Catppuccin Surface0
        layout = "dwindle";
      };

      # Decorations
      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
  # drop_shadow, shadow_range, and shadow_render_power removed (deprecated in recent Hyprland)
  # col.shadow removed (deprecated in recent Hyprland)
      };

      # Animations
      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      # Keybindings
      "$mainMod" = "SUPER";
      bind = [
        "$mainMod, Return, exec, alacritty"
        "$mainMod, Q, killactive,"
        "$mainMod, M, exit,"
        "$mainMod, E, exec, dolphin"
        "$mainMod, V, togglefloating,"
        "$mainMod, R, exec, wofi --show drun"
        "$mainMod, P, pseudo," # dwindle
        "$mainMod, J, togglesplit," # dwindle

        # Move focus with mainMod + arrow keys
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # Switch workspaces with mainMod + [0-9]
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        # Move active window to a workspace with mainMod + SHIFT + [0-9]
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

  # Screenshot bindings
  ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
  "SHIFT, Print, exec, grim - | wl-copy"

  # Custom: Launch Alacritty with mainMod+Shift+Return
  "$mainMod SHIFT, Return, exec, alacritty"

  # Add more custom keybindings below as needed
      ];
    };
  };

  # Waybar: The status bar
  programs.waybar = {
    enable = true;
    style = ''
      /* Use CSS for styling */
      * {
        border: none;
        font-family: "JetBrainsMono Nerd Font";
        font-size: 14px;
      }
      window#waybar {
        background-color: rgba(30, 30, 46, 0.8); /* Catppuccin Base */
        color: #cdd6f4; /* Catppuccin Text */
      }
      #workspaces button {
        padding: 0 5px;
        background-color: transparent;
        color: #cdd6f4;
      }
      #workspaces button.active {
        background-color: #cba6f7; /* Catppuccin Mauve */
        color: #1e1e2e;
      }
    '';
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [ "battery" "disk" "pulseaudio" "network" "cpu" "memory" "tray" ];

        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "10" = "10";
          };
        };
        clock = {
          format = "{:%Y-%m-%d %H:%M:%S}";
          interval = 1;
        };
        battery = {
          format = "{capacity}% {icon}";
          format-icons = [ "" "" "" "" "" ];
        };
        disk = {
          format = "{free} free";
          path = "/";
        };
        pulseaudio = {
          format = "{volume}% {icon}";
          format-muted = "🔇";
          format-icons = [ "🔈" "🔉" "🔊" ];
        };
        network = {
          format-wifi = "({signalStrength}%) 📶";
          format-ethernet = "🌐";
          format-disconnected = "❌";
        };
        cpu = {
          format = "{usage}% 🖥️";
        };
        memory = {
          format = "{percentage}% 🧠";
        };
        tray = {
          spacing = 10;
        };
      };
    };
  };

  # Rofi: The application launcher (using wofi for Wayland)
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

  # Dunst: The notification daemon
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
        background = "#313244"; # Catppuccin Surface0
        foreground = "#cdd6f4"; # Catppuccin Text
        timeout = 10;
      };
      urgency_normal = {
        background = "#1e1e2e"; # Catppuccin Base
        foreground = "#cdd6f4"; # Catppuccin Text
        frame_color = "#cba6f7"; # Catppuccin Mauve
        timeout = 10;
      };
      urgency_critical = {
        background = "#f38ba8"; # Catppuccin Red
        foreground = "#1e1e2e"; # Catppuccin Base
        frame_color = "#f38ba8"; # Catppuccin Red
        timeout = 0;
      };
    };
  };

  # Create the theme file for Hyprland
  xdg.configFile."hypr/theme.conf".text = ''
    # Catppuccin Mocha theme for Hyprland
    # See: https://github.com/catppuccin/catppuccin

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

  # Download a sample wallpaper
  xdg.configFile."wallpaper.png".source = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/wallpapers/nix-wallpaper-simple-dark-gray_bottom.png";
    sha256 = "254cb37fd7584722d09b124f2a9b43c572fbc91a8016de6e3340bd72b924118e";
  };
}