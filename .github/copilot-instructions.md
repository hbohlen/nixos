# Copilot Instructions for AI Coding Agents

## Project Architecture & Philosophy
This repository implements a modern, reproducible NixOS system using Nix Flakes, Disko (for declarative partitioning), ZFS (with LUKS encryption), Impermanence (ephemeral root, opt-in persistence), and Home Manager. Hosts are organized by role (desktop, laptop, server) with shared modules and overlays. Secrets are managed at runtime via Opnix/1Password—**never commit secrets**.

### Key Files & Structure
- `flake.nix`: Entry point, defines all inputs, outputs, and host/module wiring
- `hosts/`: Per-host configs (e.g., `desktop/`, `laptop/`, `server/`)
- `modules/`: Reusable modules (system and home-manager)
- `users/`: User-specific Home Manager configs
- `scripts/rebuild.sh`: Main build script (auto-detects host)
- `secrets/`: Placeholder for encrypted secrets (never commit real secrets)

### Build & Workflow
- **Full system rebuild:** `./scripts/rebuild.sh` (preferred, auto-detects host)
- **Manual rebuild:** `sudo nixos-rebuild switch --flake .#hostname`
- **Test build:** `nixos-rebuild build --flake .#hostname`
- **Dry run:** `nixos-rebuild dry-activate --flake .#hostname`
- **Check flake:** `nix flake check`
- Always test with `nixos-rebuild build` before switching

### Nix Conventions & Patterns
- All modules use `{ config, pkgs, lib, inputs, ... }:` signature (always include `...`)
- Use relative imports (e.g., `../../modules/`)
- Filenames: kebab-case; Nix options: camelCase; String vars: snake_case
- 2-space indentation, trailing commas, <100 char lines
- Use `lib.mkDefault` for overridable values, `lib.mkIf` for conditionals
- Use `lib.optionalAttrs` and `lib.optionalString` for conditional logic
- Use `lib.mkOption` for custom options with types
- Never commit secrets; use Opnix/1Password for runtime secrets

### Impermanence & Persistence
- Root is ephemeral (tmpfs); persistent state is opt-in via `/persist`
- See `modules/impermanence.nix` for what is persisted

### Disko & ZFS
- Disk layout and ZFS pools are defined declaratively (see per-host `hardware/disko-zfs.nix` files)
- Update device paths as needed for new hardware

### Home Manager
- User environments are managed via Home Manager modules
- User overlays in `users/` and `modules/home-manager/`

### Security
- Use SSH keys, not passwords (initialPassword is for setup only)
- Never store secrets in the repo

### Adding a New Host (Example)
1. Copy an existing host dir in `hosts/`
2. Update hardware config and host-specific options
3. Add to `flake.nix` outputs
4. Run `./scripts/rebuild.sh`

### Troubleshooting & Testing
- Use `nix flake check` for flake errors
- Validate hardware-specific configs on target hardware
- For ZFS/disko/impermanence issues, check module wiring in `flake.nix`

---
**For more details, see `README.md` and `AGENTS.md`.**
