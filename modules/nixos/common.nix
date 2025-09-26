# /modules/nixos/common.nix
{ config, pkgs, lib, username, ... }:

let
  # Create a system-wide rebuild script package
  rebuildn = pkgs.writeShellScriptBin "rebuildn" ''
    #!/usr/bin/env bash
    # System-wide NixOS rebuild helper
    # Automatically finds the NixOS configuration and runs the rebuild script
    
    set -euo pipefail
    
    # Function to find the NixOS configuration root directory
    find_nixos_root() {
        # Try git repository root first (most reliable)
        if git rev-parse --show-toplevel 2>/dev/null; then
            return 0
        fi
        
        # Look for common NixOS configuration locations
        local search_paths=(
            "/etc/nixos"
            "/workspaces/nixos"
            "/nix/config"
            "$HOME/nixos"
            "$HOME/.config/nixos"
        )
        
        # Also search home directories
        for home_dir in /home/*; do
            if [[ -d "$home_dir/nixos" ]]; then
                search_paths+=("$home_dir/nixos")
            fi
        done
        
        for path in "''${search_paths[@]}"; do
            if [[ -f "$path/flake.nix" && -f "$path/scripts/rebuild.sh" ]]; then
                echo "$path"
                return 0
            fi
        done
        
        # Fall back to current directory if it looks right
        if [[ -f "./flake.nix" && -f "./scripts/rebuild.sh" ]]; then
            pwd
            return 0
        fi
        
        echo "Error: Could not find NixOS configuration directory" >&2
        echo "Searched paths: ''${search_paths[*]}" >&2
        echo "Current directory: $(pwd)" >&2
        return 1
    }
    
    # Main execution
    main() {
        local nixos_root
        if ! nixos_root=$(find_nixos_root); then
            exit 1
        fi
        
        if [[ ! -f "$nixos_root/flake.nix" ]]; then
            echo "Error: flake.nix not found in $nixos_root" >&2
            exit 1
        fi
        
        if [[ ! -x "$nixos_root/scripts/rebuild.sh" ]]; then
            echo "Error: rebuild.sh not found or not executable in $nixos_root/scripts/" >&2
            exit 1
        fi
        
        # Change to the NixOS configuration directory and run rebuild
        cd "$nixos_root"
        exec ./scripts/rebuild.sh "$@"
    }
    
    # Run main function with all arguments
    main "$@"
  '';
in
{
  imports = [
    ./unfree-packages.nix
    ./wifi.nix  # Import comprehensive WiFi configuration
  ];
  # Define common module options
  options = {
    common = {
      timezone = lib.mkOption {
        type = lib.types.str;
        default = "America/New_York";
        description = "System timezone";
      };
    };
  };

  config = {
  # Enable Nix flakes and experimental features
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Enable automatic garbage collection
    auto-optimise-store = true;
    # Enable binary cache for faster builds
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 30d";
  };

  # Keep only 7 most recent NixOS generations  
  boot.loader.systemd-boot.configurationLimit = 7;

  # Common packages for all systems
  environment.systemPackages = with pkgs; [
    # Basic utilities
    wget
    curl
    git
    vim
    htop
    tree
    jq
    unzip
    zip
    
    # Note: Development tools moved to development.nix module
    # Import and enable development.nix in host configs that need dev tools
    
    # System rebuild helper (custom package defined above)
    rebuildn
    
    # Security tools
    _1password-cli
    
    # System monitoring
    btop
    iotop
    iftop
    
    # Network tools
    nettools
    iputils
    dnsutils
    
    # File management
    rsync
    ncdu
    ripgrep
    fd
    
    # Process management
    procps
    psmisc
    
    # Compression
    gzip
    bzip2
    xz
  ];

  # WiFi and networking configuration is handled by the WiFi module
  wifi = {
    enable = true;
    powerSaving = "medium";  # Balanced power saving for good connectivity and battery life
    enableFirmware = true;
  };

  # Disable systemd-networkd wait online since NetworkManager manages connectivity
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

  # Configure locale and timezone
  time.timeZone = config.common.timezone;
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  # Enable basic SSH server for remote management
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      UsePAM = true;
      X11Forwarding = false;
      AllowTcpForwarding = false;
      GatewayPorts = "no";
      PermitTunnel = "no";
    };
    openFirewall = true;
  };



  # Podman container support
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers.backend = "podman";
  };

  # System-wide environment variables
  environment.variables = {
    EDITOR = "vim";
    VISUAL = "vim";
    PAGER = "less";
    LESS = "-R";
  };

  # Enable system-wide shell aliases
  environment.shellAliases = {
    ll = "ls -la";
    la = "ls -A";
    l = "ls -CF";
    grep = "grep --color=auto";
    fgrep = "fgrep --color=auto";
    egrep = "egrep --color=auto";
    # System-wide rebuild alias - uses dedicated rebuildn command
    rebuild = "rebuildn";
  };

  # Enable system-wide bash completion
  programs.bash.enable = true;
  programs.bash.completion.enable = true;

  # Enable zsh completion
  programs.zsh.enable = true;
  programs.zsh.enableCompletion = true;

  # Enable man pages
  documentation = {
    enable = true;
    dev.enable = true;
    man.enable = true;
    info.enable = true;
    nixos.enable = true;
  };

  # Enable system monitoring
  services = {
    # Enable journald with persistent storage
    journald = {
      extraConfig = ''
        SystemMaxUse=1G
        SystemKeepFree=2G
        RuntimeMaxUse=256M
        RuntimeKeepFree=512M
        MaxFileSec=1month
      '';
    };
    
    # Enable logrotate
    logrotate.enable = true;
    
    # Enable cron service
    cron.enable = true;
    
    # Enable periodic system cleanup
    fstrim.enable = true;
  };

  # Enable system hardening
  security = {
    # Enable Polkit for privilege escalation
    polkit.enable = true;
    
    # Enable AppArmor
    apparmor.enable = true;
    
    # Enable audit daemon
    auditd.enable = true;
    
    # Enable kernel hardening
    protectKernelImage = true;
    lockKernelModules = true;
    
    # Enable memory protection
    unprivilegedUsernsClone = false;
    
    # Enable network protection
    allowSimultaneousMultithreading = false;
  };

  # Enable kernel modules for common hardware
  boot.kernelModules = [
    "v4l2loopback"
    "loop"
    "tun"
    "tap"
  ];

  # Enable kernel parameters for better security and performance
  boot.kernelParams = [
    "quiet"
    "splash"
    "loglevel=3"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "page_alloc.shuffle=1"
    "slab_nomerge"
    "init_on_alloc=1"
    "init_on_free=1"
    "pti=on"
    "random.trust_cpu=on"
    "random.trust_bootloader=on"
    "iommu=pt"
    "nosmt"
  ];

  # Enable system-wide tmpfiles
  systemd.tmpfiles.rules = [
    "d /tmp 1777 root root -"
    "d /var/tmp 1777 root root -"
    "d /var/log 0755 root root -"
  ];

  # Enable system-wide environment
  environment.etc = {
    "issue".text = ''
      Welcome to NixOS \l (\s \m \r) \t

      System information:
      - Hostname: \n
      - Kernel: \r
      - Architecture: \m
      - Uptime: \U

      For help, type: man nixos-help
    '';
  };

  # Enable system-wide services
  systemd = {
    # Enable emergency mode
    enableEmergencyMode = true;

    # Enable system-wide services
    services = {
      # Enable system cleanup
      cleanup = {
        description = "System Cleanup Service";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.coreutils}/bin/rm -rf /tmp/*";
        };
      };
    };
  };

  # Enable system-wide configuration
  system = {
    # Enable automatic system updates
    autoUpgrade = {
      enable = true;
      dates = "daily";
      allowReboot = false;
      operation = "boot";
    };
  };
  };
}