# /disko-layout-simple.nix - Simplified layout without LUKS/ZFS
{ device ? "/dev/disk/by-id/nvme-Micron_2450_MTFDKBA1T0TFK_2146334B7D47", ... }:
{
  disko.devices = {
    disk = {
      main = {
        device = device;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              name = "ESP";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            swap = {
              size = "8G";
              content = {
                type = "swap";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "btrfs";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}