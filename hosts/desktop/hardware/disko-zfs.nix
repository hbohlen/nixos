# /hosts/desktop/hardware/disko-zfs.nix
# Desktop-specific disko configuration built from reusable templates
{ inputs, ... }:

{
  imports = [ 
    inputs.disko.nixosModules.disko 
    ./disko-layout.nix
  ];
}