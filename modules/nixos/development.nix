# /modules/nixos/development.nix
# Development tools and environments
# This module can be conditionally imported by hosts that need development tools
{ config, pkgs, lib, ... }:

{
  options.development = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable development tools and environments";
    };
  };

  config = lib.mkIf config.development.enable {
    # System-wide development packages (minimal set)
    environment.systemPackages = with pkgs; [
      # Core development tools
      gcc
      clang
      gnumake
      cmake
      pkg-config
      
      # Version control
      git
      
      # Programming languages and package managers
      python3
      nodejs
      nodePackages.npm
      go
      rustc
      cargo
      
      # Python package management
      uv # Modern Python package management
      
      # Container runtime for development
      podman
      podman-compose
    ];

    # Enable container support
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };

    # Development-friendly kernel parameters
    boot.kernel.sysctl = {
      "fs.inotify.max_user_watches" = 524288; # For file watchers in IDEs
      "vm.max_map_count" = 262144; # For containers and development tools
    };
  };
}