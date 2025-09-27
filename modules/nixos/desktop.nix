# /modules/nixos/desktop.nix
{ config, pkgs, lib, username, ... }:

{
  # Define desktop module options
  options = {
    desktop = {
      enable = lib.mkEnableOption "desktop environment";
      environment = lib.mkOption {
        type = lib.types.enum [ "gnome" "hyprland" "both" ];
        default = "both";
        description = "Desktop environment to enable";
      };
    };
  };

  config = lib.mkIf config.desktop.enable {
  # System-wide fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    source-code-pro
  ];

  # Font configuration
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      serif = [ "Noto Serif" ];
      sansSerif = [ "Noto Sans" ];
      monospace = [ "JetBrains Mono" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

  # Enable X11 server for XWayland support
  services.xserver.enable = true;

  # Display Manager and Desktop Environment
  services.displayManager.gdm.enable = true;

  # Audio configuration using PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Disable PulseAudio to avoid conflicts
  services.pulseaudio.enable = false;

  # Enable Wayland and Hyprland
  programs.hyprland.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Desktop-specific unfree packages are now handled in unfree-packages.nix

  # 1Password GUI configuration
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ username ];
  };

  # Bluetooth support for desktop
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Printing support
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Desktop-specific packages
  environment.systemPackages = with pkgs; [
    # Browsers
    firefox

    # Development IDEs and editors
    zed-editor
    vscode
    
    # Productivity and office
    affine
    
    # File management
    nautilus
    
    # System monitoring
    gnome-system-monitor
    
    # Screenshot tools
    flameshot
    
    # Archive tools
    zip
    unzip
    rar
    
    # Document viewers
    evince
    
    # Audio tools (essential for desktop)
    pavucontrol
    easyeffects

    # Secrets management utilities
    gnome-keyring
    libsecret
    seahorse
    libgnome-keyring
  ];

  # Enable desktop services
  services = {
    # GNOME keyring for credential storage
    gnome.gnome-keyring.enable = true;

    # Location services
    geoclue2.enable = true;

    # Desktop Manager configuration
    desktopManager.gnome = {
      enable = true;
      extraGSettingsOverridePackages = [ pkgs.gnome-settings-daemon ];
    };
  };

  services.dbus.packages = [
    pkgs.gnome-keyring
    pkgs.gcr
  ];

  systemd.user.services.gnome-keyring = {
    Unit = {
      Description = "GNOME Keyring Daemon";
      Before = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --foreground --components=secrets,ssh,pkcs11";
      Type = "forking";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # Enable desktop user services
  programs = {
    # DConf for GNOME settings
    dconf.enable = true;
  };

  # Desktop-specific security
  security = {
    # Polkit for privilege escalation
    polkit.enable = true;

    # AppArmor for application sandboxing
    apparmor.enable = true;
    
    # PAM configuration for GNOME keyring integration
    pam.services = {
      login.enableGnomeKeyring = true;
      passwd.enableGnomeKeyring = true;
      gdm-password.enableGnomeKeyring = true;
      gdm-autologin.enableGnomeKeyring = true;
      # For systems using lightdm instead of gdm
      lightdm.enableGnomeKeyring = lib.mkDefault true;
      lightdm-greeter.enableGnomeKeyring = lib.mkDefault true;
    };
  };
};
}