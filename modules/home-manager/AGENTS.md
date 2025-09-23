# AGENTS.md

## Directory Purpose
This directory contains user-level Home Manager modules that configure desktop environments, applications, and user-specific settings that don't require root privileges.

## Files in This Directory
- `desktop.nix` - Desktop environment configuration including Hyprland Wayland compositor and desktop applications
- `opnix.nix` - Secret management configuration using Opnix for 1Password integration

## Dependencies
- `desktop.nix` may depend on Hyprland flake input and various desktop application packages
- `opnix.nix` depends on the opnix flake input for 1Password CLI and secret management
- Both modules use Home Manager module system and nixpkgs packages
- May reference user-specific configurations and preferences

## Notes for AI Agents
- These modules configure user-level applications and don't require root privileges
- Desktop configuration should focus on window managers, themes, and user applications
- Secret management should never commit actual secrets - use runtime secret injection
- Test desktop configurations on actual display hardware as Wayland/X11 behavior varies
- Ensure proper integration between desktop environment components
- Use Home Manager options and services for user-level daemon management
- Consider different user preferences and make configurations customizable through options