# AGENTS.md

## Directory Purpose
This directory serves as a placeholder for runtime secret injection. It is deliberately kept empty as secrets should never be committed to the repository. Instead, secrets are managed at runtime via Opnix/1Password integration.

## Files in This Directory
- This directory should remain empty in the repository
- No secret files should ever be committed here
- Runtime secrets are injected via the Opnix module and 1Password integration

## Dependencies
- Depends on the Opnix flake input for 1Password secret management
- Integrates with the Home Manager opnix module in `modules/home-manager/opnix.nix`
- Requires 1Password CLI and proper authentication for secret injection

## Notes for AI Agents
- **NEVER** commit any actual secret files to this directory
- **NEVER** store passwords, API keys, certificates, or any sensitive data in files here
- This directory exists only as a placeholder for runtime secret mounting
- All secret management should be done through Opnix/1Password integration
- If you see any actual secret files here, they should be removed immediately and the git history cleaned
- Use the `secrets/` path only for runtime secret injection, never for storage