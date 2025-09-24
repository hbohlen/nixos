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
  };

  config = {
    # Define the main user account
    users.users.${username} = {
      isNormalUser = true;
      description = "Hans Bohlen";
      extraGroups = [ "wheel" "networkmanager" ]
        ++ lib.optionals (config.users.hostType != "server") [ "video" "audio" ];
      initialPassword = "changeme"; # Replace with secure method in production
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