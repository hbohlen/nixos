# /hosts/laptop/hardware/disko-layout.nix
# Laptop layout built from the reusable ZFS + impermanence template.
args@{ device ? "/dev/nvme0n1", swapSize ? "8G", ... }:
let
  mkLayout = import ../../../profiles/hardware/disko/zfs-impermanence.nix;
  layoutArgs = args // {
    inherit device swapSize;
  };
in
mkLayout layoutArgs
