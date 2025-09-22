# /users/my-user/default.nix
{ config, pkgs, inputs, lib, hostname, ... }:

{
  imports = [
    ../../modules/home-manager/desktop.nix
    ../../modules/home-manager/opnix.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should manage.
  home.username = "my-user";
  home.homeDirectory = "/home/my-user";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Packages specific to this user
  home.packages = with pkgs; [
    # Development tools
    vscode
    jetbrains.idea-community
    
    # Communication
    slack
    discord
    
    # Multimedia
    spotify
    vlc

    # Utilities
    libreoffice
    gimp
    
    # Add more packages specific to this user
  ];

  # Shell configuration
  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      update = "cd /workspaces/nixos && ./scripts/rebuild.sh";
      # Add more aliases as needed
    };
    bashrcExtra = ''
      # Add custom Bash configurations here
      export PATH=$HOME/.local/bin:$PATH
    '';
  };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "docker" "kubectl" ];
      theme = "robbyrussell";
    };
    shellAliases = {
      ll = "ls -la";
      update = "cd /workspaces/nixos && ./scripts/rebuild.sh";
      # Add more aliases as needed
    };
  };

  # Terminal emulator configuration
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        size = 12.0;
      };
      colors = {
        # Catppuccin Mocha theme
        primary = {
          background = "#1E1E2E";
          foreground = "#CDD6F4";
        };
      };
    };
  };

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "your.email@example.com";
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1..."; # Replace with your SSH key
      signByDefault = true;
    };
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  # VSCode configuration
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      vscodevim.vim
      ms-python.python
      rust-lang.rust-analyzer
      # Add more extensions as needed
    ];
    userSettings = {
      "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'monospace'";
      "editor.fontSize" = 14;
      "editor.lineNumbers" = "relative";
      "workbench.colorTheme" = "Catppuccin Mocha";
      # Add more settings as needed
    };
  };

  # Firefox configuration
  programs.firefox = {
    enable = true;
    profiles.default = {
      settings = {
        "browser.startup.homepage" = "https://nixos.org";
        "browser.search.region" = "US";
        "browser.search.isUS" = true;
        "browser.urlbar.placeholderName" = "DuckDuckGo";
        # Add more Firefox settings as needed
      };
    };
  };

  # Configure XDG file associations
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "application/pdf" = "org.gnome.Evince.desktop";
      "image/jpeg" = "org.gnome.eog.desktop";
      "image/png" = "org.gnome.eog.desktop";
      # Add more file associations as needed
    };
  };

  # Conditional configuration based on hostname
  home.file = lib.mkIf (hostname == "laptop") {
    ".config/hypr/special-laptop-config.conf".text = ''
      # This config is only applied on the laptop
      # For example, special trackpad gestures or power settings
    '';
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  home.stateVersion = "23.11";
}