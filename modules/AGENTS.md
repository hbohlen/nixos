# AGENTS.md

## Directory Purpose
This directory contains reusable NixOS and Home Manager modules that can be imported by multiple host configurations. It promotes code reuse and modular configuration management.

## Files in This Directory
- `nixos/` - System-level NixOS modules for core system functionality
- `home-manager/` - User-level modules for desktop environment and application configuration

## Dependencies
- NixOS modules may depend on external inputs like impermanence, disko, and other flake inputs
- Home Manager modules depend on the home-manager flake input
- Modules may have interdependencies within this directory
- Host configurations import and configure these modules

## Notes for AI Agents
- Keep modules focused and single-purpose for maximum reusability
- Use proper NixOS module structure with options, config, and imports
- Document module options and provide sensible defaults
- Test modules across multiple host types to ensure portability
- Avoid host-specific hardcoded values in shared modules
- Use lib.mkOption for configurable parameters and lib.mkDefault for overridable defaults