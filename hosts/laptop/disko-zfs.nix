# /hosts/laptop/disko-zfs.nix
{ lib, config, pkgs, inputs, username, ... }:

{
  imports = [ inputs.disko.nixosModules.disko ];

  disko.devices = {
    disk = {
      main = {
        device = "/dev/nvme0n1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # EFI System Partition (ESP) for the bootloader.
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };

            # Smaller swap partition since we have 40GB RAM
            swap = {
              size = "4G";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };

            # Main partition to be encrypted with LUKS.
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
        # ZFS best practices for SSDs and modern drives.
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          # Standard recommended ZFS properties.
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";
          relatime = "on";
          # Disable ZFS's own mountpoint management; let NixOS handle it.
          mountpoint = "none";
        };

        # Define the hierarchical dataset structure for impermanence.
        datasets = {
          # "local" datasets are for data that can be regenerated and is not backed up.
          "local/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            postCreateHook = ''
              zfs snapshot rpool/local/root@blank
            '';
          };
          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options."com.sun:auto-snapshot" = "false"; # Disable snapshots for the Nix store.
          };

          # "safe" datasets are for persistent data that should be backed up.
          "safe/persist" = {
            type = "zfs_fs";
            mountpoint = "/persist";
          };
          "safe/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
          };
          "safe/home/${username}" = {
            type = "zfs_fs";
            mountpoint = "/home/${username}";
          };
        };
      };
    };
  };

  # ZFS optimizations for high-RAM system (40GB)
  boot.kernelParams = [
    # Increase ZFS ARC max size (default is 50% of RAM, but we can be more aggressive)
    "zfs.zfs_arc_max=21474836480"  # 20GB max ARC
    "zfs.zfs_arc_min=1073741824"   # 1GB min ARC
    # Other ZFS tunables optimized for laptop/desktop use
    "zfs.zfs_txg_timeout=5"
    "zfs.zfs_vdev_async_write_active_max_dirty_percent=50"
    "zfs.zfs_vdev_async_write_active_min_dirty_percent=10"
  ];
}