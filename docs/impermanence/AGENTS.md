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

### ZFS Impermanence Implementation Details
- Uses ZFS datasets: `rpool/local/root` (ephemeral), `rpool/safe/persist` (persistent)
- Root dataset is rolled back to `@blank` snapshot on each boot
- Rollback happens in initrd via systemd service for proper timing
- Persistent data is bind-mounted from `/persist` to appropriate locations
- Configuration follows modern best practices with initrd systemd integration
- Boot process: initrd -> import pool -> rollback -> mount sysroot -> bind mounts

### Critical Boot Dependencies
- `zfs-import-rpool.service` must complete before rollback
- `zfs-rollback` service must complete before `sysroot.mount`
- Persistent directories must exist before services that need them start
- SSH host keys are persisted to avoid regeneration on each boot