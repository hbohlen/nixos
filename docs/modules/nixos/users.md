# users.nix - User Account Management

**Location:** `modules/nixos/users.nix`

## Purpose

Provides declarative user account management with SSH key authentication, role-based group assignment, and security-focused user configuration. Supports different host types with appropriate group memberships.

## Dependencies

- **Variables:** Requires `username` parameter passed from host configuration
- **External:** NixOS user management system, SSH service

## Configuration Options

### `users.hostType`
- **Type:** `enum [ "desktop" "laptop" "server" ]`
- **Default:** `"desktop"`
- **Description:** Determines user group membership based on host role

### `users.sshKeys`
- **Type:** `listOf string`
- **Default:** `[]`
- **Description:** List of SSH public keys for user authentication
- **Example:** `[ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample... user@host" ]`

### `users.enablePasswordAuth`
- **Type:** `boolean`
- **Default:** `true`
- **Description:** Enable password authentication (should be disabled for production)

## Features

### User Account Configuration

#### Primary User Setup
```nix
users.users.${username} = {
  isNormalUser = true;
  description = "Hayden Bohlen";
  extraGroups = [ "wheel" "networkmanager" ]
    ++ lib.optionals (config.users.hostType != "server") [ "video" "audio" ];
  
  openssh.authorizedKeys.keys = config.users.sshKeys;
  group = username;
  createHome = true;
  home = "/home/${username}";
};
```

#### Group Membership by Host Type

**Desktop/Laptop Hosts:**
- `wheel` - Administrative privileges (sudo access)
- `networkmanager` - Network configuration
- `video` - Graphics hardware access
- `audio` - Audio hardware access

**Server Hosts:**
- `wheel` - Administrative privileges (sudo access)
- `networkmanager` - Network configuration
- No video/audio groups (unnecessary for headless systems)

### Authentication Methods

#### SSH Key Authentication (Recommended)
```nix
# Configure SSH keys
users.sshKeys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample... user@desktop"
  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDExample... user@laptop"
];

# Disable password auth when SSH keys are configured
users.enablePasswordAuth = false;
```

#### Password Authentication (Initial Setup Only)
```nix
# Initial password (change immediately after first login)
initialPassword = "changeme";

# Automatic password disabling when SSH keys are present
hashedPassword = lib.mkIf (!config.users.enablePasswordAuth && config.users.sshKeys == []) 
  (lib.mkForce null);
```

### Security Configuration

#### Sudo Access
```nix
security.sudo.wheelNeedsPassword = true;
```
- Members of `wheel` group can use sudo
- Password required for sudo operations (security best practice)

## Usage Examples

### Basic Desktop User
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/users.nix
  ];
  
  # Configure for desktop environment
  users = {
    hostType = "desktop";
    sshKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIYourPublicKeyHere user@desktop"
    ];
    enablePasswordAuth = false;  # SSH keys only
  };
}
```

### Server User Configuration
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/users.nix
  ];
  
  # Configure for server (minimal groups)
  users = {
    hostType = "server";
    sshKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdminKeyHere admin@workstation"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBackupKeyHere admin@backup"
    ];
    enablePasswordAuth = false;
  };
}
```

### Development Setup
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/users.nix
  ];
  
  # Laptop with development access
  users = {
    hostType = "laptop";
    sshKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDeveloperKey user@laptop"
    ];
  };
  
  # Add development-specific groups
  users.users.${username}.extraGroups = [ "docker" "libvirtd" ];
}
```

### Initial Setup (Password Auth)
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/users.nix
  ];
  
  # Temporary setup for initial configuration
  users = {
    hostType = "desktop";
    enablePasswordAuth = true;  # Enable for initial setup
    sshKeys = [];  # Add SSH keys after initial login
  };
}
```

## Advanced Configuration

### Multiple SSH Keys
```nix
users.sshKeys = [
  # Main workstation key
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMainKey user@workstation"
  
  # Laptop key
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILaptopKey user@laptop"
  
  # Emergency access key
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEmergencyKey user@emergency"
  
  # Shared admin key (for team access)
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITeamKey admin@team"
];
```

### Custom Group Assignments
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/users.nix
  ];
  
  users.hostType = "desktop";
  
  # Add additional groups after module configuration
  users.users.${username}.extraGroups = [
    "kvm"          # Virtualization
    "input"        # Input device access
    "plugdev"      # Removable devices
    "scanner"      # Scanner access
    "lp"           # Printer access
  ];
}
```

### Restricted User (Server)
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/users.nix
  ];
  
  users = {
    hostType = "server";
    sshKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIServerKey user@server" ];
    enablePasswordAuth = false;
  };
  
  # Remove wheel access for restricted user
  users.users.${username}.extraGroups = lib.mkForce [ "networkmanager" ];
  
  # Create separate admin user
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdminKey admin@secure"
    ];
  };
}
```

## Security Best Practices

### SSH Key Management
1. **Use ED25519 keys:** More secure and performant than RSA
   ```bash
   ssh-keygen -t ed25519 -C "user@hostname"
   ```

2. **Separate keys per device:** Different keys for different machines
3. **Regular key rotation:** Replace keys periodically
4. **Emergency access:** Keep secure backup keys

### Password Security
1. **Disable password auth:** Use SSH keys exclusively for production
2. **Strong initial passwords:** Change immediately after setup
3. **No shared passwords:** Each user should have unique credentials

### Group Membership
1. **Principle of least privilege:** Only assign necessary groups
2. **Regular audits:** Review group memberships periodically
3. **Host-specific groups:** Tailor access to host function

## Integration with Other Modules

### With SSH (common.nix)
The users module works with SSH configuration in common.nix:
- SSH service enabled by default
- SSH keys properly configured for authentication
- Password authentication controlled by module options

### With Impermanence (impermanence.nix)
User data persistence is handled by the impermanence module:
- SSH keys persisted in `/persist/home/${username}/.ssh`
- User home directory structure maintained across reboots
- Proper permissions restored after ephemeral root reset

### With Desktop Modules
Desktop and laptop hosts receive additional group memberships:
- `video` group for graphics hardware
- `audio` group for sound hardware
- Additional groups may be added by specific hardware modules

## Troubleshooting

### SSH Access Issues
1. **Check SSH service:** `systemctl status sshd`
2. **Verify key format:** Ensure public keys are properly formatted
3. **Test key authentication:** Use `ssh -v` for verbose output
4. **Check permissions:** SSH directory permissions must be correct

### Group Membership Problems
1. **List user groups:** `groups ${username}`
2. **Check group existence:** `getent group groupname`
3. **Restart user session:** Log out and back in for group changes

### Password Authentication
1. **Check configuration:** Verify `enablePasswordAuth` setting
2. **Test locally:** Try local login if SSH fails
3. **Reset password:** Use recovery methods if locked out

### Sudo Access
1. **Verify wheel membership:** `groups ${username}`
2. **Test sudo:** `sudo -v` to verify access
3. **Check sudo logs:** `journalctl | grep sudo`

## Migration Notes

### From Password to SSH Keys
```nix
# Step 1: Add SSH keys while keeping password auth
users = {
  sshKeys = [ "your-new-ssh-key" ];
  enablePasswordAuth = true;
};

# Step 2: Test SSH access, then disable passwords
users.enablePasswordAuth = false;
```

### Adding New Keys
```nix
# Add new key to existing list
users.sshKeys = config.users.sshKeys ++ [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINewKey user@newdevice"
];
```

### Host Type Changes
When changing host types, group memberships update automatically on next rebuild. No manual intervention required for standard groups.