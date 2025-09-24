# /hosts/laptop/hardware/disko-zfs.nix
# Laptop-specific disko configuration
{ inputs, ... }:

{
  imports = [ 
    inputs.disko.nixosModules.disko 
    ./disko-layout.nix
  ];
}