# In your disko-layout.nix, update the datasets section:
datasets = {
  "local/root" = {
    type = "zfs_fs";
    mountpoint = "/";
    options = {
      mountpoint = "legacy";
    };
    postCreateHook = ''
      zfs snapshot rpool/local/root@blank
    '';
  };
  "local/nix" = {
    type = "zfs_fs";
    mountpoint = "/nix";
    options = {
      mountpoint = "legacy";
      "com.sun:auto-snapshot" = "false";
    };
  };
  "safe/persist" = {
    type = "zfs_fs";
    mountpoint = "/persist";
    options = {
      mountpoint = "legacy";
    };
  };
  "safe/home" = {
    type = "zfs_fs";
    mountpoint = "/home";
    options = {
      mountpoint = "legacy";
    };
  };
};
