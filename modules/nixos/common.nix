# /modules/nixos/common.nix
{ config, pkgs, lib, username, ... }:

{
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

  # Allow essential unfree packages
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    # 1Password
    "1password"
    "1password-cli"
    "1password-gui"
    # Browsers
    "vivaldi"
    "chrome"
    # Archive tools
    "rar"
    # Fingerprint reader
    "libfprint-2-tod1-goodix"
    # NVIDIA drivers
    "nvidia-x11"
    "nvidia-settings"
    "nvidia-persistenced"
    "libnvidia-ml"
  ];

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
    
    # Development tools
    gcc
    clang
    python3
    nodejs
    gnumake
    cmake
    go
    rustc
    cargo
    
    # Container runtime
    podman
    
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

  # Setup networking with NetworkManager
  networking.networkmanager = {
    enable = true;
    # Enable WiFi power saving by default (can be overridden)
    wifi.powersave = true;
  };

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

    # Enable system state version
    stateVersion = "25.05";
  };
  };
}