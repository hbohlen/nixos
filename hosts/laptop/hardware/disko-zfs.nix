# /hosts/laptop/hardware/disko-zfs.nix
# Laptop-specific disko configuration built from reusable templates
{ inputs, ... }:

{
  imports = [ 
    inputs.disko.nixosModules.disko 
    ./disko-layout.nix
  ];
}