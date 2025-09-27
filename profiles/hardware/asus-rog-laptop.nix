# /profiles/hardware/asus-rog-laptop.nix
{ config, pkgs, lib, inputs, ... }:

let
  nixosHardwareModules = inputs.nixos-hardware.nixosModules;
  hasGu603zw = lib.hasAttr "asus-zephyrus-gu603zw" nixosHardwareModules;
in
{
  imports =
    (lib.optional hasGu603zw nixosHardwareModules.asus-zephyrus-gu603zw)
    ++ [
      nixosHardwareModules.asus-zephyrus-gu603h
      nixosHardwareModules.common-cpu-intel
      nixosHardwareModules.common-pc-laptop
      nixosHardwareModules.common-pc-laptop-ssd
    ];
}
