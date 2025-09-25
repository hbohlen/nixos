# Home Manager Modules - User Environment Configuration

## Directory Purpose
This directory contains user-level Home Manager modules that configure desktop environments, applications, and user-specific settings that operate in user space without requiring root privileges. These modules manage the user's personal computing environment including desktop compositors, applications, dotfiles, and secret management.

## Module Overview and Configuration

### Desktop Environment Module (`desktop.nix`)

**Purpose**: Configures the user's desktop environment with Hyprland Wayland compositor, desktop applications, and user interface components.

#### Key Features

##### Hyprland Wayland Compositor
- **Modern Compositor**: Tiling Wayland compositor with advanced features
- **Custom Configuration**: Declarative window management and keybindings
- **Multi-monitor Support**: Advanced display management capabilities
- **Performance**: GPU-accelerated rendering and efficient resource usage

**Configuration Options**:
```nix
wayland.windowManager.hyprland = {
  enable = true;
  settings = {
    # Monitor configuration
    monitor = [ "DP-1,2560x1440@144,0x0,1" ];
    
    # Input configuration
    input = {
      kb_layout = "us";
      follow_mouse = 1;
      touchpad.natural_scroll = true;
    };
    
    # General settings
    general = {
      gaps_in = 5;
      gaps_out = 20;
      border_size = 2;
    };
  };
};
```

##### Desktop Applications and Tools
- **Terminal Emulators**: Alacritty, Kitty with custom configurations
- **Application Launchers**: Rofi/Wofi for application launching
- **System Bars**: Waybar for system status and workspace management
- **File Managers**: Nautilus, Thunar with integration
- **Media Players**: MPV, VLC with codec support

##### Theme and Appearance Management
- **GTK/Qt Themes**: Consistent theming across applications
- **Icon Themes**: Coordinated icon sets for desktop environments
- **Wallpaper Management**: Automatic wallpaper setting and rotation
- **Font Configuration**: User-specific font preferences and rendering

**Effects and Integration**:
- Seamless integration with system-level graphics configuration
- Proper authentication agent setup for GUI applications
- Screen sharing and recording capabilities
- Notification system integration

#### Troubleshooting Desktop Issues

##### Hyprland Problems
**Symptoms**: Compositor crashes, display issues, input problems
**Diagnosis**:
```bash
# Check Hyprland logs
journalctl --user -u hyprland
# Test Hyprland configuration
hyprctl reload
# Check graphics drivers
glxinfo | grep renderer
```
**Solutions**:
- Verify graphics driver compatibility
- Check Hyprland configuration syntax
- Update Hyprland and dependencies
- Test with minimal configuration

##### Display Configuration Issues
**Symptoms**: Wrong resolution, multi-monitor problems, scaling issues
**Diagnosis**:
```bash
# List available outputs
hyprctl monitors
# Check display information
wlr-randr
# Test display configuration
hyprctl keyword monitor "DP-1,2560x1440@144,0x0,1"
```
**Solutions**:
- Update monitor configuration in Hyprland settings
- Check cable connections and display capabilities
- Verify graphics driver support for displays
- Test with single monitor first

##### Application Integration Problems
**Symptoms**: Applications not starting, theme inconsistencies, missing features
**Diagnosis**:
```bash
# Check environment variables
env | grep -E "(WAYLAND|XDG|QT|GTK)"
# Test application startup
waybar --log-level debug
# Check theme settings
gsettings list-recursively | grep theme
```
**Solutions**:
- Verify XDG and Wayland environment variables
- Update theme configurations for consistency
- Check application Wayland compatibility
- Use compatibility layers (XWayland) if needed

### Secret Management Module (`opnix.nix`)

**Purpose**: Integrates 1Password CLI for secure secret management, SSH key handling, and credential storage without committing secrets to the repository.

#### Key Features

##### 1Password Integration
- **CLI Access**: 1Password CLI for command-line secret access
- **SSH Agent**: 1Password SSH agent for secure key management
- **Secret Injection**: Runtime secret injection into applications
- **Multi-vault Support**: Access to multiple 1Password vaults

**Configuration**:
```nix
programs.op = {
  enable = true;
  package = pkgs.op;
};

services.ssh-agent = {
  enable = false; # Use 1Password SSH agent instead
};
```

##### SSH Key Management
- **Centralized Keys**: SSH keys stored in 1Password
- **Automatic Loading**: SSH keys automatically available to SSH client
- **Key Security**: Keys never stored on disk unencrypted
- **Multi-key Support**: Multiple SSH keys for different purposes

##### Application Secret Integration
- **Environment Variables**: Secrets injected as environment variables
- **Configuration Files**: Secure configuration file generation
- **API Keys**: Secure API key management for development
- **Database Credentials**: Secure database connection management

#### Security Architecture

##### Secret Storage
- **Encrypted Vault**: All secrets encrypted in 1Password vault
- **Access Control**: Biometric and master password protection
- **No Disk Storage**: Secrets never written to persistent storage
- **Audit Trail**: Access logging and audit capabilities

##### Runtime Injection
- **On-demand Access**: Secrets retrieved only when needed
- **Temporary Exposure**: Minimal secret exposure time
- **Process Isolation**: Secrets isolated to specific processes
- **Cleanup**: Automatic secret cleanup on process termination

#### Troubleshooting Secret Management

##### 1Password CLI Issues
**Symptoms**: Authentication failures, CLI not working, secret access denied
**Diagnosis**:
```bash
# Check 1Password CLI status
op account list
op vault list
# Test authentication
op signin
# Check SSH agent
ssh-add -l
```
**Solutions**:
- Re-authenticate with `op signin`
- Verify account and vault permissions
- Check network connectivity to 1Password
- Update 1Password CLI version

##### SSH Agent Problems
**Symptoms**: SSH keys not available, authentication failures
**Diagnosis**:
```bash
# Check SSH agent status
echo $SSH_AUTH_SOCK
ssh-add -l
# Test SSH connection
ssh -vvv user@host
```
**Solutions**:
- Restart 1Password SSH agent
- Verify SSH key configuration in 1Password
- Check SSH client configuration
- Test with traditional SSH agent temporarily

## Dependencies and Integration

### External Dependencies
- **Hyprland**: Wayland compositor and ecosystem
- **1Password**: Secret management service and CLI
- **Graphics Drivers**: Mesa, NVIDIA drivers for display
- **Audio System**: PipeWire integration for desktop audio
- **Font Packages**: System and user fonts for rendering
- **Theme Packages**: GTK, Qt, and icon theme packages

### System Integration
- **Graphics Stack**: Integration with system-level graphics configuration
- **Authentication**: PAM integration for GUI authentication
- **Session Management**: Integration with display managers and session services
- **Hardware Access**: Camera, audio, input device access

### User Configuration Integration
- **Dotfiles Management**: Coordination with user dotfiles and preferences
- **Application Settings**: Integration with user application preferences
- **Shell Environment**: Coordination with shell and terminal configuration
- **Development Tools**: Integration with development environment setup

## Configuration Best Practices

### Desktop Environment
- **Performance**: Optimize compositor settings for hardware capabilities
- **Accessibility**: Configure accessibility features as needed
- **Productivity**: Set up efficient workflows and keybindings
- **Consistency**: Maintain consistent theming across applications
- **Resource Usage**: Monitor memory and CPU usage of desktop components

### Secret Management
- **Zero Trust**: Never store secrets in configuration files
- **Minimal Access**: Use least-privilege access to secrets
- **Audit**: Regular review of secret access and usage
- **Backup**: Ensure secret backup and recovery procedures
- **Rotation**: Regular rotation of long-lived secrets

### Application Management
- **Declarative Config**: Use Home Manager for application configuration
- **Version Pinning**: Pin application versions for stability
- **Testing**: Test application configurations before deployment
- **Documentation**: Document custom application configurations
- **User Preferences**: Make configurations customizable for different users

## Integration Notes

### Home Manager Configuration
- **Module Structure**: Follow Home Manager module patterns
- **Option Definitions**: Use proper option types and defaults
- **Service Management**: Use Home Manager services for user daemons
- **File Management**: Use Home Manager file management features
- **Package Management**: Coordinate with system-level package management

### Multi-User Considerations
- **User Isolation**: Ensure proper user environment isolation
- **Shared Resources**: Coordinate shared system resources
- **Permissions**: Proper file and directory permissions
- **Customization**: Allow per-user customization of shared modules
- **Conflict Resolution**: Handle conflicting user preferences

### Performance and Resource Management
- **Startup Time**: Optimize desktop environment startup
- **Memory Usage**: Monitor and optimize memory consumption
- **Graphics Performance**: Ensure optimal graphics performance
- **Power Management**: Consider power usage on battery devices
- **Network Usage**: Optimize network-dependent features

## Advanced Configuration

### Custom Hyprland Configurations
```nix
# Example advanced Hyprland configuration
wayland.windowManager.hyprland = {
  enable = true;
  settings = {
    # Performance optimizations
    misc = {
      vfr = true;
      vrr = 1;
    };
    
    # Advanced input handling
    input = {
      kb_layout = "us";
      kb_options = "caps:escape";
      repeat_rate = 50;
      repeat_delay = 300;
    };
    
    # Window management rules
    windowrulev2 = [
      "float,class:^(pavucontrol)$"
      "workspace 2,class:^(firefox)$"
      "workspace 3,class:^(code)$"
    ];
  };
};
```

### Secure Secret Usage
```nix
# Example secure secret injection
programs.git = {
  enable = true;
  extraConfig = {
    user = {
      # Use 1Password for Git credentials
      helper = "!${pkgs._1password}/bin/op get item 'Git Token' --fields password";
    };
  };
};
```

This comprehensive documentation provides detailed guidance for configuring and troubleshooting user-level Home Manager modules effectively.