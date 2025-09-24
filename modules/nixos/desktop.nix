# /modules/nixos/desktop.nix
{ config, pkgs, lib, ... }:

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
    nerd-fonts.source-code-pro
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
  services.desktopManager.gnome.enable = true;

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

  # Desktop-specific unfree packages
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    # 1Password family
    "1password"
    "1password-cli"
    "1password-gui"
    # Development tools
    "vscode"
    "code"
    # Gaming
    "steam"
    "steam-unwrapped"
    "discord"
    # Browsers
    "vivaldi"
    "chrome"
    # NVIDIA drivers
    "nvidia-x11"
    "nvidia-settings"
    "nvidia-persistenced"
    "libnvidia-ml"
  ];

  # 1Password GUI configuration
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "hbohlen" ];
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
    # Desktop utilities
    firefox
    thunderbird
    gimp
    libreoffice
    vlc
    # Audio/video tools
    pavucontrol
    easyeffects
    # File management
    gnome.nautilus
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
    # Image viewers
    eog
  ];

  # Enable desktop services
  services = {
    # GNOME keyring for credential storage
    gnome.gnome-keyring.enable = true;

    # Location services
    geoclue2.enable = true;

    # User directories
    xserver.desktopManager.gnome.extraGSettingsOverridePackages = [ pkgs.gnome.gnome-settings-daemon ];
  };

  # Enable desktop user services
  programs = {
    # DConf for GNOME settings
    dconf.enable = true;

    # SSH agent for key management
    ssh.startAgent = true;
  };

  # Desktop-specific security
  security = {
    # Polkit for privilege escalation
    polkit.enable = true;

    # AppArmor for application sandboxing
    apparmor.enable = true;
  };
}