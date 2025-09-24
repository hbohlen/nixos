# /modules/nixos/unfree-packages.nix
{ lib, ... }:

{
  # Centralized unfree package allowlist
  # This prevents conflicts from multiple modules defining allowUnfreePredicate
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    # 1Password family
    "1password"
    "1password-cli"
    "1password-gui"
    
    # Development tools
    "vscode"
    "code"
    
    # Browsers
    "vivaldi"
    "chrome"
    "google-chrome"
    
    # NVIDIA drivers
    "nvidia-x11"
    "nvidia-settings"
    "nvidia-persistenced"
    "libnvidia-ml"
    
    # Gaming
    "steam"
    "steam-unwrapped"
    "discord"
    
    # Archive tools
    "rar"
    "unrar"
    
    # Fingerprint reader
    "libfprint-2-tod1-goodix"
    
    # Communication
    "slack"
    "zoom"
    "teams"
    
    # Media
    "spotify"
    
    # Other common unfree packages
    "nvidia-vaapi-driver"
    "cuda"
    "cudatoolkit"
  ];
}