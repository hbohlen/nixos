# /modules/nixos/server.nix
{ config, pkgs, lib, ... }:

{
  # Server-specific SSH configuration with enhanced security
  services.openssh = {
    enable = true;
    settings = {
      # Security hardening
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      PermitEmptyPasswords = false;
      UsePAM = true;
      
      # Connection limits
      MaxAuthTries = 3;
      MaxSessions = 10;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 3;
      
      # Protocol settings
      Protocol = 2;
      X11Forwarding = false;
      AllowTcpForwarding = false;
      GatewayPorts = "no";
      PermitTunnel = "no";
      
      # Logging
      LogLevel = "VERBOSE";
      SyslogFacility = "AUTHPRIV";
      
      # Authentication methods
      AuthorizedKeysFile = ".ssh/authorized_keys";
      ChallengeResponseAuthentication = false;
      KerberosAuthentication = false;
      GSSAPIAuthentication = false;
    };
    
    # Additional security measures
    ports = [ 22 ];
    openFirewall = true;
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
      {
        path = "/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
    ];
  };

  # Unfree packages are managed centrally by modules/nixos/unfree-packages.nix
  # This prevents conflicts with the centralized allowUnfreePredicate configuration

  # Server-specific packages
  environment.systemPackages = with pkgs; [
    # System monitoring and management
    htop
    iotop
    iftop
    nethogs
    lm_sensors
    smartmontools
    
    # Network tools
    curl
    wget
    rsync
    netcat-gnu
    nmap
    tcpdump
    wireshark-cli
    
    # System utilities
    tmux
    screen
    git
    vim
    neovim
    jq
    yq
    
    # Compression tools
    gzip
    bzip2
    xz
    zip
    unzip
    
    # Process management
    procps
    psmisc
    
    # Filesystem tools
    parted
    gptfdisk
    lsof
    strace
    ltrace
    
    # Security tools
    fail2ban
    
    # Backup tools
    borgbackup
    restic
    
    # Container runtime (if needed)
    podman
    docker-compose
    
    # Virtualization (if needed)
    qemu
    libvirt
    virt-manager
    
    # Database clients (if needed)
    postgresql
    mysql-client
    redis
    
    # Development tools (minimal)
    gcc
    python3
    # nodejs - removed to avoid conflicts, use development module if needed
    go
  ];

  # Enable fail2ban for SSH protection
  services.fail2ban.enable = true;

  # System monitoring
  services = {
    # Enable system metrics collection
    prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [ "systemd" "processes" "diskstats" "filefd" "network" "stat" ];
      port = 9100;
    };
    
    # Enable log rotation
    logrotate.enable = true;
  };

  # Security hardening
  security = {
    # AppArmor for server applications
    apparmor.enable = true;
    
    # Audit daemon
    auditd.enable = true;
    
    # Kernel hardening
    protectKernelImage = true;

    # Memory protection
    lockKernelModules = true;
    
    # Filesystem protection
    unprivilegedUsernsClone = false;
    
    # Network protection
    allowSimultaneousMultithreading = false;
  };

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowPing = false;
    logRefusedConnections = true;
    logRefusedPackets = true;
    logRefusedUnicastsOnly = false;
    
    # Allow only essential services
    allowedTCPPorts = [ 22 ]; # SSH
    allowedUDPPorts = [ ];
    
    # Additional trusted interfaces can be configured per host
    trustedInterfaces = [ ];
  };

  # System hardening
  system = {
    # Disable unused services
    disableInstallerTools = true;

    # Enable automatic updates
    autoUpgrade = {
      enable = true;
      dates = "daily";
      allowReboot = false;
    };
  };

  # Performance tuning
  boot = {
    # Kernel parameters for server performance
    kernelParams = [
      "nohz_full=1-15" # CPU isolation for better performance
      "rcu_nocbs=1-15" # RCU callback offloading
      "tsc=reliable"   # Trust TSC clock source
      "processor.max_cstate=1" # Limit C-states for latency
      "idle=poll"      # Use idle=poll for low latency
    ];
    
    # Enable CPU performance governor
    kernelModules = lib.mkAfter [ "cpufreq_performance" ];
  };

  # Resource limits
  systemd.settings.Manager = {
    DefaultLimitNOFILE = 65536;
    DefaultLimitNPROC = 32768;
  };

  # Enable journald persistence and limits
  services.journald = {
    extraConfig = ''
      SystemMaxUse=1G
      SystemKeepFree=2G
      RuntimeMaxUse=256M
      RuntimeKeepFree=512M
      MaxFileSec=1month
    '';
  };
}