# /modules/nixos/common.nix
{ config, pkgs, lib, username, ... }:

{
  # Enable Wayland and PipeWire for audio/video.
  services.xserver = {
    enable = true; # Still needed for XWayland.
    displayManager.gdm.enable = true; # Or another Wayland-compatible DM.
    desktopManager.gnome.enable = true; # GDM requires this.
  };
  
  # Disable power-profiles-daemon which conflicts with TLP
  services.power-profiles-daemon.enable = false;
  
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Enable Hyprland-specific services.
  programs.hyprland.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Enable the unfree packages we need.
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "1password"
    "1password-cli"
    "1password-gui"
    "vscode"
    "vscode-extension-ms-vsliveshare-vsliveshare"
    "slack"
    "discord"
    "spotify"
  ];

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Enable PolKit for system authentication features (e.g., fingerprint unlock).
    polkitPolicyOwners = [ username ];
  };

  # Common packages for all systems
  environment.systemPackages = with pkgs; [
    # Basic utilities
    wget
    curl
    git
    vim
    htop
    # Add more packages as needed
  ];

  # Setup networking with NetworkManager
  networking.networkmanager.enable = true;

  # Configure locale and timezone (customize for your location)
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable SSH server for remote management
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # System-wide fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    # Add more fonts as needed
  ];

  # Security configurations
  security.sudo.wheelNeedsPassword = true; # Require sudo password for wheel group
  
  # Bluetooth support
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
}