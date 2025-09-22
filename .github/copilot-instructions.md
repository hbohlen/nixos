# Copilot Instructions for AI Coding Agents

## Project Overview
This repository defines a modern, declarative NixOS system using Nix Flakes, Disko, ZFS (with LUKS), Impermanence, and Home Manager. The architecture is designed for reproducibility, ephemeral root, and secure secret management (Opnix/1Password). Hosts are organized by role (desktop, laptop, server) with shared modules and user overlays.

## Key Files & Structure
- `flake.nix`: Entry point, defines inputs, outputs, and host/module wiring
- `hosts/`: Per-host configs (e.g., `desktop/`, `laptop/`, `server/`)
- `modules/`: Reusable modules (system and home-manager)
- `users/`: User-specific Home Manager configs
- `scripts/rebuild.sh`: Main build script (auto-detects host)
- `secrets/`: Placeholder for encrypted secrets (never commit real secrets)

## Build & Workflow
- **Full rebuild:** `./scripts/rebuild.sh` (preferred)
- **Manual:** `sudo nixos-rebuild switch --flake .#hostname`
- **Test:** `nixos-rebuild build --flake .#hostname`
- **Check:** `nix flake check`
- Always test with `nixos-rebuild build` before switching

## Nix Conventions
- All modules use `{ config, pkgs, lib, inputs, ... }:` signature
- Use relative imports (e.g., `../../modules/`)
- Filenames: kebab-case; Nix options: camelCase; String vars: snake_case
- 2-space indentation, trailing commas, <100 char lines
- Use `lib.mkDefault` for overridable values, `lib.mkIf` for conditionals
- Use `lib.optionalAttrs` and `lib.optionalString` for conditional logic
- Never commit secrets; use 1Password/Opnix for runtime secrets

## Impermanence & Persistence
- Root is ephemeral (tmpfs); persistent state is opt-in via `/persist`
- See `modules/impermanence.nix` for what is persisted

## Disko & ZFS
- Disk layout and ZFS pools are defined declaratively (see `modules/zfs.nix`)
- Update device paths as needed for new hardware

## Home Manager
- User environments are managed via Home Manager modules
- User overlays in `users/` and `modules/home-manager/`

## Security
- Use SSH keys, not passwords (initialPassword is for setup only)
- Never store secrets in the repo

## Example: Adding a New Host
1. Copy an existing host dir in `hosts/`
2. Update hardware config and host-specific options
3. Add to `flake.nix` outputs
4. Run `./scripts/rebuild.sh`

## Troubleshooting
- Use `nix flake check` for flake errors
- Validate hardware-specific configs on target hardware
- For ZFS/disko/impermanence issues, check module wiring in `flake.nix`

---
For more, see `README.md` and `AGENTS.md`.
