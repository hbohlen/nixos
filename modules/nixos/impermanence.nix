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

  # CRITICAL FIX: Prevent device timeout issues during initrd boot
  # Use the new settings.Manager approach for systemd configuration
  boot.initrd.systemd.settings.Manager = {
    DefaultTimeoutStartSec = "300s";
    DefaultTimeoutStopSec = "30s";
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
      # NetworkManager persistence (critical for WiFi connections)
      "/etc/NetworkManager/system-connections"
      "/var/lib/NetworkManager"
      "/var/lib/colord"
      "/var/lib/flatpak"
      "/var/lib/systemd/timers"
      "/var/mail"
      # 1Password system-wide
      "/var/lib/1password"
      # ASUS-specific directories
      "/etc/asusd"
      "/var/lib/asusd"
    ];
    files = [
      # System-level files that need persistence
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
    # User-specific persistence
    users.${username} = {
      directories = [
        # Essential user directories
        ".ssh" # SSH keys and config
        ".gnupg" # GPG keys and configuration
        
        # GNOME keyring storage
        ".local/share/keyrings" # GNOME keyring database
        
        # 1Password CLI and GUI (user-specific)
        ".config/op"
        ".config/1Password"
        ".cache/1Password"
        ".config/1Password-Beta"
        
        # Development and configuration
        ".config/git"
        ".config/gh" # GitHub CLI
        ".local/share/zsh" # Zsh history and completions
        ".cache" # General cache directory
        ".local/state" # Application state
        
        # ASUS-specific user directories
        ".config/asusd"
        
        # User data directories
        "Documents"
        "Downloads"
        "Pictures"
        "Music"
        "Videos"
        ".local/share"
        
        # Development directories (optional)
        ".cargo" # Rust cargo cache
        ".npm" # npm cache
        "Development" # Project workspace
      ];
      files = [
        # Shell history files
        ".bash_history"
        ".zsh_history"
        
        # Git configuration
        ".gitconfig"
        ".gitconfig.local"
      ];
    };
  };

  # Fix SSH host key permissions after rollback
  system.activationScripts.fixSSHPermissions = {
    text = ''
      # Ensure SSH host keys have correct permissions after impermanence rollback
      if [ -d "/persist/etc/ssh" ]; then
        chown -R root:root /persist/etc/ssh
        chmod 755 /persist/etc/ssh
        chmod 600 /persist/etc/ssh/ssh_host_*_key
        chmod 644 /persist/etc/ssh/ssh_host_*_key.pub
      fi
      
      # Ensure user SSH directory has correct permissions
      if [ -d "/persist/home/${username}/.ssh" ]; then
        chown -R ${username}:${username} /persist/home/${username}/.ssh
        chmod 700 /persist/home/${username}/.ssh
        chmod 600 /persist/home/${username}/.ssh/id_* 2>/dev/null || true
        chmod 644 /persist/home/${username}/.ssh/id_*.pub 2>/dev/null || true
        chmod 644 /persist/home/${username}/.ssh/authorized_keys 2>/dev/null || true
        chmod 644 /persist/home/${username}/.ssh/known_hosts* 2>/dev/null || true
      fi
    '';
    deps = [ "users" ];
  };

  # Ensure NetworkManager directories and permissions are properly set up
  system.activationScripts.setupNetworkManagerPersistence = {
    text = ''
      # Create NetworkManager persistence directories if they don't exist
      mkdir -p /persist/etc/NetworkManager/system-connections
      mkdir -p /persist/var/lib/NetworkManager
      
      # Set correct ownership and permissions for NetworkManager directories
      chown root:root /persist/etc/NetworkManager/system-connections
      chmod 755 /persist/etc/NetworkManager/system-connections
      
      chown root:root /persist/var/lib/NetworkManager
      chmod 755 /persist/var/lib/NetworkManager
      
      # Fix permissions on existing connection files
      if [ -d "/persist/etc/NetworkManager/system-connections" ]; then
        for conn_file in /persist/etc/NetworkManager/system-connections/*; do
          if [ -f "$conn_file" ]; then
            chown root:root "$conn_file"
            chmod 600 "$conn_file"
          fi
        done
      fi
      
      # Copy any existing connections to persist if not already there
      if [ -d "/etc/NetworkManager/system-connections" ]; then
        for conn_file in /etc/NetworkManager/system-connections/*; do
          if [ -f "$conn_file" ]; then
            base_name=$(basename "$conn_file")
            if [ ! -f "/persist/etc/NetworkManager/system-connections/$base_name" ]; then
              cp "$conn_file" "/persist/etc/NetworkManager/system-connections/"
              chown root:root "/persist/etc/NetworkManager/system-connections/$base_name"
              chmod 600 "/persist/etc/NetworkManager/system-connections/$base_name"
            fi
          fi
        done
      fi
    '';
    deps = [ "users" "fixSSHPermissions" ];
  };
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
      options = [ "zfsutil" "x-systemd.device-timeout=300" ];
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

  # Ensure NetworkManager starts after persistent directories are mounted
  systemd.services.NetworkManager = {
    after = [ "systemd-tmpfiles-setup.service" ];
    wants = [ "systemd-tmpfiles-setup.service" ];
  };
}