# AGENTS.md

## Directory Purpose
This directory contains user-specific Home Manager configurations that define individual user accounts and their personal environment settings.

## Files in This Directory
- `hbohlen/` - User configuration directory for the user 'hbohlen' containing Home Manager settings

## Dependencies
- User directories import modules from `/modules/home-manager/` for shared functionality
- References system-level user account definitions from host configurations
- Depends on Home Manager flake input for user environment management
- May use packages and services from nixpkgs

## Notes for AI Agents
- Each user should have their own subdirectory with personalized configurations
- User configurations should import appropriate home-manager modules for their needs
- Personal preferences, packages, and dotfiles should be defined in user-specific files
- Avoid system-level configurations in user directories - those belong in `/modules/nixos/`
- Test user configurations by building and activating Home Manager configurations
- Consider different user roles (developer, gamer, admin) when structuring user configs