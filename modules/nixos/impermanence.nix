# /modules/nixos/impermanence.nix
{ config, lib, pkgs, inputs, username, ... }:

{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  # Enable ZFS support and ensure the pool is imported at boot.
  boot.supportedFilesystems = [ "zfs" ];
  services.zfs.autoScrub.enable = true;
  
  # CRITICAL FIX: Enable systemd in initrd for proper service ordering
  boot.initrd.systemd.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Move ZFS rollback to initrd stage where it belongs
  boot.initrd.systemd.services.zfs-rollback = {
    description = "Rollback ZFS root dataset to a blank snapshot";
    wantedBy = [ "initrd.target" ];
    after = [ "zfs-import-rpool.service" ];
    before = [ "sysroot.mount" ];
    path = [ pkgs.zfs ];
    serviceConfig.Type = "oneshot";
    unitConfig.DefaultDependencies = "no";
    script = "zfs rollback -r -f rpool/local/root@blank";
  };

  # Ensure persistent directories are created before they're needed
  boot.initrd.systemd.services.create-needed-for-boot-dirs = {
    after = [ "zfs-rollback.service" ];
    wants = [ "zfs-rollback.service" ];
  };

  # Define which files and directories should persist across reboots.
  # These are bind-mounted from the `/persist` dataset.
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      # System-level directories that need persistence
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/AccountsService"
      "/etc/NetworkManager/system-connections"
      "/var/lib/colord"
      "/var/lib/flatpak"
      "/var/lib/systemd/timers"
      "/var/mail"
      # 1Password system-wide
      "/var/lib/1password"
    ];
    files = [
      # System-level files that need persistence
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  # User-specific persistence (separate from system persistence)
  environment.persistence."/persist/home/${username}" = {
    hideMounts = true;
    directories = [
      # 1Password CLI and GUI (user-specific)
      ".config/op"
      ".config/1Password"
      ".cache/1Password"
      ".config/1Password-Beta"
      # Add more user directories as needed
      "Documents"
      "Downloads"
      "Pictures"
      "Music"
      "Videos"
      ".local/share"
    ];
  };

  # Explicitly define the filesystem mounts.
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
    "/boot" = {
      device = "/dev/disk/by-partlabel/disk-main-ESP";
      fsType = "vfat";
      options = [ "umask=0077" ];
      neededForBoot = true;
    };
  };

  # Remove the old zfs-rollback service that runs too late
  systemd.services.zfs-rollback = lib.mkForce { };
  
  # Remove the persist-ensure-ssh-keys service (not needed with proper initrd ordering)
  systemd.services.persist-ensure-ssh-keys = lib.mkForce { };
  
  # Fix for SSH service - ensure it starts after persistent directories are available
  systemd.services.sshd = {
    after = [ "systemd-tmpfiles-setup.service" ];
    wants = [ "systemd-tmpfiles-setup.service" ];
  };
}
