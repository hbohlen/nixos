# /modules/nixos/disko-zfs.nix
{ inputs, ... }:

{
  imports = [ inputs.disko.nixosModules.disko ../../disko-layout.nix ];
}
