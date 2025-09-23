# /hosts/desktop/gaming.nix
{ config, pkgs, lib, ... }:

{
  # Enable Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Optimizations for gaming (AMD CPU)
  boot.kernelParams = [ "amd_pstate=active" ];
  
  # Gaming-related packages
  environment.systemPackages = with pkgs; [
    lutris
    wine
    winetricks
    gamemode
    mangohud
    discord
  ];
  
  # Enable gamemode
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
      };
    };
  };
}