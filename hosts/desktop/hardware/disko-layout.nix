# /hosts/desktop/hardware/disko-layout.nix
# Desktop layout built from the reusable ZFS + impermanence template.
args@{ device ? "/dev/nvme0n1", swapSize ? "16G", ... }:
let
  mkLayout = import ../../../profiles/hardware/disko/zfs-impermanence.nix;
  layoutArgs = args // {
    inherit device swapSize;
  };
in
mkLayout layoutArgs
