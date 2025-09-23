Architecting a Modern, Declarative, and Ephemeral NixOS System
Purpose and Philosophy
This report presents a reference architecture for a modern, secure, and fully reproducible NixOS desktop system. The design philosophy is rooted in the principles of declarative infrastructure and system impermanence, often summarized by the mantra "Erase Your Darlings". By declaratively defining every aspect of the system—from disk partitions to application themes—and ensuring the root filesystem is stateless, this architecture achieves an unparalleled level of predictability, resilience, and maintainability. Changes are not applied imperatively; rather, the entire system state is derived from a single, version-controlled source of truth. This approach eliminates configuration drift, simplifies system recovery, and makes onboarding new hardware a trivial, automated process.
The integration of Nix Flakes serves as the cornerstone of this architecture, providing a self-contained, hermetic definition of the system and all its dependencies. This ensures that a configuration that builds successfully today will build identically years from now, regardless of changes in the upstream Nixpkgs repository. This report provides not merely a collection of code snippets, but a cohesive blueprint for a robust, elegant, and forward-looking personal computing environment.
Overview of the Technology Stack
The technology stack has been selected to create a seamless, powerful, and secure user experience, with each component playing a specific, complementary role:
* Nix Flakes: The central management framework, providing reproducible builds and dependency management for the entire system configuration. Flakes define clear inputs and outputs, making the configuration portable and easy to share.
* Disko: A declarative disk partitioning and formatting tool. It extends the declarative nature of NixOS to the bare metal, allowing the entire disk layout to be defined as code, which is critical for automated installations.
* ZFS: A powerful, modern filesystem chosen for its advanced features, including robust data integrity, efficient snapshots, and native compression. Its dataset and snapshotting capabilities are fundamental to the impermanence strategy.
* Impermanence: A NixOS module that facilitates the creation of an ephemeral (stateless) root filesystem. It works in concert with ZFS snapshots to reset the system state on every boot, while providing a declarative mechanism for opting specific files and directories into persistence.
* Hyprland: A dynamic, extensible Wayland compositor that offers a modern, visually appealing, and highly configurable desktop experience. Its configuration is managed declaratively through Home Manager.
* Home Manager: A tool for managing user-level ("dotfiles") configurations and packages declaratively. It allows for the same level of reproducibility for the user environment as NixOS provides for the system environment.
* Opnix: A secrets management tool that integrates with 1Password to inject secrets into the system at runtime. This approach avoids storing sensitive data in the world-readable Nix store, enhancing the security posture of the system.
Proposed Directory Structure
A modular and scalable configuration begins with a well-organized directory structure. This layout separates concerns, promotes reusability, and makes the configuration easier to navigate and maintain. The proposed structure is a synthesis of best practices observed across numerous advanced NixOS configurations.
Path
	Description
	/flake.nix
	The central flake entry point, defining all inputs and outputs for the system.
	/hosts/
	Contains host-specific configurations. Each subdirectory (e.g., my-laptop/) holds the default.nix and hardware-configuration.nix for that machine.
	/modules/nixos/
	Houses reusable NixOS modules that can be imported by any host (e.g., zfs.nix, impermanence.nix, hyprland.nix).
	/modules/home-manager/
	Contains reusable Home Manager modules for user-level configurations (e.g., desktop.nix, shell.nix, opnix.nix).
	/users/
	Defines user accounts and their associated Home Manager configurations. Each subdirectory (e.g., hbohlen/) contains a home.nix file.
	/secrets/
	A placeholder directory for encrypted secret files. While Opnix injects secrets at runtime, other tools like sops-nix or agenix would store their encrypted files here.
	/scripts/
	Contains helper scripts for common tasks, such as deploying the configuration (rebuild.sh).
	Section 1: Foundational Flake Architecture for a Modular, Multi-Host System
The flake.nix file is the definitive entry point for the entire system configuration. It declares all external dependencies (inputs) and defines the buildable artifacts (outputs), such as the NixOS configurations for each machine. A well-structured flake is paramount for managing a complex, multi-host setup in a clean and scalable manner.
The flake.nix Entry Point
The following flake.nix demonstrates a robust pattern for managing multiple hosts while minimizing code duplication. It defines all necessary inputs and uses a helper function to construct each system configuration from a combination of shared and host-specific modules.
# /flake.nix
{
 description = "A modular, flake-based NixOS configuration";

 # Define all external dependencies (flakes) for the system.
 inputs = {
   # Nixpkgs: The primary source of packages and NixOS modules.
   # Pinning to a specific branch (e.g., nixos-unstable) ensures reproducibility.
   nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

   # Home Manager: For declarative management of user environments.
   home-manager = {
     url = "github:nix-community/home-manager";
     # Ensure home-manager uses the same version of nixpkgs as the system.
     # This prevents package version mismatches and build failures.[span_32](start_span)[span_32](end_span)
     inputs.nixpkgs.follows = "nixpkgs";
   };

   # Disko: For declarative disk partitioning.
   disko = {
     url = "github:nix-community/disko";
     inputs.nixpkgs.follows = "nixpkgs";
   };

   # Impermanence: For managing ephemeral root filesystems.
   impermanence.url = "github:nix-community/impermanence";

   # Hyprland: The Wayland compositor and its associated modules.
   hyprland = {
     url = "github:hyprwm/Hyprland";
     inputs.nixpkgs.follows = "nixpkgs";
   };

   # Opnix: For 1Password secrets management.
   opnix = {
     url = "github:brizzbuzz/opnix";
     inputs.nixpkgs.follows = "nixpkgs";
   };
 };

 # Define the outputs of the flake (e.g., NixOS configurations).
 outputs = { self, nixpkgs, home-manager, disko, impermanence, hyprland, opnix,... }@inputs:
   let
     # Define a helper function to build a NixOS system configuration.
     # This pattern reduces boilerplate and enforces a consistent structure.[span_33](start_span)[span_33](end_span)
     mkSystem = { system? "x86_64-linux", hostname, username, extraModules? [ ] }:
       nixpkgs.lib.nixosSystem {
         inherit system;
         specialArgs = { inherit inputs; inherit hostname username; }; # Pass inputs and other args to all modules.

         modules =
           home-manager.nixosModules.home-manager
           {
             home-manager.useGlobalPkgs = true;
             home-manager.useUserPackages = true;
             # Pass the user's specific home.nix configuration.
             home-manager.users.${username} = import./users/${username};
             # Pass specialArgs to home-manager modules as well.
             home-manager.extraSpecialArgs = { inherit inputs; inherit hostname username; };
           }
         ] ++ extraModules; # Allow for additional, one-off modules.
       };
   in
   {
     # Define the NixOS configurations for each machine.
     # The key name (e.g., "my-laptop") must match the machine's hostname
     # for `nixos-rebuild` to pick it up automatically.[span_35](start_span)[span_35](end_span)[span_36](start_span)[span_36](end_span)
     nixosConfigurations = {
       "my-laptop" = mkSystem {
         hostname = "my-laptop";
         username = "hbohlen";
       };

       "my-desktop" = mkSystem {
         hostname = "my-desktop";
         username = "hbohlen";
         # Example of an extra module for a specific host.
         extraModules = [./hosts/my-desktop/gaming.nix ];
       };
     };
   };
}

The use of a helper function like mkSystem represents a significant architectural decision. A naive approach might involve duplicating the entire nixpkgs.lib.nixosSystem block for each host, leading to verbose, error-prone, and difficult-to-maintain code. By abstracting the system definition into a function, a clear contract is established for what constitutes a "system" within the repository: a combination of common modules, host-specific settings, and user configurations. This pattern prevents configuration drift between machines, as any change to the common baseline is automatically propagated to all hosts during their next rebuild. This shifts the mental model from configuring individual machines to defining a fleet of systems from a shared, robust template, a practice that dramatically improves scalability and maintainability even for a small number of personal machines.
Section 2: Declarative Disk Management with Disko and Encrypted ZFS
Declarative disk management is a critical step toward a fully reproducible system. The Disko tool extends the Nix philosophy to the block device level, allowing the entire partitioning, encryption, and filesystem layout to be defined as code. This eliminates one of the last manual, imperative steps in a NixOS installation, enabling fully automated and repeatable deployments.
The disko-zfs.nix Module
This module, intended to be located at ./modules/nixos/disko-zfs.nix, defines a complete disk layout using Disko. It specifies a GPT partition table, an EFI boot partition, a dedicated swap partition, and a LUKS-encrypted container for the ZFS pool.
The choice to use LUKS as the encryption layer for the root pool, rather than ZFS native encryption, is a deliberate one based on community experience and stability considerations. While ZFS native encryption is powerful, its integration with the early boot process can be fragile, particularly during kernel upgrades that affect the ZFS kernel modules. LUKS is the standard block device encryption layer in the Linux ecosystem and is deeply integrated into the initrd boot process, providing a more robust and reliable foundation for an encrypted root filesystem.
The ZFS dataset structure defined below is specifically designed to support the impermanence strategy. It separates ephemeral system data from persistent system data and user data, providing the necessary foundation for the rollback mechanism detailed in the next section. The postCreateHook is a powerful Disko feature used here to create the initial @blank snapshot of the root dataset immediately after its creation, which is the pristine state to which the system will revert on each boot.
# /modules/nixos/disko-zfs.nix
{ lib, config, pkgs,... }:

let
 # Assume the device path is passed via flake's specialArgs or a custom option.
 # This makes the module reusable. For this example, we'll hardcode it.
 # In a real setup, replace this with `config.myOptions.bootDevice` or similar.
 device = "/dev/disk/by-id/your-disk-id";
in
{
 imports =;

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

           # Swap partition. ZFS does not reliably support swap on zvols or swapfiles.[span_13](start_span)[span_13](end_span)
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
           # This hook runs after the dataset is created, establishing the clean state.[span_46](start_span)[span_46](end_span)
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
         "safe/home/${config.users.users.${username}.name}" = {
           type = "zfs_fs";
           mountpoint = "legacy"; # Mounted at /home/<username>.
         };
       };
     };
   };
 };
}

This declarative filesystem layout is formalized in the following table, which serves as a map to the system's state management strategy.
Dataset Name
	Mount Point
	Persistence Strategy
	Rationale
	rpool/local/root
	/
	Ephemeral (Rolls back to @blank)
	Contains the live system state, which should be stateless. Any changes are discarded on reboot to prevent configuration drift.
	rpool/local/nix
	/nix
	Persistent
	The Nix store contains all system packages and configurations; it must always persist. It is designated local because it can be fully rebuilt from the flake and does not require backups.
	rpool/safe/persist
	/persist
	Persistent
	Stores critical system state that is explicitly opted into persistence via the impermanence module (e.g., SSH host keys, logs, machine-id). Designated safe to indicate it should be included in backups.
	rpool/safe/home
	/home
	Persistent
	Stores all persistent user data, including application configurations and personal files. This separates the ephemeral nature of the system from the persistent state of the user.
	Section 3: Implementing an Ephemeral Root with ZFS and Impermanence
With the ZFS datasets declaratively established by Disko, the next step is to implement the logic that enforces the ephemeral nature of the root filesystem. This is achieved through a combination of a ZFS rollback command executed at boot and the impermanence NixOS module, which declaratively manages the persistence of essential files and directories.
The impermanence.nix Module
This module, located at ./modules/nixos/impermanence.nix, contains the configuration to enable the ZFS rollback and defines the persistence rules for the system.
ZFS Snapshot Rollback
The core mechanism for achieving an ephemeral root with ZFS is to roll the rpool/local/root dataset back to its pristine @blank snapshot during the boot process. This action effectively discards any changes made to the root filesystem during the previous session. This can be implemented via a systemd service that runs early in the boot sequence.
Opt-In State Persistence
While the root filesystem is ephemeral, certain system-level state must be preserved across reboots. The impermanence module provides a clean, declarative interface (environment.persistence) for this purpose. It works by creating bind mounts or symbolic links from a persistent location (our /persist ZFS dataset) into the ephemeral root filesystem after it has been reset. This ensures that essential files like the machine-id (required by systemd) and SSH host keys are available where the system expects them, even though they are physically stored on a separate, persistent dataset.
The configuration also mounts the rpool/safe/home dataset directly to /home, making all user data persistent by default. This is a pragmatic approach that provides the benefits of a clean system environment without forcing the user to manage the persistence of every application dotfile, which can be a tedious process.
# /modules/nixos/impermanence.nix
{ config, lib, pkgs,... }:

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
   hideMounts = true; # Hides the bind mounts from appearing in file managers.[span_54](start_span)[span_54](end_span)
   directories =;
   files =;
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
   "/home/${config.users.users.${username}.name}" = {
     device = "rpool/safe/home/${config.users.users.${username}.name}";
     fsType = "zfs";
   };
 };
}

The relationship between the ZFS dataset structure defined by Disko and the logical linking provided by the impermanence module is deeply symbiotic. While tmpfs can be used for an ephemeral root, it has significant drawbacks, such as potential data loss on a system crash and limitations imposed by available RAM. The ZFS snapshot approach is far more robust. Disko creates the physical separation of state into distinct ZFS volumes at installation time. The ZFS rollback mechanism then enforces ephemerality on the root volume. Finally, the impermanence module acts as the declarative "glue," reassembling the necessary parts of a functional filesystem at boot time by creating bind mounts from the persistent volumes (/persist, /home) into the newly wiped ephemeral root. This layered approach creates a fully declarative, resilient, and comprehensible ephemeral system that is more powerful than the sum of its individual components.
Section 4: Configuring the Hyprland Desktop Environment via Home Manager
A modern, declarative system deserves a modern desktop environment. Hyprland is a highly customizable and feature-rich Wayland compositor that provides a fluid and visually appealing experience. Managing its configuration, along with its rich ecosystem of tools like Waybar, Rofi, and Dunst, is best accomplished through Home Manager. This ensures that the user's entire desktop environment is as reproducible and version-controlled as the underlying operating system.
The hyprland.nix Home Manager Module
This module, located at ./modules/home-manager/desktop.nix, provides a comprehensive configuration for Hyprland and its essential companion applications. It is designed to be imported into a user's home.nix.
First, certain system-level packages and settings are required for any Wayland environment to function correctly. These should be placed in a shared NixOS module, such as ./modules/nixos/common.nix.
# /modules/nixos/common.nix (relevant section)
{ pkgs,... }: {
 # Enable Wayland and PipeWire for audio/video.
 services.xserver.enable = true; # Still needed for XWayland.
 services.xserver.displayManager.gdm.enable = true; # Or another Wayland-compatible DM.
 services.xserver.desktopManager.gnome.enable = true; # GDM requires this.
 security.rtkit.enable = true;
 services.pipewire = {
   enable = true;
   alsa.enable = true;
   pulse.enable = true;
 };

 # Enable Hyprland-specific services.
 programs.hyprland.enable = true;
 xdg.portal.enable = true;
 xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
}

With the system-level prerequisites in place, the Home Manager module can focus on the user's specific desktop configuration. The following code provides a well-structured starting point for Hyprland, Waybar, Rofi, and Dunst, with a consistent theme applied across all components.
# /modules/home-manager/desktop.nix
{ pkgs,... }:

{
 imports = [
   # Import the official Hyprland Home Manager module.[span_59](start_span)[span_59](end_span)[span_60](start_span)[span_60](end_span)
   inputs.hyprland.homeManagerModules.default
 ];

 # Install essential desktop applications.
 home.packages = with pkgs;;

 # Hyprland configuration
 wayland.windowManager.hyprland = {
   enable = true;
   # extraConfig allows for raw hyprland.conf syntax.
   extraConfig = ''
     # Set a background image.
     exec-once = swaybg -i ~/.config/wallpaper.png

     # Source a file for colors and themes.
     source = ~/.config/hypr/theme.conf
   '';
   settings = {
     # See https://wiki.hyprland.org/Configuring/Variables/ for all options
     monitor = ",preferred,auto,1";

     # Input devices
     input = {
       kb_layout = "us";
       follow_mouse = 1;
       touchpad = {
         natural_scroll = true;
       };
     };

     # General settings
     general = {
       gaps_in = 5;
       gaps_out = 10;
       border_size = 2;
       "col.active_border" = "rgb(cba6f7)"; # Catppuccin Mauve
       "col.inactive_border" = "rgb(45475a)"; # Catppuccin Surface0
       layout = "dwindle";
     };

     # Decorations
     decoration = {
       rounding = 10;
       blur = {
         enabled = true;
         size = 3;
         passes = 1;
       };
       drop_shadow = true;
       shadow_range = 4;
       shadow_render_power = 3;
       "col.shadow" = "rgba(1a1a1aee)";
     };

     # Animations
     animations = {
       enabled = true;
       bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
       animation =;
     };

     # Keybindings
     "$mainMod" = "SUPER";
     bind =;
   };
 };

 # Waybar: The status bar
 programs.waybar = {
   enable = true;
   style = ''
     /* Use CSS for styling [span_61](start_span)[span_61](end_span) */
     * {
       border: none;
       font-family: "JetBrains Mono Nerd Font";
       font-size: 14px;
     }
     window#waybar {
       background-color: rgba(30, 30, 46, 0.8); /* Catppuccin Base */
       color: #cdd6f4; /* Catppuccin Text */
     }
     #workspaces button {
       padding: 0 5px;
       background-color: transparent;
       color: #cdd6f4;
     }
     #workspaces button.active {
       background-color: #cba6f7; /* Catppuccin Mauve */
       color: #1e1e2e;
     }
   '';
   settings = {
     mainBar = {
       layer = "top";
       position = "top";
       height = 30;
       modules-left = [ "hyprland/workspaces" "hyprland/window" ];
       modules-center = [ "clock" ];
       modules-right = [ "pulseaudio" "network" "cpu" "memory" "tray" ];

       "hyprland/workspaces" = {
         format = "{icon}";
       };
       clock = {
         format = "{:%Y-%m-%d %H:%M:%S}";
       };
       #... other module settings
     };
   };
 };

 # Rofi: The application launcher
 programs.rofi = {
   enable = true;
   theme = "catppuccin"; # Assuming a theme is available or defined
 };

 # Dunst: The notification daemon
 services.dunst = {
   enable = true;
   settings = {
     global = {
       font = "JetBrains Mono 10";
       format = ''<b>%s</b>\n%b'';
     };
     urgency_low = {
       background = "#313244"; # Catppuccin Surface0
       foreground = "#cdd6f4"; # Catppuccin Text
     };
     urgency_normal = {
       background = "#cba6f7"; # Catppuccin Mauve
       foreground = "#1e1e2e"; # Catppuccin Base
     };
     #... and so on
   };
 };
}

Section 5: Secure and Declarative Secret Injection with Opnix and 1Password
Effective secrets management is a non-negotiable component of a secure and reproducible system. While tools like sops-nix and agenix are popular choices, they operate by decrypting secrets during the system build process (nixos-rebuild) and placing them in the Nix store or a runtime directory with restricted permissions. The user's choice of Opnix represents a different architectural approach: secrets are fetched from a 1Password vault and injected into the filesystem at runtime, meaning they are never stored, even temporarily, in the world-readable Nix store.
This runtime injection model introduces a fundamental trade-off. It enhances security by ensuring secrets never touch the Nix store, but it also creates a runtime dependency on a functioning and authenticated 1Password daemon. If the daemon is not running or cannot be unlocked, services or applications that depend on Opnix-managed secrets will fail to start or function correctly. This contrasts with build-time secret managers, where once the system is successfully built, it is self-contained and does not rely on an external service for its secrets during operation. This operational distinction is critical to understand when architecting the system's services and startup sequence.
The opnix.nix Home Manager Module
This module, located at ./modules/home-manager/opnix.nix, configures both the necessary system-level daemons and the user-level secret definitions.
First, the 1Password GUI application and its associated Polkit agent must be enabled at the system level to allow for authentication and integration with the command-line tools that Opnix relies on.
# /modules/nixos/common.nix (relevant section)
{ config, pkgs, lib, username,... }: {
 # Enable the unfree 1Password packages.
 nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
   "1password"
   "1password-gui"
 ];

 programs._1password.enable = true;
 programs._1password-gui = {
   enable = true;
   # Enable PolKit for system authentication features (e.g., fingerprint unlock).
   polkitPolicyOwners = [ username ];
 };
}

With the system components enabled, the Home Manager module can define the specific secrets to be managed by Opnix. The programs.onepassword-secrets option provides a declarative interface for mapping 1Password secret URIs (op://...) to specific file paths within the user's home directory.
# /modules/home-manager/opnix.nix
{ pkgs, lib,... }:

{
 imports = [
   # Import the Opnix Home Manager module.
   inputs.opnix.homeManagerModules.default
 ];

 # Enable the 1Password secrets management program.
 programs.onepassword-secrets = {
   enable = true;
   # Define a list of secrets to be provisioned at runtime.
   secrets =
       # Format: op://<vault>/<item>/<field>
       reference = "op://Personal/SSH Private Key/private key";
       # Set appropriate file permissions.
       mode = "0600";
     }
     {
       path = ".config/my-app/api.token";
       reference = "op://Work/API Tokens/My App Token";
       mode = "0600";
     }
   ];
 };

 # Configure the SSH client to use the 1Password SSH agent for authentication.
 # This requires enabling the SSH agent in the 1Password desktop app settings.[span_66](start_span)[span_66](end_span)[span_68](start_span)[span_68](end_span)
 programs.ssh = {
   enable = true;
   extraConfig = ''
     Host *
       IdentityAgent ~/.1password/agent.sock
   '';
 };
}

This configuration declaratively ensures that whenever the user logs in, the Opnix service will attempt to connect to the 1Password daemon, fetch the specified secrets, and write them to the designated files with the correct permissions. This provides a secure and automated way to provision sensitive credentials without ever committing them to the configuration repository.
Section 6: Full System Integration and Deployment Strategy
The final step is to integrate all the modular components into a cohesive system definition for each host and to establish a standardized deployment workflow. This is where the architectural benefits of modularity become apparent, as assembling a complete system is reduced to importing the required modules.
Host Configuration (./hosts/my-laptop/default.nix)
Each host in the /hosts/ directory has a default.nix file that serves as its main configuration entry point. This file imports the shared modules (like disko-zfs.nix and impermanence.nix), the machine-specific hardware configuration, and sets any host-specific options.
# /hosts/my-laptop/default.nix
{ config, pkgs,... }:

{
 # Import the modules that define the core architecture of the system.
 imports = [
  ./hardware-configuration.nix
  ../../modules/nixos/disko-zfs.nix
  ../../modules/nixos/impermanence.nix
 ];

 # Host-specific settings.
 networking.hostName = "my-laptop"; # Must match the name in flake.nix

 # Define the user account for this machine.
 users.users.hbohlen = {
   isNormalUser = true;
   extraGroups = [ "wheel" "networkmanager" ]; # Sudo and network access.
   # The password should be set via a secure, declarative method.
   # For an impermanent system, this is critical, as imperative password setting
   # will be lost on reboot.[span_52](start_span)[span_52](end_span) Here we use a placeholder.
   # In a real system, this could be managed by sops-nix or agenix.
   initialPassword = "changeme";
 };

 # System timezone and locale.
 time.timeZone = "America/New_York";
 i18n.defaultLocale = "en_US.UTF-8";

 # Enable the system-wide services needed for the desktop.
 # This could be abstracted into its own module, e.g., `desktop-system.nix`.
 services.xserver.enable = true;
 services.xserver.displayManager.gdm.enable = true;
 services.xserver.desktopManager.gnome.enable = true;

 programs.hyprland.enable = true;
 xdg.portal = {
   enable = true;
   extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
 };

 # Enable sound.
 sound.enable = true;
 security.rtkit.enable = true;
 services.pipewire = {
   enable = true;
   alsa.enable = true;
   pulse.enable = true;
 };

 # This value determines the NixOS release from which the default
 # settings for stateful data, like file locations and database versions,
 # are taken. It's crucial for managing upgrades.
 system.stateVersion = "23.11";
}

The user's home.nix file, referenced by the main flake.nix, would then import the Home Manager modules:
# /users/hbohlen/home.nix
{... }:

{
 imports = [
  ../../modules/home-manager/desktop.nix
  ../../modules/home-manager/opnix.nix
   #... other home-manager modules like shell.nix, git.nix, etc.
 ];

 home.stateVersion = "23.11";
}

Deployment Script (./scripts/rebuild.sh)
To streamline the deployment process and avoid manual, error-prone commands, a simple helper script is invaluable. This script automates the process of building and applying the correct configuration for the machine it is run on. It detects the system's hostname and passes it as the target to the nixos-rebuild command, ensuring the correct nixosConfigurations entry from flake.nix is used.
#!/usr/bin/env bash
# /scripts/rebuild.sh

# Exit immediately if a command exits with a non-zero status.
set -e

# Automatically detect the hostname of the current machine.
HOSTNAME=$(hostname)
echo "--- Rebuilding system for host: $HOSTNAME ---"

# Navigate to the flake's root directory (assuming the script is run from there or a subdirectory).
FLAKE_DIR="$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd)"
cd "$FLAKE_DIR"

# Build and switch to the new configuration for the detected hostname.
# The --flake.#$HOSTNAME syntax targets the specific host output in flake.nix.[span_71](start_span)[span_71](end_span)[span_72](start_span)[span_72](end_span)
sudo nixos-rebuild switch --flake.#$HOSTNAME --use-remote-sudo

# Optional: Clean up old generations to save space.
# sudo nix-collect-garbage -d

echo "--- System rebuild complete for host: $HOSTNAME ---"

This script transforms the deployment workflow from a series of manual steps into a single, repeatable command (./scripts/rebuild.sh), embodying the principles of automation and reproducibility that are central to the NixOS philosophy.
Conclusion
This report has detailed a comprehensive architecture for a modern NixOS system that is modular, reproducible, secure, and ephemeral. By leveraging the power of Nix Flakes as a foundation, it integrates a sophisticated stack of technologies—Disko, ZFS with LUKS encryption, Impermanence, Hyprland, and Opnix—into a cohesive and manageable whole.
The key architectural patterns presented are:
1. Modular Flake Structure: A multi-host flake.nix with a helper function and a well-defined directory structure provides a scalable and maintainable foundation for managing a fleet of machines.
2. Declarative, Encrypted Filesystem: Disko enables the complete automation of disk setup, creating a robust, LUKS-encrypted ZFS pool with a dataset hierarchy specifically designed for an ephemeral system.
3. Robust Ephemerality: The combination of ZFS snapshot rollbacks and the impermanence module creates a stateless system that prevents configuration drift while allowing for the declarative persistence of critical system and user data.
4. Integrated Desktop and Secrets Management: Home Manager provides a fully declarative user environment, from the Hyprland window manager to application-level secrets managed securely at runtime by Opnix and 1Password.
The resulting system is not just a collection of configured tools but a unified, resilient platform where the state of every component is derived from a single source of truth. This approach minimizes administrative overhead, maximizes security, and provides a powerful, flexible environment for development and daily use.
For further extension, this architecture can be readily adapted. Adding a new host is as simple as creating a new entry in the /hosts directory and flake.nix. Custom packages or services can be defined in their own modules and imported where needed. For performance, a binary cache like Cachix or a self-hosted solution can be added to the configuration to share build artifacts between machines, significantly speeding up deployments. This architecture serves as a robust and expert-level foundation upon which to build a truly personalized and powerful computing experience.
Works cited
1. dc-tec/nixos-config: NixOS Configuration Repository - GitHub, https://github.com/dc-tec/nixos-config 2. NixOS as a server, part 1: Impermanence - Guekka's blog, https://guekka.github.io/nixos-server-1/ 3. ZFS, Encryption, Backups, and Convenience - yomaq, https://yomaq.github.io/posts/zfs-encryption-backups-and-convenience/ 4. flake.nix Configuration Explained | NixOS & Flakes Book, https://nixos-and-flakes.thiscute.world/nixos-with-flakes/nixos-flake-configuration-explained 5. Flakes - NixOS Wiki, https://nixos.wiki/wiki/Flakes 6. NixOS on a mirrored ZFS pool using disko, featuring opt-in persistence. - GitHub, https://github.com/KornelJahn/nixos-disko-zfs-test 7. nix-community/disko: Declarative disk partitioning and formatting using nix [maintainers=@Lassulus @Enzime @iFreilicht @Mic92 @phaer] - GitHub, https://github.com/nix-community/disko 8. How good is ZFS on root on NixOS? - Help, https://discourse.nixos.org/t/how-good-is-zfs-on-root-on-nixos/40512 9. Encrypted Root and ZFS on NixOS - Ryan Seipp, https://ryanseipp.com/post/nixos-encrypted-root/ 10. Ephemeral root partition on NixOS using ZFS - Wolfgang's Blog, https://notthebe.ee/blog/nixos-ephemeral-zfs-root/ 11. impermanence on NixOS? - Reddit, https://www.reddit.com/r/NixOS/comments/1lg3dem/impermanence_on_nixos/ 12. nix-community/impermanence: Modules to help you handle persistent state on systems with ephemeral root storage [maintainer=@talyz] - GitHub, https://github.com/nix-community/impermanence 13. Impermanence - NixOS Wiki, https://nixos.wiki/wiki/Impermanence 14. danielgafni/nixos: My NixOS configuration & dotfiles. Flakes, multi-host, multi-user, Hyprland. - GitHub, https://github.com/danielgafni/nixos 15. Hyprland starter pack - Help - NixOS Discourse, https://discourse.nixos.org/t/hyprland-starter-pack/32414 16. Getting Started with Home Manager | NixOS & Flakes Book, https://nixos-and-flakes.thiscute.world/nixos-with-flakes/start-using-home-manager 17. Opnix: Agenix inspired tool for injecting 1Password secrets into your ..., https://www.reddit.com/r/NixOS/comments/1gs6h4b/opnix_agenix_inspired_tool_for_injecting/ 18. fufexan/dotfiles: NixOS system config & Home-Manager user config - GitHub, https://github.com/fufexan/dotfiles 19. Simple steps to build a multi-machine flake for 3 machines + home manager? : r/NixOS, https://www.reddit.com/r/NixOS/comments/16cssv9/simple_steps_to_build_a_multimachine_flake_for_3/ 20. How to make one flake.nix for multiple hosts - Help - NixOS Discourse, https://discourse.nixos.org/t/how-to-make-one-flake-nix-for-multiple-hosts/62056 21. nix-config - Ambroisie's forge, https://git.belanyi.fr/ambroisie/nix-config/blame/commit/beb35737d94d1a31919fb17bff0a6294f794233b/flake.nix 22. Set up nixos + home manager via flake - Help, https://discourse.nixos.org/t/set-up-nixos-home-manager-via-flake/29710 23. Full Disk Encryption - NixOS Wiki, https://nixos.wiki/wiki/Full_Disk_Encryption 24. AntonHakansson/nixos-config: NixOS configuration of my machines - GitHub, https://github.com/AntonHakansson/nixos-config 25. How do you organize your `/persist`? - Help - NixOS Discourse, https://discourse.nixos.org/t/how-do-you-organize-your-persist/28256 26. Impermanence - Hacker News, https://news.ycombinator.com/item?id=37218289 27. Getting Started with Agenix | Mitchell Hanberg, https://www.mitchellhanberg.com/getting-started-with-agenix/ 28. NixOS Agenix (for secrets management) - splitbrain.org, https://www.splitbrain.org/blog/2025-07/27-agenix 29. Managing Secrets in NixOS Home Manager with SOPS - Zohaib, https://zohaib.me/managing-secrets-in-nixos-home-manager-with-sops/ 30. 1Password - NixOS Wiki, https://wiki.nixos.org/wiki/1Password 31. Get hostname in home-manager flake for host-dependent user ..., https://discourse.nixos.org/t/get-hostname-in-home-manager-flake-for-host-dependent-user-configs/18859
