# /modules/nixos/users.nix
{ config, pkgs, lib, username, ... }:

{
  # Define user options for declarative configuration
  options = {
    users.hostType = lib.mkOption {
      type = lib.types.enum [ "desktop" "laptop" "server" ];
      description = "Type of host for user group configuration";
      default = "desktop";
    };
    
    users.sshKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "SSH public keys for user authentication";
      default = [];
      example = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample... user@host" ];
    };
    
    users.enablePasswordAuth = lib.mkOption {
      type = lib.types.bool;
      description = "Enable password authentication (disable for production)";
      default = true;
    };
  };

  config = lib.mkMerge [
    {
      # Define the main user account
      users.users.${username} = {
        isNormalUser = true;
        description = "Primary User Account";
        extraGroups = [ "wheel" "networkmanager" ]
          ++ lib.optionals (config.users.hostType != "server") [ "video" "audio" ];

        # SSH key authentication (preferred for security)
        openssh.authorizedKeys.keys = config.users.sshKeys;

        group = username;
        createHome = true;
        home = "/home/${username}";
      };

      # Create user group
      users.groups.${username} = {};

      # Security configuration
      security.sudo.wheelNeedsPassword = true;
    }

    (lib.mkIf config.users.enablePasswordAuth {
      users.users.${username}.initialPassword = "changeme";
    })

    (lib.mkIf (!config.users.enablePasswordAuth && config.users.sshKeys == []) {
      users.users.${username}.hashedPassword = lib.mkForce null;
    })
  ];
}
