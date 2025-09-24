# /hosts/desktop/hardware/disko-zfs.nix
# Desktop-specific disko configuration
{ inputs, ... }:

{
  imports = [ 
    inputs.disko.nixosModules.disko 
    ./disko-layout.nix
  ];
}