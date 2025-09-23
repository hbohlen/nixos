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
  # Ensure /persist is available (so persisted files like SSH host keys exist)
  # before the rollback runs. Also wait for zfs-mount so datasets are mounted.
  systemd.services.zfs-rollback = {
    description = "Rollback ZFS root dataset to a blank snapshot";
    wantedBy = [ "multi-user.target" ];
    # Must run before filesystems are remounted by systemd, but after the zpool
    # is imported and ZFS datasets are mounted under /persist.
    before = [ "systemd-remount-fs.service" ];
    after = [ "zfs-import.service" "zfs-mount.service" ];
    # Require /persist to be mounted so persisted files are present when other
    # units (sshd, display-manager, etc.) start.
    serviceConfig = {
      Type = "oneshot";
      RequiresMountsFor = "/persist";
      # The -r flag recursively destroys any snapshots newer than @blank.
      # The -f flag is needed if the dataset is mounted, which it may be.
      ExecStart = "${pkgs.zfs}/bin/zfs rollback -r -f rpool/local/root@blank";
    };
  };

  # Ensure SSH host keys exist in /persist before sshd starts. This oneshot
  # is idempotent and will only generate keys if they are missing.
  systemd.services.persist-ensure-ssh-keys = {
    description = "Ensure SSH host keys exist in /persist/etc/ssh";
    wantedBy = [ "multi-user.target" ];
    after = [ "zfs-mount.service" "zfs-rollback.service" ];
    # Run before sshd so the daemon finds keys when it starts
    before = [ "sshd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RequiresMountsFor = "/persist";
      ExecStart = ''
        if [ ! -e /etc/ssh/ssh_host_ed25519_key ] && [ ! -e /persist/etc/ssh/ssh_host_ed25519_key ]; then
          ${pkgs.openssh}/bin/ssh-keygen -A || true
        fi
      '';
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
      "/var/lib/AccountsService"
      "/var/cache"
      "/var/lib"
      "/etc/X11"
      "/etc/NetworkManager/system-connections"
      "/var/spool"
      "/var/lib/colord"
      "/var/lib/flatpak"
      "/var/lib/systemd/timers"
      "/var/mail"
      "/root"
  # 1Password CLI and GUI (user-specific)
  "/home/${username}/.config/op"
  "/home/${username}/.config/1Password"
  "/home/${username}/.cache/1Password"
  "/home/${username}/.config/1Password-Beta"
  # 1Password system-wide (rare)
  "/var/lib/1password"
  # Add more directories as needed
    ];
    files = [
      # System-level files that need persistence
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/passwd"
      "/etc/group"
      "/etc/shadow"
      "/etc/gshadow"
      "/etc/nsswitch.conf"
      "/etc/hostname"
      "/etc/localtime"
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
    "/boot" = {
      device = "/dev/disk/by-partlabel/disk-main-ESP";
      fsType = "vfat";
      options = [ "umask=0077" ];
      neededForBoot = true;
    };
  };
}