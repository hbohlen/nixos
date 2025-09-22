# NixOS Configuration - Agent Guidelines

## Architecture Overview
This is a modern, declarative NixOS system built on the "Erase Your Darlings" philosophy. The architecture combines Nix Flakes, Disko for declarative partitioning, ZFS with LUKS encryption, Impermanence for ephemeral root filesystem, Hyprland Wayland compositor, and Opnix for runtime secret injection via 1Password.

## Build Commands
- **Full system rebuild**: `./scripts/rebuild.sh` (auto-detects hostname)
- **Manual rebuild**: `sudo nixos-rebuild switch --flake .#hostname`
- **Test build**: `nixos-rebuild build --flake .#hostname`
- **Dry run**: `nixos-rebuild dry-activate --flake .#hostname`
- **Check configuration**: `nix flake check`

## Code Style Guidelines

### Nix Module Structure
- Use consistent function signature: `{ config, pkgs, lib, inputs, ... }:`
- Always include `...` for module system compatibility
- Group related options in attribute sets
- Use descriptive comments above major sections

### Imports and Organization
- Import modules at the top of each file
- Use relative paths: `../../modules/`
- Group imports by type (system modules, home-manager modules, etc.)
- Keep flake inputs in `flake.nix` only

### Naming Conventions
- Use kebab-case for filenames: `disko-zfs.nix`, `home-manager/`
- Use camelCase for Nix options: `networking.hostName`
- Use snake_case for variables in strings: `CPU_SCALING_GOVERNOR_ON_AC`

### Formatting
- 2-space indentation
- Align attribute sets vertically
- Use trailing commas in lists and attribute sets
- Keep lines under 80-100 characters when possible

### Types and Validation
- Use `lib.mkOption` for custom options with proper types
- Prefer `lib.mkDefault` over direct assignment for overridable values
- Use `lib.mkIf` for conditional configuration
- Validate inputs with `lib.asserts` when necessary

### Error Handling
- Use `lib.optionalAttrs` for conditional attribute inclusion
- Wrap potentially failing operations in `lib.optionalString`
- Provide meaningful error messages in assertions
- Use `lib.warn` for deprecation notices

### Security
- Never commit secrets or sensitive data
- Use `initialPassword` only for temporary setup
- Prefer SSH key authentication over passwords
- Use `allowUnfreePredicate` instead of global `allowUnfree`

### Testing
- Test configurations with `nixos-rebuild build` before switching
- Use `nix flake check` to verify flake structure
- Test on multiple hosts when making core module changes
- Verify hardware-specific configurations work on target hardware