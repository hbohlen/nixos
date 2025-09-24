# /hosts/server/hardware/disko-zfs.nix
# Server-specific disko configuration
{ inputs, ... }:

{
  imports = [ 
    inputs.disko.nixosModules.disko 
    ./disko-layout.nix
  ];
}