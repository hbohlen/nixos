# server.nix - Server Hardening and Monitoring

**Location:** `modules/nixos/server.nix`

## Purpose

Provides comprehensive server hardening, security configuration, and monitoring capabilities for headless server deployments. Focuses on security, performance, and reliability for production server environments.

## Dependencies

- **Integration:** Used independently or with minimal common.nix
- **External:** Security and monitoring packages, server-specific tools
- **Network:** Designed for headless operation with SSH access

## Features

### Enhanced SSH Security

#### Hardened SSH Configuration
```nix
services.openssh = {
  enable = true;
  settings = {
    # Authentication security
    PasswordAuthentication = false;
    PermitRootLogin = "no";
    PermitEmptyPasswords = false;
    UsePAM = true;
    
    # Connection limits and timeouts
    MaxAuthTries = 3;
    MaxSessions = 10;
    ClientAliveInterval = 300;       # 5 minutes
    ClientAliveCountMax = 3;
    
    # Protocol settings  
    Protocol = 2;
    X11Forwarding = false;
    AllowTcpForwarding = false;
    GatewayPorts = "no";
    PermitTunnel = "no";
    
    # Logging and monitoring
    LogLevel = "VERBOSE";
    SyslogFacility = "AUTHPRIV";
    
    # Key-based authentication
    AuthorizedKeysFile = ".ssh/authorized_keys";
    ChallengeResponseAuthentication = false;
    KerberosAuthentication = false;
    GSSAPIAuthentication = false;
  };
  
  # Host keys configuration
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
```

### System Security Hardening

#### Comprehensive Security Configuration
```nix
security = {
  # Application sandboxing
  apparmor.enable = true;
  
  # System audit logging
  auditd.enable = true;
  
  # Kernel protection
  protectKernelImage = true;
  lockKernelModules = true;
  
  # Memory protection
  unprivilegedUsernsClone = false;
  
  # Network protection
  allowSimultaneousMultithreading = false;
};
```

#### Firewall Configuration
```nix
networking.firewall = {
  enable = true;
  allowPing = false;                    # Disable ping for security
  logRefusedConnections = true;
  logRefusedPackets = true;
  logRefusedUnicastsOnly = false;
  
  # Minimal open ports
  allowedTCPPorts = [ 22 ];            # SSH only
  allowedUDPPorts = [ ];
  
  # Additional interfaces can be configured per host
  trustedInterfaces = [ ];
};
```

### Intrusion Detection and Prevention

#### Fail2Ban Configuration
```nix
services.fail2ban.enable = true;
```
Automatically blocks IP addresses that show malicious signs such as too many password failures.

### System Monitoring

#### Prometheus Node Exporter
```nix
services.prometheus.exporters.node = {
  enable = true;
  enabledCollectors = [ 
    "systemd" 
    "processes" 
    "diskstats" 
    "filefd" 
    "network" 
    "stat" 
  ];
  port = 9100;
};
```

#### Log Management
```nix
services.logrotate.enable = true;

services.journald = {
  extraConfig = ''
    SystemMaxUse=1G
    SystemKeepFree=2G
    RuntimeMaxUse=256M
    RuntimeKeepFree=512M
    MaxFileSec=1month
  '';
};
```

### Essential Server Packages

#### System Administration Tools
```nix
environment.systemPackages = with pkgs; [
  # System monitoring
  htop iotop iftop nethogs lm_sensors smartmontools
  
  # Network tools
  curl wget rsync netcat-gnu nmap tcpdump wireshark-cli
  
  # System utilities
  tmux screen git vim neovim jq yq
  
  # Process and file management
  procps psmisc lsof strace ltrace
  
  # Filesystem tools
  parted gptfdisk
  
  # Compression
  gzip bzip2 xz zip unzip
  
  # Security tools
  fail2ban
  
  # Backup tools
  borgbackup restic
  
  # Container runtime
  podman docker-compose
  
  # Virtualization
  qemu libvirt virt-manager
  
  # Database clients
  postgresql mysql-client redis
  
  # Development tools (minimal)
  gcc python3 go
];
```

### Performance Optimization

#### Server-Specific Kernel Parameters
```nix
boot = {
  kernelParams = [
    "nohz_full=1-15"           # CPU isolation for performance
    "rcu_nocbs=1-15"           # RCU callback offloading
    "tsc=reliable"             # Trust TSC clock source
    "processor.max_cstate=1"   # Limit C-states for latency
    "idle=poll"                # Use idle=poll for low latency
  ];
  
  # Performance-oriented modules
  kernelModules = [ "cpufreq_performance" ];
};
```

#### Resource Limits
```nix
systemd.settings.Manager = {
  DefaultLimitNOFILE = 65536;          # File descriptor limit
  DefaultLimitNPROC = 32768;           # Process limit
};
```

### System Maintenance

#### Automatic Updates
```nix
system = {
  # Disable installer tools for security
  disableInstallerTools = true;
  
  # Automatic system updates
  autoUpgrade = {
    enable = true;
    dates = "daily";
    allowReboot = false;          # Manual reboot control
  };
};
```

## Usage Examples

### Basic Server Setup
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/common.nix
    ../../modules/nixos/server.nix
  ];
  
  # Server module provides comprehensive hardening
  # SSH keys should be configured in users.nix
}
```

### Web Server Configuration
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/common.nix
    ../../modules/nixos/server.nix
  ];
  
  # Add web server specific configurations
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
  };
  
  # Open HTTP/HTTPS ports
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  
  # SSL certificates
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@example.com";
  };
}
```

### Database Server
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/server.nix
  ];
  
  # PostgreSQL configuration
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    dataDir = "/var/lib/postgresql/15";
    
    authentication = ''
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      local   all             postgres                                peer
      local   all             all                                     md5
      host    all             all             127.0.0.1/32            md5
      host    all             all             ::1/128                 md5
    '';
    
    settings = {
      shared_buffers = "256MB";
      effective_cache_size = "1GB";
      maintenance_work_mem = "64MB";
      checkpoint_completion_target = 0.7;
      wal_buffers = "7864kB";
      default_statistics_target = 100;
      random_page_cost = 4;
      effective_io_concurrency = 2;
    };
  };
  
  # Database backup
  services.postgresqlBackup = {
    enable = true;
    databases = [ "postgres" ];
  };
  
  # Open database port (if needed)
  networking.firewall.allowedTCPPorts = [ 5432 ];
}
```

### Container Host
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/server.nix
  ];
  
  # Enhanced container support
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    
    # Enable nested virtualization if needed
    libvirtd = {
      enable = true;
      qemu = {
        runAsRoot = false;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [ pkgs.OVMFFull.fd ];
        };
      };
    };
  };
  
  # Container management tools
  environment.systemPackages = with pkgs; [
    docker-compose
    kubernetes
    kubectl
    podman-compose
    dive            # Docker image analysis
  ];
}
```

### Monitoring Server
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/server.nix
  ];
  
  # Prometheus monitoring
  services.prometheus = {
    enable = true;
    port = 9090;
    
    scrapeConfigs = [
      {
        job_name = "node-exporter";
        static_configs = [{
          targets = [ "localhost:9100" ];
        }];
      }
    ];
  };
  
  # Grafana visualization
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
      };
      security = {
        admin_password = "$__file{/etc/grafana/admin-password}";
      };
    };
  };
  
  # Reverse proxy for monitoring services
  services.nginx = {
    enable = true;
    virtualHosts."monitoring.example.com" = {
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:3000";
    };
  };
  
  networking.firewall.allowedTCPPorts = [ 80 443 9090 ];
}
```

## Advanced Security Configuration

### Enhanced Firewall Rules
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/server.nix
  ];
  
  # Custom iptables rules
  networking.firewall.extraCommands = ''
    # Rate limiting for SSH
    iptables -A nixos-fw -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
    iptables -A nixos-fw -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
    
    # Allow established connections
    iptables -A nixos-fw -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    
    # Log dropped packets
    iptables -A nixos-fw -j LOG --log-prefix "nixos-fw: "
  '';
}
```

### SELinux/AppArmor Profiles
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/server.nix
  ];
  
  # Enhanced AppArmor profiles
  security.apparmor.packages = with pkgs; [
    apparmor-profiles
    apparmor-utils
  ];
  
  # Custom AppArmor profiles
  security.apparmor.profiles = {
    nginx = {
      enforce = true;
      profile = ''
        #include <tunables/global>
        
        /usr/sbin/nginx {
          #include <abstractions/base>
          #include <abstractions/nameservice>
          
          capability net_bind_service,
          capability setuid,
          capability setgid,
          
          /etc/nginx/** r,
          /var/log/nginx/** w,
          /var/cache/nginx/** rw,
        }
      '';
    };
  };
}
```

### Audit Configuration
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/server.nix
  ];
  
  # Comprehensive audit rules
  security.audit.rules = [
    # Monitor file access
    "-w /etc/passwd -p wa -k identity"
    "-w /etc/group -p wa -k identity"
    "-w /etc/shadow -p wa -k identity"
    
    # Monitor privilege escalation
    "-w /bin/su -p x -k priv_esc"
    "-w /usr/bin/sudo -p x -k priv_esc"
    
    # Monitor network configuration
    "-w /etc/hosts -p wa -k network"
    "-w /etc/sysconfig/network -p wa -k network"
    
    # Monitor SSH
    "-w /etc/ssh/sshd_config -p wa -k sshd"
    
    # System calls
    "-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change"
    "-a always,exit -F arch=b64 -S clock_settime -k time-change"
  ];
}
```

## Performance Tuning

### Network Performance
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/server.nix
  ];
  
  # Network performance tuning
  boot.kernel.sysctl = {
    # TCP performance
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.ipv4.tcp_rmem" = "4096 87380 134217728";
    "net.ipv4.tcp_wmem" = "4096 65536 134217728";
    
    # Network security
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    
    # Connection tracking
    "net.netfilter.nf_conntrack_max" = 524288;
  };
}
```

### Storage Performance
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/server.nix
  ];
  
  # I/O scheduler optimization
  services.udev.extraRules = ''
    # SSD optimization
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    
    # HDD optimization  
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
  '';
  
  # Filesystem optimizations
  boot.kernel.sysctl = {
    "vm.dirty_background_ratio" = 1;
    "vm.dirty_ratio" = 5;
    "vm.swappiness" = 10;
  };
}
```

## Backup and Recovery

### Automated Backup Configuration
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/server.nix
  ];
  
  # Borg backup configuration
  services.borgbackup.jobs."server-backup" = {
    paths = [
      "/home"
      "/var/lib"
      "/etc"
    ];
    
    exclude = [
      "/var/lib/docker"
      "/var/lib/systemd"
      "/var/lib/cache"
    ];
    
    repo = "/backup/borg-repo";
    compression = "auto,zstd";
    startAt = "daily";
    
    preHook = ''
      echo "Starting backup at $(date)"
    '';
    
    postHook = ''
      echo "Backup completed at $(date)"
    '';
  };
  
  # System state backup
  services.restic.backups = {
    daily = {
      repository = "sftp:backup-server:/backups/restic";
      passwordFile = "/etc/restic/password";
      
      paths = [
        "/home"
        "/var/lib/postgresql"
        "/etc"
      ];
      
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
  };
}
```

## Monitoring and Alerting

### Comprehensive Monitoring
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/server.nix
  ];
  
  # System monitoring with alerting
  services.prometheus.rules = [
    ''
      groups:
      - name: system.rules
        rules:
        - alert: HighCPUUsage
          expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "High CPU usage detected"
            
        - alert: HighMemoryUsage
          expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 90
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "High memory usage detected"
            
        - alert: DiskSpaceLow
          expr: node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} * 100 < 10
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "Low disk space on root filesystem"
    ''
  ];
  
  # Log monitoring
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 3031;
        grpc_listen_port = 9096;
      };
      
      clients = [
        { url = "http://localhost:3100/loki/api/v1/push"; }
      ];
      
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = "server";
            };
          };
          relabel_configs = [
            {
              source_labels = ["__journal__systemd_unit"];
              target_label = "unit";
            }
          ];
        }
      ];
    };
  };
}
```

## Troubleshooting

### Security Issues

#### SSH Access Problems
```bash
# Check SSH service status
systemctl status sshd

# Test SSH configuration
sudo sshd -T

# Check fail2ban status
sudo fail2ban-client status sshd

# View auth logs
sudo journalctl -u sshd -f
```

#### Firewall Issues
```bash
# Check firewall status
sudo iptables -L -n -v

# Test connectivity
nmap -p 22 localhost

# Check blocked IPs
sudo fail2ban-client status
```

### Performance Issues

#### High Load Investigation
```bash
# Check system load
uptime
htop

# Check I/O wait
iostat -x 1

# Check network usage
iftop
nethogs
```

#### Memory Issues
```bash
# Check memory usage
free -h
ps aux --sort=-%mem | head

# Check for memory leaks
valgrind --tool=memcheck program

# Monitor memory over time
vmstat 5
```

### Service Issues

#### Service Failures
```bash
# Check service status
systemctl status service-name

# View service logs
journalctl -u service-name -f

# Check dependencies
systemctl list-dependencies service-name
```

#### Database Issues
```bash
# PostgreSQL status
sudo -u postgres psql -c "SELECT version();"

# Check connections
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"

# Database performance
sudo -u postgres psql -c "SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;"
```

## Security Maintenance

### Regular Security Tasks
```bash
# Update system packages
sudo nixos-rebuild switch

# Check for security updates
nix-channel --update
nix-env -u

# Review system logs
sudo journalctl --since "yesterday" | grep -i "error\|fail\|warn"

# Check for suspicious activity
sudo ausearch -i -m avc
sudo fail2ban-client status
```

### Security Auditing
```bash
# Check open ports
sudo netstat -tulpn

# Check running processes
ps aux

# Check system integrity
sudo aide --check

# Scan for vulnerabilities
nmap -sV localhost
```

## Integration Notes

### With Common Module
Server module extends common.nix with:
- Enhanced security configurations
- Server-specific package selections
- Performance optimizations for server workloads

### With Impermanence
Server deployments with impermanence should persist:
- Application data directories
- Configuration files
- SSL certificates
- Database files
- Log files (selectively)

### With Backup Systems
Regular backup strategies should include:
- System configuration
- Application data
- User data
- Database dumps
- SSL certificates and keys

The server module provides the foundation for secure, reliable server deployments with comprehensive monitoring and maintenance capabilities.