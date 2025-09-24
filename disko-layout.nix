# /disko-layout.nix
# TODO: Make device path configurable per host to avoid hardware coupling
# Consider moving this to per-host hardware-configuration.nix files
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
                randomEncryption = true;
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "zfs";
                  pool = "rpool";
                };
              };
            };
          };
        };
      };
    };
    zpool = {
      rpool = {
        type = "zpool";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";
          relatime = "on";
          mountpoint = "none";
        };
        datasets = {
          "local/root" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
              recordsize = "1M"; # Optimize for system files
            };
            postCreateHook = ''
              zfs snapshot rpool/local/root@blank
            '';
          };
          "local/nix" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
              recordsize = "1M"; # Optimize for large files (nix store)
              "com.sun:auto-snapshot" = "false";
            };
          };
          "safe/persist" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
              recordsize = "128K"; # Mixed workload optimization
            };
          };
          "safe/home" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
              recordsize = "128K"; # User files mixed workload
            };
          };
        };
      };
    };
  };
}
