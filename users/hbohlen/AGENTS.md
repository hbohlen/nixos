# AGENTS.md

## Directory Purpose
This directory contains the Home Manager configuration for user 'hbohlen', defining personal environment settings, applications, and user-specific preferences.

## Files in This Directory
- `default.nix` - User account definition and basic configuration
- `home.nix` - Main Home Manager configuration file with user packages, services, and environment setup

## Dependencies
- Imports modules from `/modules/home-manager/desktop.nix` for desktop environment configuration
- Imports modules from `/modules/home-manager/opnix.nix` for secret management
- Depends on Home Manager flake input and nixpkgs for packages
- References system user configuration defined in host files

## Notes for AI Agents
- This configuration is specific to the user 'hbohlen' and contains personal preferences
- Package selections reflect development and productivity use cases
- 1Password integration is configured for SSH agent and secret management
- Desktop applications include code editors, browsers, and productivity tools
- When modifying, ensure changes align with the user's workflow and preferences
- Test changes by rebuilding Home Manager configuration: `home-manager switch --flake .#hbohlen`