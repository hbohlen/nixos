# /modules/nixos/impermanence.nix
{ config, lib, pkgs, inputs, username, ... }:

{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  # Enable ZFS support and ensure the pool is imported at boot.
  boot.supportedFilesystems = [ "zfs" ];
  services.zfs.autoScrub.enable = true;

  # This systemd service executes the ZFS rollback at boot, wiping the root filesystem.
  systemd.services.zfs-rollback = {
    description = "Rollback ZFS root dataset to a blank snapshot";
    wantedBy = [ "multi-user.target" ];
    # Must run before filesystems are mounted but after the zpool is imported.
    before = [ "systemd-remount-fs.service" ];
    after = [ "zfs-import.service" ];
    serviceConfig = {
      Type = "oneshot";
      # The -r flag recursively destroys any snapshots newer than @blank.
      # The -f flag is needed if the dataset is mounted, which it may be.
      ExecStart = "${pkgs.zfs}/bin/zfs rollback -r -f rpool/local/root@blank";
    };
  };

  # Define which files and directories should persist across reboots.
  # These are bind-mounted from the `/persist` dataset.
  environment.persistence."/persist" = {
    hideMounts = true; # Hides the bind mounts from appearing in file managers.
    directories = [
      # System-level directories that need persistence
      "/var/lib/nixos"
      "/var/log"
      "/var/lib/systemd/coredump"
      # Add more directories as needed
    ];
    files = [
      # System-level files that need persistence
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      # Add more files as needed
    ];
  };

  # Explicitly define the filesystem mounts. Disko handles the creation,
  # but NixOS needs to know how to mount them on subsequent boots.
  # We use `mountpoint=legacy` in ZFS and let NixOS manage the mounts.
  fileSystems = {
    "/" = {
      device = "rpool/local/root";
      fsType = "zfs";
    };
    "/nix" = {
      device = "rpool/local/nix";
      fsType = "zfs";
      neededForBoot = true;
    };
    "/persist" = {
      device = "rpool/safe/persist";
      fsType = "zfs";
      neededForBoot = true;
    };
    "/home" = {
      device = "rpool/safe/home";
      fsType = "zfs";
    };
    "/home/${username}" = {
      device = "rpool/safe/home/${username}";
      fsType = "zfs";
    };
  };
}