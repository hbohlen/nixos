# /hosts/laptop/hardware/disko-layout.nix
# Laptop-specific disk layout configuration
# 
# IMPORTANT: Update the device path to match your actual hardware!
# 
# To find your device path, run:
#   lsblk -f
#   ls -la /dev/disk/by-id/
# 
# Examples of common device paths:
#   NVMe: /dev/nvme0n1 or /dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_1TB_...
#   SATA SSD: /dev/sda or /dev/disk/by-id/ata-Samsung_SSD_860_EVO_500GB_...
#
# Using by-id paths is preferred for stability across reboots
{ device ? "/dev/nvme0n1", ... }:
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
              size = "8G"; # Laptop: smaller swap for battery life
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