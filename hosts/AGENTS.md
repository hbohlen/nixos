# AGENTS.md

## Directory Purpose
This directory contains host-specific NixOS configurations for different types of machines (desktop, laptop, server). Each subdirectory represents a distinct host with its own hardware configuration and specific system settings.

## Files in This Directory
- `desktop/` - Desktop computer configuration with Intel CPU + Nvidia GPU support and full desktop environment
- `laptop/` - Laptop configuration with power management and portable device optimizations  
- `server/` - Server configuration focused on minimal overhead and service hosting

## Dependencies
- Imports modules from `/modules/nixos/` for common system configurations
- Imports modules from `/modules/home-manager/` for user environment setup
- Depends on hardware-specific configurations in each host subdirectory
- References user configurations from `/users/` directory
- Uses disk layout definitions from root-level disko files

## Notes for AI Agents
- Each host should have a `default.nix` file as the main configuration entry point
- Hardware configurations should be in `hardware-configuration.nix` files
- Host-specific options like networking.hostName should be defined in the host's default.nix
- When adding new hosts, follow the existing pattern and ensure unique networking.hostId for ZFS systems
- Test configurations with `nixos-rebuild build --flake .#hostname` before switching