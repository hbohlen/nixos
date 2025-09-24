# /modules/nixos/common.nix
{ config, pkgs, lib, username, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable Wayland and PipeWire for audio/video.
  services.xserver = {
    enable = true; # Still needed for XWayland.
  };
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  
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

  # Enable unfree packages - comprehensive list for all hosts
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    # 1Password family
    "1password"
    "1password-cli"
    "1password-gui"
    # Development tools
    "vscode"
    "code"
    # Gaming (for desktop)
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
    # Add more as needed
  ];
  programs._1password-gui = {
    enable = true;
    # Enable PolKit for system authentication features (e.g., fingerprint unlock).
    polkitPolicyOwners = [ username ];
  };

  # Common packages for all systems
  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    vim
    htop
    gcc
    clang
    python3
    nodejs
    gnumake
    cmake
    docker
    podman
    go
    rustc
    cargo
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

  # Podman container support
  virtualisation.podman.enable = true;
}