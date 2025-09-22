# NixOS Configuration

A modern, declarative, and ephemeral NixOS system with ZFS, Impermanence, and Hyprland.

## Architecture Overview

This is a modern, declarative NixOS system built on the "Erase Your Darlings" philosophy. The architecture combines:

- **Nix Flakes**: For reproducible, hermetic system definition
- **Disko**: For declarative partitioning
- **ZFS with LUKS encryption**: For advanced filesystem features
- **Impermanence**: For ephemeral root filesystem
- **Hyprland**: Wayland compositor for a modern desktop experience
- **Opnix**: For runtime secret injection via 1Password

## Project Structure

- `flake.nix`: Central entry point for all configuration
- `hosts/`: Machine-specific configurations
  - `laptop/`: Laptop-specific settings
  - `desktop/`: Desktop-specific settings
  - `server/`: Server-specific settings
- `modules/`: Reusable modules
  - `nixos/`: System-level modules
    - `common.nix`: Shared system configurations
    - `disko-zfs.nix`: Disk partitioning and ZFS setup
    - `impermanence.nix`: Ephemeral root configuration
  - `home-manager/`: User-level modules
    - `desktop.nix`: Hyprland and desktop applications
    - `opnix.nix`: Secret management
- `users/`: User accounts and Home Manager configurations
- `secrets/`: Placeholder for encrypted secrets
- `scripts/`: Helper scripts for system management

## Build Commands

- **Full system rebuild**: `./scripts/rebuild.sh` (auto-detects hostname)
- **Manual rebuild**: `sudo nixos-rebuild switch --flake .#hostname`
- **Test build**: `nixos-rebuild build --flake .#hostname`
- **Dry run**: `nixos-rebuild dry-activate --flake .#hostname`
- **Check configuration**: `nix flake check`

## Getting Started

1. Clone this repository
2. Customize `hosts/laptop/hardware-configuration.nix` for your hardware
3. Update the disk identifier in `modules/nixos/disko-zfs.nix`
4. Set your username and preferences in the `users` directory
5. Run `./scripts/rebuild.sh` to build and activate the configuration

## Key Features

- **Declarative System**: Everything from disk partitioning to application themes is defined as code
- **Ephemeral Root**: The root filesystem is reset to a pristine state on each boot
- **Persistent State**: Specific files and directories can be opted into persistence
- **Modern Desktop**: Hyprland Wayland compositor with a cohesive theme
- **Secret Management**: 1Password integration for secure runtime secret injection

## Customization

- Add new host configurations in the `hosts/` directory
- Create additional user configurations in the `users/` directory
- Extend functionality with new modules in the `modules/` directory
- Adjust the disk layout in `modules/nixos/disko-zfs.nix`
- Modify persistence rules in `modules/nixos/impermanence.nix`

## References

- [NixOS Documentation](https://nixos.org/manual/nixos/stable/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [Disko](https://github.com/nix-community/disko)
- [Impermanence](https://github.com/nix-community/impermanence)
- [Hyprland](https://hyprland.org/)
- [Opnix](https://github.com/brizzbuzz/opnix)