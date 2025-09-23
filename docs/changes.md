# Changelog

All notable changes to this NixOS configuration will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Created comprehensive AGENTS.md files for all directories and subdirectories
- Added directory-specific guidance for AI agents working with NixOS configuration
- Enhanced documentation structure for better maintainability

### Changed
- Updated home.nix stateVersion from 23.11 to 25.05 for consistency with system configuration
- Restructured docs/changes.md to follow proper changelog format
- Consolidated allowUnfreePredicate configuration to prevent conflicts between hosts and common module

### Fixed
- Fixed duplicate environment.persistence."/persist" blocks in impermanence.nix that caused syntax errors
- Corrected mixed indentation (tabs/spaces) in users/hbohlen/home.nix
- Removed duplicate nixpkgs.config.allowUnfreePredicate definitions from host configurations
- Consolidated unfree package allowlist in common.nix to prevent configuration conflicts

### Removed
- Removed outdated changelog content that was actually troubleshooting information rather than changelog entries

## Previous Changes

The configuration has been significantly improved with fixes for:
- ZFS dataset inconsistencies between disko-layout.nix and impermanence.nix
- Proper service ordering with ZFS rollback in initrd stage
- SSH service dependency issues
- Boot process reliability improvements
- User home directory mounting issues
- Username propagation across all modules