# Development Workflows and Best Practices
# Context for ByteRover MCP - hbohlen/nixos

This document captures the practical workflows, troubleshooting approaches, and development practices specific to this NixOS configuration repository.

## Daily Development Workflow

### Standard Development Cycle
```bash
# 1. Start with clean state validation
cd /path/to/nixos
nix flake check                    # Validate flake syntax and inputs

# 2. Make configuration changes
# Edit files in modules/, hosts/, or users/

# 3. Format code (maintain consistency)
./scripts/format.sh

# 4. Test build (NEVER skip this step)
nixos-rebuild build --flake .#$(hostname)

# 5. Preview changes (optional but recommended)
nixos-rebuild dry-activate --flake .#$(hostname)

# 6. Deploy changes
./scripts/rebuild.sh switch

# 7. Monitor for issues
systemctl status
journalctl -f
```

### Quick Iteration Workflow (for small changes)
```bash
# For config tweaks and testing
./scripts/rebuild.sh test         # Temporary activation (no bootloader)
# Validate changes work
./scripts/rebuild.sh switch       # Make permanent if satisfied
```

## Adding New Functionality

### Adding a New Host
1. **Create host directory structure**:
   ```bash
   mkdir -p hosts/newhostname/hardware
   cp hosts/laptop/default.nix hosts/newhostname/
   cp hosts/laptop/hardware-configuration.nix hosts/newhostname/
   cp hosts/laptop/hardware/disko-zfs.nix hosts/newhostname/hardware/
   ```

2. **Update configuration files**:
   ```nix
   # hosts/newhostname/default.nix
   networking.hostName = "newhostname";  # Must match directory name
   networking.hostId = "12345678";       # Unique 8-char hex for ZFS
   users.hostType = "desktop";           # or "laptop" or "server"
   ```

3. **Add to flake.nix**:
   ```nix
   nixosConfigurations = {
     # ... existing hosts ...
     "newhostname" = mkSystem {
       hostname = "newhostname";
       username = "hbohlen";
     };
   };
   ```

4. **Test new host configuration**:
   ```bash
   nixos-rebuild build --flake .#newhostname
   ```

### Adding a New Module
1. **Create module file**:
   ```bash
   # For system module
   touch modules/nixos/newmodule.nix
   
   # For user module  
   touch modules/home-manager/newmodule.nix
   ```

2. **Standard module template**:
   ```nix
   { config, pkgs, lib, inputs, ... }:

   {
     options.newmodule = {
       enable = lib.mkEnableOption "newmodule description";
       
       option = lib.mkOption {
         type = lib.types.str;
         default = "defaultValue";
         description = "Option description for documentation";
       };
     };

     config = lib.mkIf config.newmodule.enable {
       # Module implementation
       environment.systemPackages = with pkgs; [
         # Package list
       ];
       
       # Service configuration
       services.someservice = {
         enable = true;
         # Configuration
       };
     };
   }
   ```

3. **Import in appropriate location**:
   ```nix
   # In host configuration or parent module
   imports = [
     ../../modules/nixos/newmodule.nix
   ];
   
   # Enable the module
   newmodule.enable = true;
   ```

## Troubleshooting Workflows

### Build Failures
1. **Syntax errors**:
   ```bash
   nix flake check                 # Identifies syntax issues
   # Fix syntax errors, then retry
   ```

2. **Dependency issues**:
   ```bash
   nix flake update               # Update all inputs
   nix flake lock --update-input nixpkgs  # Update specific input
   ```

3. **Package not found**:
   ```bash
   # Search for correct package name
   nix search nixpkgs packagename
   # Verify package exists in current channel
   nix-env -qaP | grep packagename
   ```

4. **Module evaluation errors**:
   ```bash
   # Get detailed error information
   nixos-rebuild build --flake .#hostname --show-trace
   ```

### Boot and System Issues

1. **System won't boot after changes**:
   ```bash
   # At boot menu, select previous generation
   # Or from recovery environment:
   nixos-rebuild switch --rollback
   ```

2. **ZFS mount issues**:
   ```bash
   # Check ZFS pool status
   zpool status
   zfs list
   
   # Import pool if needed
   zpool import -f rpool
   
   # Check for snapshot rollback
   zfs list -t snapshot | grep @blank
   ```

3. **Impermanence problems**:
   ```bash
   # Check persistent storage
   ls -la /persist/
   
   # Verify bind mounts
   mount | grep "/persist"
   
   # Check impermanence configuration
   systemctl status create-needed-for-boot-dirs.service
   ```

### Network Troubleshooting

1. **WiFi connection issues**:
   ```bash
   # Check NetworkManager status  
   systemctl status NetworkManager
   
   # List available networks
   nmcli dev wifi list
   
   # Connect to network
   nmcli dev wifi connect SSID password PASSWORD
   
   # Verify no wpa_supplicant conflicts
   systemctl status wpa_supplicant  # Should be inactive
   ```

2. **SSH connectivity**:
   ```bash
   # Check SSH service
   systemctl status sshd
   
   # Check host keys exist
   ls -la /etc/ssh/ssh_host_*
   
   # Regenerate host keys if needed  
   ssh-keygen -A
   ```

### GPU and Graphics Issues

1. **Nvidia driver problems**:
   ```bash
   # Check driver status
   nvidia-smi
   lspci | grep -i nvidia
   
   # Check Xorg logs
   journalctl -u display-manager
   
   # Verify driver module loaded
   lsmod | grep nvidia
   ```

2. **Hybrid graphics (laptop)**:
   ```bash
   # Check GPU switching
   prime-run glxinfo | grep "OpenGL renderer"
   
   # Monitor GPU usage
   nvidia-smi -l 1
   ```

## Performance Optimization

### Build Performance
```bash
# Parallel builds (add to configuration.nix)
nix.settings.max-jobs = "auto";         # Use all CPU cores
nix.settings.cores = 0;                 # Use all cores per job

# Build cache optimization
nix.settings.substituters = [
  "https://cache.nixos.org"
  "https://nix-community.cachix.org"
];
```

### System Performance Monitoring
```bash
# System resource monitoring
htop                    # CPU and memory usage
iotop                   # Disk I/O monitoring  
nethogs                 # Network usage by process

# ZFS performance monitoring
zpool iostat -v 1       # Pool I/O statistics
zfs get compression     # Check compression ratios
```

## Security Workflows

### SSH Key Management
```bash
# Generate new SSH key for host
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""

# Add user SSH key to 1Password (preferred)
# OR temporarily add to configuration for bootstrap:
# users.users.username.openssh.authorizedKeys.keys = [ "ssh-ed25519 ..." ];
```

### Secret Management Workflow
```bash
# Set up 1Password CLI (first time)
op signin

# Store development secrets
op item create --category="Secure Note" --title="dev-secrets" \
  credential[password]="secret-value"

# Access secrets in development
export API_KEY=$(op item get "dev-secrets" --field credential)
```

### System Hardening Checklist
- [ ] SSH keys configured, password auth disabled
- [ ] Full disk encryption (LUKS) enabled
- [ ] Firewall configured (`networking.firewall.enable = true`)
- [ ] Automatic updates configured (`system.autoUpgrade.enable = true`)
- [ ] No secrets in git repository (use Opnix/1Password)

## Backup and Recovery

### ZFS Snapshot Strategy
```bash
# Create manual snapshot before major changes
zfs snapshot rpool/nixos/root@$(date +%Y%m%d-%H%M%S)
zfs snapshot rpool/nixos/home@$(date +%Y%m%d-%H%M%S)
zfs snapshot rpool/nixos/persist@$(date +%Y%m%d-%H%M%S)

# List snapshots
zfs list -t snapshot

# Rollback to specific snapshot (emergency)
zfs rollback rpool/nixos/root@snapshot-name
```

### Configuration Backup
```bash
# Export current configuration
nixos-rebuild build --flake .#hostname
cp /run/current-system/configuration.nix /tmp/backup-config.nix

# Git-based backup (automatic via repository)
git add -A
git commit -m "Backup configuration - $(date)"
git push origin main
```

### Data Recovery Procedures
1. **Boot from NixOS ISO**
2. **Import ZFS pools**: `zpool import -f rpool`
3. **Mount filesystems**: `mount -t zfs rpool/nixos/root /mnt`
4. **Access persistent data**: `ls /mnt/persist/`
5. **Chroot and rebuild**: 
   ```bash
   nixos-enter --root /mnt
   nixos-rebuild switch --flake .#hostname
   ```

## Development Environment Setup

### Editor Configuration (VS Code)
```bash
# Install recommended extensions
code --install-extension jnoortheen.nix-ide
code --install-extension ms-vscode-remote.remote-ssh

# Configure Nix language server
echo '{"nix.enableLanguageServer": true}' > .vscode/settings.json
```

### Development Tools Installation
```nix
# Add to development.nix module
environment.systemPackages = with pkgs; [
  # Nix development
  nixpkgs-fmt              # Nix formatter
  nil                      # Nix LSP server
  nix-tree                 # Dependency visualization
  nix-diff                 # Compare configurations
  
  # General development
  git                      # Version control
  gh                       # GitHub CLI
  direnv                   # Environment management
  
  # System tools
  htop                     # System monitoring
  ncdu                     # Disk usage analysis
  tree                     # Directory visualization
];
```

This workflow guide provides the practical knowledge needed for day-to-day development and maintenance of the NixOS configuration system.