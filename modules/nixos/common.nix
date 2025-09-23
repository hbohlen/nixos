# /modules/nixos/common.nix
{ config, pkgs, lib, username, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable Wayland and PipeWire for audio/video.
  # Temporarily disabled for ISO install to save space
  # services.xserver = {
  #   enable = true; # Still needed for XWayland.
  # };
  # services.displayManager.gdm.enable = true;
  # services.desktopManager.gnome.enable = true;
  
  # Disable power-profiles-daemon which conflicts with TLP
  services.power-profiles-daemon.enable = false;
  
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Enable Hyprland-specific services.
  # Temporarily disabled for ISO install to save space
  # programs.hyprland.enable = true;
  # xdg.portal = {
  #   enable = true;
  #   extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  # };

  # Enable the unfree packages we need (minimal set for ISO install).
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "1password"
    "1password-cli"
    # "steam"          # Temporarily disabled
    # "vscode"         # Temporarily disabled
    # "vivaldi"        # Temporarily disabled
    # "nvidia-x11"     # Temporarily disabled
    # "nvidia-settings" # Temporarily disabled
  ];
  programs._1password-gui = {
    enable = true;
    # Enable PolKit for system authentication features (e.g., fingerprint unlock).
    polkitPolicyOwners = [ username ];
  };

  # Common packages for all systems (minimal set for ISO install)
  environment.systemPackages = with pkgs; [
    # Basic utilities only
    wget
    curl
    git
    vim
    htop
    # gcc         # Temporarily disabled
    # clang       # Temporarily disabled
    # python3     # Temporarily disabled
    # nodejs      # Temporarily disabled
    # gnumake     # Temporarily disabled
    # cmake       # Temporarily disabled
    # docker      # Temporarily disabled
    # podman      # Temporarily disabled
    # go          # Temporarily disabled
    # rustc       # Temporarily disabled
    # cargo       # Temporarily disabled
    jq
    unzip
    zip
    tree
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
    noto-fonts-cjk-sans
    noto-fonts-emoji
    nerd-fonts.jetbrains-mono
    # Add more fonts as needed
  ];

  # Security configurations
  security.sudo.wheelNeedsPassword = true; # Require sudo password for wheel group
  
  # Bluetooth support
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Podman container support (temporarily disabled for ISO install)
  # virtualisation.podman.enable = true;
}