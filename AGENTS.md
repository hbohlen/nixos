# NixOS Configuration - Agent Guidelines

## Build Commands
- **Full rebuild**: `./scripts/rebuild.sh` (auto-detects hostname)
- **Manual rebuild**: `sudo nixos-rebuild switch --flake .#hostname`
- **Test build**: `nixos-rebuild build --flake .#hostname`
- **Dry run**: `nixos-rebuild dry-activate --flake .#hostname`
- **Check config**: `nix flake check`
- **Format**: `./scripts/format.sh` or `npm run fmt`
- **Lint**: `./scripts/format.sh --check` or `npm run fmt:check`

## Code Style
- **Module signature**: `{ config, pkgs, lib, inputs, ... }:`
- **Imports**: Use relative paths `../../modules/`
- **Naming**: kebab-case files, camelCase options, snake_case vars
- **Formatting**: 2-space indent, trailing commas, <100 char lines
- **Types**: Use `lib.mkOption`, `lib.mkDefault`, `lib.mkIf`
- **Error handling**: `lib.optionalAttrs`, `lib.optionalString`
- **Security**: Never commit secrets, use Opnix/1Password for runtime secrets