# AGENTS.md

## Directory Purpose
This directory contains the desktop host configuration, optimized for a full desktop experience with multimedia capabilities, development tools, and Intel/Nvidia hardware support.

## Files in This Directory
- `default.nix` - Main desktop system configuration with desktop-specific settings and module imports
- `hardware-configuration.nix` - Hardware-specific configuration for Intel CPU + Nvidia GPU desktop systems

## Dependencies
- Imports common system modules from `/modules/nixos/common.nix`
- Imports ZFS and disk configuration from `./hardware/disko-zfs.nix` (host-specific)  
- Imports impermanence configuration from `/modules/nixos/impermanence.nix`
- Imports NVIDIA-specific configuration from `/profiles/graphics/nvidia-desktop.nix`
- References user configurations through Home Manager integration
- Uses root-level flake.nix for system definition

## Notes for AI Agents
- This host is configured for high-performance desktop use with Intel CPU and Nvidia GPU
- Gaming support has been removed - this is now a general-purpose desktop configuration
- Ensure hardware-configuration.nix matches Intel CPU + Nvidia GPU desktop hardware
- Desktop-specific packages and services should be defined here rather than in common modules
- Test Nvidia driver changes carefully as they involve proprietary drivers and kernel modules
- Use MSI motherboard profiles from nixos-hardware when available