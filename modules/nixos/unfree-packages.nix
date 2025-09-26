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
    
    # Archive tools
    "rar"
    "unrar"
    
    # Fingerprint reader
    "libfprint-2-tod1-goodix"
    
    # Firmware packages
    "linux-firmware"
    "b43-firmware"
    "broadcom-bt-firmware"
    "facetimehd-firmware"
    "rtl8761b-firmware"
    "intel-ucode"
    "amd-ucode"
    "sof-firmware"
    "alsa-firmware"
    "wireless-regdb"
    "intel2200BGFirmware"
    "rt73-firmware"
    "zd1211fw"
    
    # Other common unfree packages
    "nvidia-vaapi-driver"
    "cuda"
    "cudatoolkit"
  ];
}