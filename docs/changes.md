

After reviewing your entire NixOS configuration, I've identified several issues that could be causing the boot errors with SSH and other services. Here's a comprehensive solution to fix all the problems:

## 1. Fix ZFS Dataset Inconsistencies

Your `disko-layout.nix` and `impermanence.nix` have inconsistencies in dataset names and structure. Update your `disko-layout.nix` to match exactly what's expected:

```nix
# /disko-layout.nix
{ device ? "/dev/disk/by-id/REPLACE_WITH_YOUR_DISK_ID", ... }:
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
            options.mountpoint = "legacy";
            postCreateHook = ''
              zfs snapshot rpool/local/root@blank
            '';
          };
          "local/nix" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            options."com.sun:auto-snapshot" = "false";
          };
          "safe/persist" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
          };
          "safe/home" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
          };
        };
      };
    };
  };
}
```

## 2. Fix impermanence.nix Configuration

Update your `/modules/nixos/impermanence.nix` with these critical fixes:

```nix
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
```

## 3. Fix User Home Directory Mount

In your `/hosts/laptop/default.nix` or `/hosts/desktop/default.nix`, ensure the user home directory is properly mounted:

```nix
# Add this to your host configuration
users.users.${username} = {
  isNormalUser = true;
  extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
  initialPassword = "changeme";
  # Ensure the home directory is created properly
  createHome = true;
  home = "/home/${username}";
};
```

## 4. Update flake.nix to Pass Username Properly

Make sure your `flake.nix` is correctly passing the username to all modules:

```nix
# /flake.nix
outputs = { self, nixpkgs, home-manager, disko, impermanence, hyprland, opnix, ... }@inputs:
  let
    # Define a helper function to build a NixOS system configuration.
    mkSystem = { system ? "x86_64-linux", hostname, username, extraModules ? [ ] }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs hostname username; }; # Pass inputs and other args to all modules.

        modules = [
          # Include the host-specific configuration
          ./hosts/${hostname}

          # Add home-manager as a NixOS module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Pass the user's specific home.nix configuration.
            home-manager.users.${username} = import ./users/${username}/home.nix;
            # Pass specialArgs to home-manager modules as well.
            home-manager.extraSpecialArgs = { inherit inputs hostname username; };
          }
        ] ++ extraModules; # Allow for additional, one-off modules.
      };
  in
  {
    # Define the NixOS configurations for each machine.
    nixosConfigurations = {
      "laptop" = mkSystem {
        hostname = "laptop";
        username = "hbohlen";
      };

      "desktop" = mkSystem {
        hostname = "desktop";
        username = "hbohlen";
        # Example of an extra module for a specific host.
        extraModules = [ ./hosts/desktop/gaming.nix ];
      };

      "server" = mkSystem {
        hostname = "server";
        username = "hbohlen";
      };
    };
  };
```

## 5. Fix User Home Manager Configuration

Update your `/users/hbohlen/home.nix` to ensure it properly receives the username:

```nix
# /users/hbohlen/home.nix
{ config, pkgs, inputs, lib, hostname, username, ... }:

{
  imports = [
    ../../modules/home-manager/desktop.nix
    ../../modules/home-manager/opnix.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should manage.
  home.username = username;  # Use the passed username variable
  home.homeDirectory = "/home/${username}";  # Use the passed username variable

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Packages specific to this user
  home.packages = with pkgs; [
    # Development tools
    vscode
    zed-editor
    nodejs
    python3
    uv
    git
    gh
    
    # Applications
    affine
    _1password-cli
    _1password-gui
    opencode
    podman
    podman-desktop
    vivaldi
    
    # Add more packages specific to this user
  ];

  # Rest of your configuration...
}
```

## 6. Add Host ID for ZFS

In your host configuration files (`/hosts/laptop/default.nix`, `/hosts/desktop/default.nix`, etc.), ensure you have a unique host ID for ZFS:

```nix
# Add this to each host configuration
networking.hostId = "cafebabe";  # Must be unique for each machine, 8 hex digits
```

## 7. Fix Boot Issues

If you're still having boot issues after applying these changes, you may need to:

1. Boot into an older generation from the bootloader
2. Apply the changes
3. Rebuild:
   ```bash
   sudo nixos-rebuild switch --flake .#hostname
   ```
4. If that fails, try:
   ```bash
   sudo nixos-rebuild boot --flake .#hostname
   sudo reboot
   ```

## Why These Changes Fix the Issues

1. **ZFS Dataset Consistency**: Ensures that the dataset names in Disko match exactly what's expected in impermanence.nix.

2. **Proper Service Ordering**: The ZFS rollback happens in the initrd stage before any services start, preventing the "dependency failed" errors.

3. **User Home Directory**: Ensures the user's home directory is properly mounted and accessible.

4. **SSH Service Fix**: Explicitly makes SSH start after the temporary files are set up, preventing the SSH-related errors.

5. **Username Propagation**: Ensures the username is properly passed to all modules that need it.

These changes should resolve the boot errors you're experiencing with SSH, nscd, and other services when using NixOS with ZFS and impermanence.