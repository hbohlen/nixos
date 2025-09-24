# AGENTS.md

## Directory Purpose
This directory contains utility scripts for managing the NixOS configuration, including system rebuilding, installation automation, and code formatting.

## Files in This Directory
- `bootstrap.sh` - Quick bootstrap script that can be run directly from the web for one-line installation
- `install.sh` - Comprehensive NixOS installation script for disko-ZFS-impermanence setup from live ISO
- `rebuild.sh` - Automated system rebuild script that detects the current hostname and rebuilds the appropriate configuration
- `format.sh` - Code formatting script that applies consistent formatting to Nix files using various formatters

## Dependencies
- `bootstrap.sh` requires internet connection and curl/wget for downloading, designed for live ISO environment
- `install.sh` requires live NixOS ISO environment, git, nix with flakes, disko, zfs, and cryptsetup tools
- `rebuild.sh` depends on nixos-rebuild command and flake.nix system definitions
- `format.sh` depends on formatting tools like Prettier, Alejandra, or nixfmt-rfc-style
- All scripts depend on being run from the repository root directory (except bootstrap.sh)
- May depend on npm packages defined in package.json for formatting

## Notes for AI Agents
- `bootstrap.sh` provides the quickest installation method - can be run directly from the web with a single command
- `install.sh` is the comprehensive installation script for new systems using disko-ZFS-impermanence setup
- `rebuild.sh` should be the preferred method for system rebuilds as it auto-detects the hostname
- `format.sh` ensures consistent code style across all Nix files in the repository
- Scripts should be kept executable and tested on all supported host types
- Consider error handling and user feedback in script implementations
- Update scripts when adding new hosts or changing the repository structure
- Both installation scripts include comprehensive error handling and cleanup procedures for safe installation