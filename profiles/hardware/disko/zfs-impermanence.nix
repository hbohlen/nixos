# /profiles/hardware/disko/zfs-impermanence.nix
# Parameterized Disko layout for LUKS-encrypted ZFS with impermanence support.
#
# Usage example (within a host-specific module):
#   let
#     mkLayout = import ../../../profiles/hardware/disko/zfs-impermanence.nix;
#   in
#   mkLayout {
#     device = "/dev/nvme0n1";
#     swapSize = "16G";
#   }
{
  device,
  swapSize ? "8G",
  poolName ? "rpool",
  luksName ? "cryptroot",
  efiMountOptions ? [ "umask=0077" ],
  swapRandomEncryption ? true,
  luksSettings ? { allowDiscards = true; },
  poolOptions ? { ashift = "12"; autotrim = "on"; },
  rootFsOptions ? {
    compression = "zstd";
    acltype = "posixacl";
    xattr = "sa";
    relatime = "on";
    mountpoint = "none";
  },
  datasetOverrides ? { },
  zpoolOverrides ? { },
  diskOverrides ? { },
  enableRootSnapshot ? true,
}:
let
  inherit (builtins) attrNames foldl' hasAttr isAttrs;

  recursiveUpdate = base: updates:
    if isAttrs base && isAttrs updates then
      let
        applyUpdate = acc: name:
          let
            updateValue = updates.${name};
          in
            if hasAttr name acc then
              acc // { ${name} = recursiveUpdate acc.${name} updateValue; }
            else
              acc // { ${name} = updateValue; };
      in
      foldl' applyUpdate base (attrNames updates)
    else
      updates;

  rootDataset = {
    type = "zfs_fs";
    options = {
      mountpoint = "legacy";
      recordsize = "1M";
    };
  } // (if enableRootSnapshot then {
    postCreateHook = ''
      zfs snapshot ${poolName}/local/root@blank
    '';
  } else { });

  datasetDefaults = {
    "local/root" = rootDataset;
    "local/nix" = {
      type = "zfs_fs";
      options = {
        mountpoint = "legacy";
        recordsize = "1M";
        "com.sun:auto-snapshot" = "false";
      };
    };
    "safe/persist" = {
      type = "zfs_fs";
      options = {
        mountpoint = "legacy";
        recordsize = "128K";
      };
    };
    "safe/home" = {
      type = "zfs_fs";
      options = {
        mountpoint = "legacy";
        recordsize = "128K";
      };
    };
  };

  finalDatasets = recursiveUpdate datasetDefaults datasetOverrides;

  diskDefaults = {
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
                mountOptions = efiMountOptions;
              };
            };
            swap = {
              size = swapSize;
              content = {
                type = "swap";
                randomEncryption = swapRandomEncryption;
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = luksName;
                settings = luksSettings;
                content = {
                  type = "zfs";
                  pool = poolName;
                };
              };
            };
          };
        };
      };
    };
  };

  finalDisk = recursiveUpdate diskDefaults diskOverrides;

  zpoolDefaults = {
    ${poolName} = {
      type = "zpool";
      options = poolOptions;
      rootFsOptions = rootFsOptions;
      datasets = finalDatasets;
    };
  };

  finalZpool = recursiveUpdate zpoolDefaults zpoolOverrides;
in
{
  disko.devices = finalDisk // { zpool = finalZpool; };
}
