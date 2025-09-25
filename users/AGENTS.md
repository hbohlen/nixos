# User Configurations - Home Manager Documentation

## Directory Purpose
This directory contains user-specific Home Manager configurations that define individual user accounts and their personal computing environments. Each user configuration manages applications, dotfiles, services, and preferences that operate in user space without requiring system-level privileges.

## User Configuration Architecture

### Home Manager Integration Pattern
```
┌─────────────────────────────────────────────┐
│              User Configuration             │
│  ┌─────────────────────────────────────────┐ │
│  │           Personal Layer                │ │
│  │  • Individual preferences              │ │
│  │  • Personal packages                   │ │
│  │  • Custom configurations              │ │
│  │  • User-specific dotfiles             │ │
│  └─────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────┐ │
│  │         Shared Modules Layer            │ │
│  │  • Desktop environment                 │ │
│  │  • Development tools                   │ │
│  │  • Secret management                   │ │
│  │  • Common applications                 │ │
│  └─────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────┐ │
│  │        System Integration Layer         │ │
│  │  • System user accounts               │ │
│  │  • Group memberships                  │ │
│  │  • System service integration         │ │
│  │  • Hardware access permissions        │ │
│  └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

## User Directory Structure and Configuration

### Standard User Directory Layout
```
users/
└── username/
    ├── default.nix    # System-level user account definition
    ├── home.nix       # Home Manager configuration entry point
    ├── packages/      # User-specific package configurations
    ├── programs/      # Application-specific configurations
    ├── services/      # User service definitions
    └── dotfiles/      # Personal dotfiles and configurations
```

### User Account Definition (`default.nix`)
```nix
# System-level user account configuration
{ config, pkgs, lib, ... }:

{
  # User account definition
  users.users.username = {
    isNormalUser = true;
    description = "Full Name";
    shell = pkgs.zsh;  # or preferred shell
    
    # Group memberships for hardware access and privileges
    extraGroups = [
      "wheel"          # sudo access
      "networkmanager" # network management
      "audio"          # audio devices
      "video"          # video devices
      "input"          # input devices
      "plugdev"        # USB devices
      "docker"         # Docker (if enabled)
      "libvirtd"       # Virtualization (if enabled)
    ];
    
    # SSH public keys for authentication
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleKey user@example.com"
    ];
    
    # Initial password for first login (change immediately)
    hashedPassword = "$6$rounds=4096$salt$hashedpassword";
    # Or use passwordFile for security
    # passwordFile = "/persist/secrets/user-password";
  };
  
  # User-specific system configuration
  programs.zsh.enable = true;  # Enable shell system-wide
}
```

### Home Manager Configuration (`home.nix`)
```nix
# User environment configuration
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # Shared Home Manager modules
    ../../modules/home-manager/desktop.nix
    ../../modules/home-manager/opnix.nix
    
    # User-specific modules
    ./programs
    ./services  
  ];

  # Home Manager settings
  home = {
    username = "username";
    homeDirectory = "/home/username";
    stateVersion = "25.05";
  };

  # Personal package selection
  home.packages = with pkgs; [
    # Development tools
    vscode-with-extensions
    jetbrains.idea-ultimate
    postman
    
    # Productivity applications
    obsidian
    notion-app-enhanced
    libreoffice-fresh
    
    # Media and graphics
    gimp-with-plugins
    blender
    obs-studio
    
    # Communication
    discord
    slack
    zoom-us
    
    # Utilities
    tree
    htop
    neofetch
    bat
    fd
    ripgrep
  ];

  # Program configurations
  programs = {
    # Terminal and shell
    alacritty = {
      enable = true;
      settings = {
        window.opacity = 0.95;
        font.size = 12;
        colors.primary = {
          background = "0x1e1e1e";
          foreground = "0xd4d4d4";
        };
      };
    };

    # Git configuration
    git = {
      enable = true;
      userName = "Full Name";
      userEmail = "user@example.com";
      signing = {
        key = "GPG_KEY_ID";
        signByDefault = true;
      };
      extraConfig = {
        init.defaultBranch = "main";
        push.default = "simple";
        pull.rebase = false;
      };
    };

    # Shell configuration
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      
      shellAliases = {
        ll = "ls -alF";
        la = "ls -A";
        l = "ls -CF";
        rebuild = "./scripts/rebuild.sh";
        update = "nix flake update && ./scripts/rebuild.sh";
      };
      
      oh-my-zsh = {
        enable = true;
        theme = "robbyrussell";
        plugins = [
          "git"
          "docker"
          "kubectl"
          "history-substring-search"
        ];
      };
    };

    # Development environment
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
  };

  # Services and daemons
  services = {
    # GPG agent for key management
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      pinentryPackage = pkgs.pinentry-gtk2;
    };
    
    # Notification daemon
    dunst = {
      enable = true;
      settings = {
        global = {
          follow = "keyboard";
          format = "<b>%s</b>\\n%b";
          sort = "yes";
          indicate_hidden = "yes";
        };
      };
    };
  };

  # XDG configuration
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "$HOME/Desktop";
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      music = "$HOME/Music";
      pictures = "$HOME/Pictures";
      videos = "$HOME/Videos";
    };
  };
}
```

## Role-Based User Configurations

### Developer User Profile
```nix
# Enhanced configuration for software developers
{ config, pkgs, ... }:

{
  # Development-focused package selection
  home.packages = with pkgs; [
    # Programming languages and runtimes
    nodejs_20
    python3
    rustc
    cargo
    go
    openjdk17
    
    # Development tools
    docker-compose
    kubernetes-helm
    terraform
    ansible
    
    # IDEs and editors
    vscode-with-extensions
    jetbrains.idea-ultimate
    jetbrains.webstorm
    neovim
    
    # Database tools
    postgresql
    redis
    sqlite
    dbeaver-bin
    
    # API and testing tools
    postman
    insomnia
    curl
    jq
    
    # Version control and collaboration
    gh  # GitHub CLI
    gitlab-runner
    pre-commit
  ];

  # Development-specific program configurations
  programs = {
    # Enhanced Git configuration for development
    git = {
      enable = true;
      signing.signByDefault = true;
      extraConfig = {
        core.editor = "code --wait";
        merge.tool = "vscode";
        diff.tool = "vscode";
        "mergetool \"vscode\"".cmd = "code --wait $MERGED";
        "difftool \"vscode\"".cmd = "code --wait --diff $LOCAL $REMOTE";
      };
    };

    # SSH configuration for development workflows
    ssh = {
      enable = true;
      matchBlocks = {
        "github.com" = {
          hostname = "github.com";
          user = "git";
          identityFile = "~/.ssh/id_ed25519";
        };
        "gitlab.com" = {
          hostname = "gitlab.com";
          user = "git";
          identityFile = "~/.ssh/id_ed25519";
        };
      };
    };

    # Development shell configuration
    zsh.shellAliases = {
      # Docker shortcuts
      dc = "docker-compose";
      dcup = "docker-compose up -d";
      dcdown = "docker-compose down";
      
      # Kubernetes shortcuts
      k = "kubectl";
      kgp = "kubectl get pods";
      kgs = "kubectl get services";
      
      # Development workflow
      dev = "nix develop";
      build = "nix build";
      test = "nix flake check";
    };
  };

  # Development services
  services = {
    # Lorri for direnv integration (deprecated, using nix-direnv)
    # Can add other development-related services here
  };
}
```

### Content Creator Profile
```nix
# Configuration optimized for content creation and media work
{ config, pkgs, ... }:

{
  # Media-focused packages
  home.packages = with pkgs; [
    # Video editing and production
    davinci-resolve
    obs-studio
    kdenlive
    handbrake
    
    # Audio production
    audacity
    reaper
    lmms
    
    # Graphics and design
    gimp-with-plugins
    inkscape
    blender
    krita
    
    # Photography
    darktable
    rawtherapee
    
    # 3D and modeling
    freecad
    meshlab
    
    # Screen capture and streaming
    flameshot
    simplescreenrecorder
    
    # Media utilities
    ffmpeg-full
    imagemagick
    exiftool
  ];

  # Media-specific configurations
  programs = {
    # Enhanced file manager for media files
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-media-tags-plugin
      ];
    };
  };
}
```

### System Administrator Profile
```nix
# Configuration for system administration tasks
{ config, pkgs, ... }:

{
  # System administration packages
  home.packages = with pkgs; [
    # System monitoring and analysis
    htop
    iotop
    nethogs
    wireshark
    nmap
    
    # Network tools
    dig
    traceroute
    tcpdump
    iperf3
    
    # System utilities
    rsync
    rclone
    borgbackup
    
    # Virtualization
    virt-manager
    vagrant
    
    # Cloud tools
    awscli2
    azure-cli
    google-cloud-sdk
    
    # Security tools
    gnupg
    pass
    bitwarden-cli
  ];

  # Administrative shell configuration
  programs.zsh.shellAliases = {
    # System monitoring
    ports = "netstat -tulanp";
    processes = "ps auxf";
    
    # Log viewing
    logs = "journalctl -f";
    errors = "journalctl -p err";
    
    # System maintenance
    cleanup = "nix-collect-garbage -d";
    update-system = "nixos-rebuild switch --upgrade";
  };
}
```

## User-Specific Configuration Management

### Dotfiles and Personal Configurations
```nix
# Personal configuration files management
{ config, ... }:

{
  # Dotfiles management using Home Manager
  home.file = {
    # Custom configuration files
    ".vimrc".source = ./dotfiles/vimrc;
    ".tmux.conf".source = ./dotfiles/tmux.conf;
    ".gitignore_global".source = ./dotfiles/gitignore_global;
    
    # Application-specific configurations
    ".config/alacritty/alacritty.yml".source = ./dotfiles/alacritty.yml;
    ".config/rofi/config.rasi".source = ./dotfiles/rofi-config.rasi;
  };

  # XDG configuration directories
  xdg.configFile = {
    # VSCode settings and extensions
    "Code/User/settings.json".source = ./dotfiles/vscode-settings.json;
    "Code/User/keybindings.json".source = ./dotfiles/vscode-keybindings.json;
    
    # Terminal configurations
    "kitty/kitty.conf".source = ./dotfiles/kitty.conf;
    "wezterm/wezterm.lua".source = ./dotfiles/wezterm.lua;
  };
}
```

### Environment Variables and Paths
```nix
# User environment configuration
{ config, pkgs, ... }:

{
  # Session variables
  home.sessionVariables = {
    EDITOR = "code";
    BROWSER = "firefox";
    TERMINAL = "alacritty";
    
    # Development environment
    GOPATH = "$HOME/go";
    CARGO_HOME = "$HOME/.cargo";
    
    # Application preferences
    PAGER = "less -R";
    LESS = "-R";
  };

  # Session path modifications
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/go/bin"
    "$HOME/.cargo/bin"
    "$HOME/scripts"
  ];
}
```

## User Configuration Best Practices

### Security and Privacy
- **SSH Key Management**: Use dedicated SSH keys for different services
- **GPG Configuration**: Set up GPG for code signing and encryption
- **Secret Management**: Use 1Password integration for credentials
- **Browser Security**: Configure browser with privacy and security extensions
- **Application Sandboxing**: Use appropriate application isolation

### Performance Optimization
- **Resource Monitoring**: Monitor user application resource usage
- **Startup Optimization**: Optimize shell and application startup times
- **Cache Management**: Configure appropriate cache sizes for applications
- **Background Services**: Minimize unnecessary background services

### Maintenance Procedures
```bash
# User configuration maintenance
home-manager switch --flake .#username    # Apply user configuration
home-manager generations                  # List user generations
home-manager remove-generations 7d       # Clean old generations

# User package management
home-manager packages                     # List installed packages
nix-env --list-generations               # List package generations
nix-collect-garbage --delete-older-than 7d  # Clean package cache
```

## Integration with System Configuration

### User-System Coordination
- **Group Memberships**: Coordinate user groups with system services
- **Hardware Access**: Ensure proper hardware device access permissions
- **Service Integration**: Integrate user services with system services
- **Resource Limits**: Configure appropriate user resource limits

### Multi-User Considerations
- **Shared Resources**: Manage shared system resources appropriately
- **User Isolation**: Maintain proper user environment isolation
- **Common Configurations**: Share common configurations through modules
- **Conflict Resolution**: Handle conflicting user preferences gracefully

This comprehensive user configuration documentation provides detailed guidance for creating, managing, and maintaining user environments within the NixOS configuration system.