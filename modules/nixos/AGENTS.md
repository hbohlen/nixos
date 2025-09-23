# AGENTS.md

## Directory Purpose
This directory contains system-level NixOS modules that configure core system functionality, disk management, filesystems, and hardware-specific settings.

## Files in This Directory
- `common.nix` - Shared system configurations used across all hosts including base packages and services
- `disko-zfs.nix` - Declarative disk partitioning and ZFS filesystem configuration using Disko
- `impermanence.nix` - Ephemeral root filesystem configuration with selective persistence using the impermanence module
- `nvidia-rog.nix` - NVIDIA graphics and ROG (Republic of Gamers) hardware-specific configuration

## Dependencies
- `disko-zfs.nix` depends on the disko flake input for declarative partitioning
- `impermanence.nix` depends on the impermanence flake input for ephemeral root functionality
- `nvidia-rog.nix` depends on NVIDIA proprietary drivers and ROG-specific kernel modules
- All modules may import and use nixpkgs packages and NixOS system options

## Notes for AI Agents
- These modules configure critical system infrastructure and should be tested carefully
- ZFS configuration requires proper pool names and dataset structure consistency
- Impermanence configuration must properly define what files/directories to persist
- NVIDIA configuration often requires careful kernel module and driver version management
- Changes to disk or filesystem configuration can be destructive - always test with nixos-rebuild build first
- Ensure hardware-specific modules only activate on appropriate hardware