# Changelog

All notable changes to this NixOS configuration will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Created comprehensive AGENTS.md files for all directories and subdirectories
- Added directory-specific guidance for AI agents working with NixOS configuration  
- Enhanced documentation structure for better maintainability
- **NEW**: Comprehensive LiveISO installation guide with step-by-step ZFS setup
- **NEW**: Detailed troubleshooting section for common installation issues
- **NEW**: Hardware-specific installation instructions for Intel/Nvidia systems
- **NEW**: Intel CPU and desktop PC hardware profiles from nixos-hardware
- **NEW**: Enhanced ZFS impermanence documentation with boot process details

### Changed
- Updated home.nix stateVersion from 23.11 to 25.05 for consistency with system configuration
- Restructured docs/changes.md to follow proper changelog format
- Consolidated allowUnfreePredicate configuration to prevent conflicts between hosts and common module
- **UPDATED**: Desktop configuration from AMD/gaming to Intel/general-purpose setup
- **UPDATED**: Hardware configurations to support Intel CPU + Nvidia GPU combinations
- **UPDATED**: README.md with comprehensive installation and hardware requirements
- **UPDATED**: Desktop AGENTS.md to reflect gaming removal and Intel/Nvidia focus
- **UPDATED**: Laptop AGENTS.md with specific ASUS ROG Zephyrus M16 GU603ZW details
- **UPDATED**: Impermanence AGENTS.md with ZFS implementation details

### Fixed
- Fixed duplicate environment.persistence."/persist" blocks in impermanence.nix that caused syntax errors
- Corrected mixed indentation (tabs/spaces) in users/hbohlen/home.nix
- Removed duplicate nixpkgs.config.allowUnfreePredicate definitions from host configurations
- Consolidated unfree package allowlist in common.nix to prevent configuration conflicts

### Removed
- Removed outdated changelog content that was actually troubleshooting information rather than changelog entries
- **REMOVED**: Gaming support completely (hosts/desktop/gaming.nix)
- **REMOVED**: Gaming-related packages (Steam, Lutris, Wine, GameMode, MangoHUD, Discord)
- **REMOVED**: AMD-specific optimizations and kernel parameters (amd_pstate=active)
- **REMOVED**: AMD CPU microcode configuration in favor of Intel
- **REMOVED**: Gaming module import from flake.nix extraModules

## Previous Changes

The configuration has been significantly improved with fixes for:
- ZFS dataset inconsistencies between disko-layout.nix and impermanence.nix
- Proper service ordering with ZFS rollback in initrd stage
- SSH service dependency issues
- Boot process reliability improvements
- User home directory mounting issues
- Username propagation across all modules