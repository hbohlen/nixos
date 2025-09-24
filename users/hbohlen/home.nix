# /users/hbohlen/home.nix
{ config, pkgs, inputs, lib, hostname, username, ... }:

{
  imports = [
    ../../modules/home-manager/desktop.nix
    ../../modules/home-manager/opnix.nix
  ];

  # nixpkgs.config is managed globally to avoid conflicts with useGlobalPkgs

  # Home Manager needs a bit of information about you and the paths it should manage.
  home.username = username;
  home.homeDirectory = "/home/${username}";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Packages specific to this user
  home.packages = with pkgs; [
    # Development tools and IDEs
    zed-editor
    vscode
    nodejs
    python3
    uv
    git
    gh
    
    # Terminals
    alacritty
    kitty
    
    # Browsers
    vivaldi
    
    # Productivity applications
    affine
    
    # 1Password family
    _1password-cli
    _1password-gui
    
    # Development and DevOps tools
    opencode
    podman
    podman-desktop
    podman-compose
    
    # CLI tools for development
    # Note: rovodev-cli and gemini-cli may need to be added as custom packages
    # if not available in nixpkgs - for now commenting out until verified
    # rovodev-cli
    # gemini-cli
    
    # Additional development tools
    npm
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
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "docker" "kubectl" "podman" ];
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

  # SSH configuration
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      forwardAgent = true;
      identitiesOnly = true;
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


  # Example: Manage dotfiles with a bare git repo ("dotfiles" pattern)
  # To use, run:
  #   git --git-dir=$HOME/.cfg/ --work-tree=$HOME init
  #   git --git-dir=$HOME/.cfg/ --work-tree=$HOME remote add origin <your-dotfiles-repo>
  #   git --git-dir=$HOME/.cfg/ --work-tree=$HOME pull
  #   git --git-dir=$HOME/.cfg/ --work-tree=$HOME add ...
  #   git --git-dir=$HOME/.cfg/ --work-tree=$HOME commit -m "..."
  #   git --git-dir=$HOME/.cfg/ --work-tree=$HOME push
  # You can add an alias in your shell config:
  #   alias config='git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

  # Ensure the .cfg directory is persisted (add to impermanence config):
  #   - /persist/home/hbohlen/.cfg

  # If you want to use chezmoi or yadm, add them to home.packages and configure as needed.

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  home.stateVersion = "25.05";
}
