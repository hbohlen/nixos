# unfree-packages.nix - Centralized Unfree Package Management

**Location:** `modules/nixos/unfree-packages.nix`

## Purpose

Provides centralized management of unfree (proprietary) package allowances across the entire NixOS configuration. This prevents conflicts from multiple modules defining `allowUnfreePredicate` and ensures consistent unfree package policy.

## Dependencies

- **Integration:** Automatically imported by `common.nix`
- **External:** NixOS package system, nixpkgs unfree packages
- **Usage:** Referenced by all other modules that need unfree packages

## Features

### Centralized Unfree Package Allowlist

#### Complete Package List
```nix
nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  # 1Password family
  "1password"
  "1password-cli" 
  "1password-gui"
  
  # Development tools
  "vscode"
  "code"
  
  # Browsers
  "vivaldi"
  "chrome"
  "google-chrome"
  
  # NVIDIA drivers and tools
  "nvidia-x11"
  "nvidia-settings"
  "nvidia-persistenced"
  "libnvidia-ml"
  "nvidia-vaapi-driver"
  "cuda"
  "cudatoolkit"
  
  # Archive and compression tools
  "rar"
  "unrar"
  
  # Hardware support
  "libfprint-2-tod1-goodix"    # Fingerprint reader driver
];
```

### Package Categories

#### Security and Authentication
- **1Password suite:** Complete 1Password ecosystem support
  - `1password` - Core 1Password package
  - `1password-cli` - Command-line interface
  - `1password-gui` - Graphical user interface

#### Development Tools
- **Code Editors:** Professional development environments
  - `vscode` - Visual Studio Code editor
  - `code` - Alternative VS Code package name

#### Web Browsers
- **Chromium-based browsers:** 
  - `vivaldi` - Vivaldi browser
  - `chrome` / `google-chrome` - Google Chrome browser

#### Graphics and GPU
- **NVIDIA ecosystem:** Complete NVIDIA driver support
  - `nvidia-x11` - Main NVIDIA drivers
  - `nvidia-settings` - NVIDIA control panel
  - `nvidia-persistenced` - NVIDIA persistence daemon
  - `libnvidia-ml` - NVIDIA Management Library
  - `nvidia-vaapi-driver` - NVIDIA VA-API support
  - `cuda` / `cudatoolkit` - CUDA development toolkit

#### File Compression
- **RAR support:**
  - `rar` - RAR archiver
  - `unrar` - RAR extractor

#### Hardware Drivers
- **Biometric devices:**
  - `libfprint-2-tod1-goodix` - Goodix fingerprint reader support

## Usage Examples

### Standard Configuration
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/common.nix    # Automatically includes unfree-packages.nix
  ];
  
  # Unfree packages are automatically allowed based on the centralized list
  environment.systemPackages = with pkgs; [
    vscode           # Allowed by unfree-packages.nix
    _1password-gui   # Allowed by unfree-packages.nix
    firefox          # Free package, no restriction needed
  ];
}
```

### Adding New Unfree Packages
To add a new unfree package to the system:

1. **Add to allowlist** in `modules/nixos/unfree-packages.nix`:
```nix
nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  # ... existing packages ...
  "your-new-unfree-package"
];
```

2. **Use in any module** or host configuration:
```nix
environment.systemPackages = with pkgs; [
  your-new-unfree-package    # Now allowed system-wide
];
```

### Gaming Configuration Example
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/common.nix
    ../../modules/nixos/desktop.nix
  ];
  
  desktop.enable = true;
  
  # These unfree packages are allowed by the central allowlist
  environment.systemPackages = with pkgs; [
    # Gaming platforms (would need to be added to allowlist)
    # steam              # Usually free
    # discord            # Usually free
    
    # Proprietary tools that are already allowed
    nvidia-settings      # NVIDIA control panel
    rar                  # RAR compression
  ];
}
```

### Development Environment
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/common.nix
    ../../modules/nixos/development.nix
  ];
  
  development.enable = true;
  
  # Development tools with unfree components
  environment.systemPackages = with pkgs; [
    vscode               # Already allowed
    cudatoolkit         # NVIDIA CUDA development (already allowed)
    
    # Would need to add these to allowlist if needed:
    # jetbrains.idea-ultimate
    # sublime4
    # slack
  ];
}
```

## Advanced Configuration

### Conditional Unfree Allowance
For more complex scenarios, you can extend the basic allowlist:

```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/unfree-packages.nix
  ];
  
  # Extend the basic allowlist with host-specific packages
  nixpkgs.config.allowUnfreePredicate = pkg: 
    let
      # Get the base allowlist
      baseAllowed = builtins.elem (lib.getName pkg) [
        "1password" "1password-cli" "1password-gui"
        "vscode" "code"
        "nvidia-x11" "nvidia-settings"
        # ... rest of base list
      ];
      
      # Add host-specific unfree packages
      hostSpecific = builtins.elem (lib.getName pkg) [
        "teamviewer"
        "zoom-us"
        "slack"
      ];
    in
    baseAllowed || hostSpecific;
}
```

### Per-Module Unfree Requirements
Different modules have different unfree package requirements:

#### Desktop Module Unfree Needs
```nix
# Typically requires:
# - None (desktop module uses mostly free packages)
# - vscode (development)
# - browsers (if proprietary ones are preferred)
```

#### NVIDIA Module Unfree Needs  
```nix
# Requires all NVIDIA packages:
# - nvidia-x11
# - nvidia-settings
# - nvidia-persistenced
# - libnvidia-ml
# - nvidia-vaapi-driver
# - cuda / cudatoolkit
```

#### Development Module Unfree Needs
```nix
# May require:
# - vscode
# - jetbrains IDEs
# - proprietary development tools
```

## Adding New Packages

### Step-by-Step Process

1. **Identify the package name:**
```bash
# Find the exact package name
nix search nixpkgs packagename
# or
nix-env -qaP | grep packagename
```

2. **Check if it's unfree:**
```bash
# Try to install and see if it's blocked
nix-shell -p packagename
# If it fails with unfree error, it needs to be added to allowlist
```

3. **Add to allowlist:**
```nix
# In modules/nixos/unfree-packages.nix
nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  # ... existing packages ...
  "new-package-name"
];
```

4. **Test the addition:**
```bash
# Rebuild and test
sudo nixos-rebuild build --flake .#hostname
nix-shell -p new-package-name    # Should work now
```

### Common Unfree Packages

#### Communication and Productivity
```nix
# Common additions you might need:
"slack"                    # Team communication
"discord"                  # Gaming/community communication  
"zoom-us"                  # Video conferencing
"teams"                    # Microsoft Teams
"skype"                    # Skype communication
"teamviewer"               # Remote desktop
```

#### Development Tools
```nix
# Professional development environments:
"jetbrains.idea-ultimate"      # IntelliJ IDEA Ultimate
"jetbrains.pycharm-professional"  # PyCharm Professional
"jetbrains.webstorm"           # WebStorm IDE
"sublime4"                     # Sublime Text 4
"sublime-merge"                # Sublime Merge Git client
```

#### Multimedia and Creative
```nix
# Creative software:
"davinci-resolve"              # Video editing
"adobe-reader"                 # PDF reader
"spotify"                      # Music streaming
"steam"                        # Gaming platform (sometimes unfree)
```

#### System Utilities
```nix
# System tools:
"anydesk"                      # Remote desktop
"dropbox"                      # Cloud storage
"google-drive-ocamlfuse"       # Google Drive integration
"plex-media-server"            # Media server
```

## Integration with Other Modules

### Automatic Integration
The unfree-packages module is automatically imported by `common.nix`, so all other modules can safely use unfree packages without defining their own `allowUnfreePredicate`.

### Module-Specific Requirements

#### With Desktop Module
```nix
# Desktop module can safely use:
environment.systemPackages = with pkgs; [
  vscode               # Development
  _1password-gui       # Security
  # Any other packages in the allowlist
];
```

#### With NVIDIA Module
```nix
# NVIDIA module automatically gets access to:
# - All NVIDIA drivers and tools
# - CUDA development environment
# - Hardware acceleration packages
```

#### With Development Module
```nix
# Development module can use:
# - Professional IDEs (if added to allowlist)
# - Proprietary development tools
# - Commercial compilers and debuggers
```

## Troubleshooting

### Package Not Allowed Error
```bash
# Error message example:
# Package 'package-name' has an unfree license, refusing to evaluate.

# Solution: Add package to unfree-packages.nix allowlist
```

### Finding Package Names
```bash
# Method 1: Search nixpkgs
nix search nixpkgs package-name

# Method 2: Use nix-env
nix-env -qaP | grep -i package

# Method 3: Check derivation name
nix-instantiate --eval -E 'with import <nixpkgs> {}; lib.getName package-name'
```

### Multiple allowUnfreePredicate Definitions
```bash
# Error: multiple definitions of allowUnfreePredicate
# Solution: Remove duplicate definitions, use only the centralized one
```

### Package Still Not Available
```bash
# Check if package is actually in nixpkgs
nix search nixpkgs package-name

# Check if it's available in your channel
nix-channel --list
nix-channel --update

# Try different package variations
nix search nixpkgs ".*package.*"
```

## Security Considerations

### Unfree Package Security
- **Source verification:** Unfree packages may not be auditable
- **License compliance:** Ensure organizational license compliance  
- **Update frequency:** Proprietary packages may have slower security updates
- **Dependency analysis:** Review unfree package dependencies

### Best Practices

#### Minimize Unfree Usage
```nix
# Prefer free alternatives when possible:
# - LibreOffice instead of Microsoft Office
# - Firefox instead of Chrome
# - VS Codium instead of VS Code
# - GIMP instead of Photoshop
```

#### Regular Review
```nix
# Periodically review unfree package list:
# 1. Remove unused packages
# 2. Check for free alternatives
# 3. Verify license compliance
# 4. Update to newer versions
```

#### Documentation
```nix
# Document why each unfree package is needed:
nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  "nvidia-x11"        # Required for NVIDIA GPU support
  "1password-gui"     # Corporate security requirement
  "vscode"            # Development team standard
  # ... etc
];
```

## Maintenance

### Regular Updates
1. **Review package list** quarterly
2. **Remove unused packages** to minimize unfree footprint
3. **Check for free alternatives** that may have become available
4. **Update package versions** when new releases are available

### Adding Team Packages
When working in teams:
1. **Discuss unfree additions** with team members
2. **Document business justification** for each unfree package
3. **Consider license implications** for the organization
4. **Maintain centralized list** for consistency across team members

### Migration Path
If moving away from unfree packages:
1. **Identify free alternatives**
2. **Test compatibility** with existing workflows
3. **Gradual migration** rather than sudden changes
4. **Update documentation** to reflect changes

The unfree-packages module provides a clean, centralized way to manage proprietary software requirements while maintaining visibility into what unfree software is being used across the system.