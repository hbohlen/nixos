# AGENTS.md

## Directory Purpose
This directory contains comprehensive documentation and implementation files for the impermanence system, which enables ephemeral root filesystem with selective persistence.

## Files in This Directory
- `README.org` - Main documentation explaining the impermanence concept and implementation
- `nixos.nix` - NixOS module implementation for impermanence functionality
- `home-manager.nix` - Home Manager module for user-level impermanence configuration
- `flake.nix` - Standalone flake configuration for impermanence testing
- `lib.nix` - Helper functions and utilities for impermanence implementation
- `create-directories.bash` - Script for creating necessary persistent directories
- `mount-file.bash` - Script for handling file mounting in impermanence setup

## Dependencies
- Depends on the impermanence flake input from nix-community
- Integrates with ZFS filesystem for snapshot and rollback functionality
- Requires proper boot sequence configuration for initrd-based rollbacks
- Works with systemd services for directory and file management

## Notes for AI Agents
- This is a complex system that affects boot process and filesystem layout
- Changes to impermanence configuration can cause system boot failures if incorrect
- Test all impermanence changes thoroughly with nixos-rebuild build before switching
- Understand the relationship between persistent paths and system functionality
- Ensure critical system files and directories are properly persisted
- Consider the implications of ephemeral root on service data and user files