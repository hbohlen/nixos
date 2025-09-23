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
      # This prevents package version mismatches and build failures.
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
  outputs = { self, nixpkgs, home-manager, disko, impermanence, hyprland, opnix, ... }@inputs:
    let
      # Define a helper function to build a NixOS system configuration.
      # This pattern reduces boilerplate and enforces a consistent structure.
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

      # Helper to get pkgs for a given system without adding new inputs
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      # Define the NixOS configurations for each machine.
      # The key name (e.g., "laptop") must match the machine's hostname
      # for `nixos-rebuild` to pick it up automatically.
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

      # Provide a formatter so `nix fmt` works
      formatter = {
        x86_64-linux = (pkgsFor "x86_64-linux").nixfmt-rfc-style;
      };

      # Dev shell with common Nix tooling for contributors
      devShells = {
        x86_64-linux = {
          default = (pkgsFor "x86_64-linux").mkShell {
            packages = with (pkgsFor "x86_64-linux"); [
              nixfmt-rfc-style
              alejandra
              nil
              statix
              deadnix
            ];
          };
        };
      };
    };
}