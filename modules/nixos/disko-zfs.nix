# /modules/nixos/disko-zfs.nix
{ lib, config, pkgs, inputs, username, ... }:

let
  # Make the device path configurable per host
  device = lib.mkDefault (
    if config.networking.hostName == "laptop" then
      "/dev/nvme0n1"
    else if config.networking.hostName == "desktop" then
      "/dev/disk/by-id/desktop-disk-id"
    else if config.networking.hostName == "server" then
      "/dev/disk/by-id/server-disk-id"
    else
      "/dev/disk/by-id/default-disk-id"
  );
in
{
  imports = [ inputs.disko.nixosModules.disko ];

  disko.devices = {
    disk = {
      main = {
        inherit device;
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

            # Swap partition. ZFS does not reliably support swap on zvols or swapfiles.
            swap = {
              size = "8G"; # Adjust based on RAM.
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
                # The password will be requested at boot.
                # For unattended installs, a key file can be used.
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "zfs";
                  pool = "rpool"; # The name of our ZFS pool.
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
            mountpoint = "legacy"; # NixOS will mount this at /.
            # This hook runs after the dataset is created, establishing the clean state.
            postCreateHook = ''
              zfs snapshot rpool/local/root@blank
            '';
          };
          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "legacy"; # Mounted at /nix.
            options."com.sun:auto-snapshot" = "false"; # Disable snapshots for the Nix store.
          };

          # "safe" datasets are for persistent data that should be backed up.
          "safe/persist" = {
            type = "zfs_fs";
            mountpoint = "legacy"; # Mounted at /persist.
          };
          "safe/home" = {
            type = "zfs_fs";
            mountpoint = "legacy"; # Mounted at /home.
          };
          "safe/home/\${config.users.users.\${username}.name}" = {
            type = "zfs_fs";
            mountpoint = "legacy"; # Mounted at /home/<username>.
          };
        };
      };
    };
  };
}
