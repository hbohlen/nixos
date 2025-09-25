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

  config = {
    # Define the main user account
    users.users.${username} = {
      isNormalUser = true;
      description = "Hayden Bohlen";
      extraGroups = [ "wheel" "networkmanager" ]
        ++ lib.optionals (config.users.hostType != "server") [ "video" "audio" ];
      
      # SSH key authentication (preferred for security)
      openssh.authorizedKeys.keys = config.users.sshKeys;
      
      # Password authentication (only for initial setup)
      initialPassword = lib.mkIf config.users.enablePasswordAuth "changeme";
      hashedPassword = lib.mkIf (!config.users.enablePasswordAuth && config.users.sshKeys == []) 
        (lib.mkForce null); # Disable password auth when SSH keys are configured
      
      group = username;
      createHome = true;
      home = "/home/${username}";
    };

    # Create user group
    users.groups.${username} = {};

    # Security configuration
    security.sudo.wheelNeedsPassword = true;
  };
}