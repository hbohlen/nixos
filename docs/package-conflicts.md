# Package Conflicts and Resolution

## Node.js Conflict Resolution

### Problem
The build failed with a `pkgs.buildEnv error` due to conflicting subpaths for `nodejs-22.19.0`:
```
pkgs.buildEnv error: two given paths contain a conflicting subpath:
  `/nix/store/vgq8n9nkzgi1ippizg3ys4ar4dr0qp5l-nodejs-22.19.0/include/node/config.gypi' and
  `/nix/store/r4557ald6zn4dzmvgh8na9vwnwzgrjgc-nodejs-22.19.0/include/node/config.gypi'
```

### Root Cause
The same version of Node.js was being included from multiple sources in the Home Manager build environment:
1. **User-level** (`users/hbohlen/home.nix`): `nodejs` + `nodePackages.npm`
2. **System-level development** (`modules/nixos/development.nix`): `nodejs` + `nodePackages.npm`  
3. **System-level server** (`modules/nixos/server.nix`): `nodejs`

### Solution
Centralized Node.js configuration to avoid duplicates:

1. **System-level Node.js**: Keep in `modules/nixos/development.nix` (only active when `development.enable = true`)
2. **User-level tools**: Keep `nodePackages.npm` in `users/hbohlen/home.nix` for user-specific npm packages
3. **Server environments**: Removed Node.js from `modules/nixos/server.nix` (can enable development module if needed)

### Changes Made
```diff
# users/hbohlen/home.nix
- nodejs
+ # nodejs - provided by system-level development module to avoid conflicts

# modules/nixos/server.nix  
- nodejs
+ # nodejs - removed to avoid conflicts, use development module if needed

# modules/nixos/development.nix (unchanged)
+ # NOTE: nodejs and npm are provided system-wide here to avoid conflicts
+ # with user-level Home Manager packages
nodejs
nodePackages.npm
```

## Best Practices for Package Management

### System vs User Package Guidelines
- **System packages** (`environment.systemPackages`): Core system tools, development environments, shared utilities
- **User packages** (`home.packages`): User-specific applications, personal tools, configuration-specific packages

### Avoiding Conflicts
1. **Centralize common packages**: Place shared development tools in system modules
2. **Use conditional imports**: Enable modules only where needed (e.g., `development.enable = true`)
3. **Document package locations**: Add comments explaining where packages are provided
4. **Regular conflict checks**: Test builds regularly, especially when adding new packages

### Module Organization
- `modules/nixos/development.nix`: Development tools (nodejs, python, go, etc.)
- `modules/nixos/server.nix`: Server-specific utilities (no development tools by default)
- `users/{username}/home.nix`: User-specific applications and tools
- Host configs: Enable appropriate modules (`development.enable = true` for desktop/laptop)