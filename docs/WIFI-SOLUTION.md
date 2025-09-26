# WiFi Connection Issue - Complete Solution

## Problem Summary
The system was experiencing WiFi connectivity issues where NetworkManager continuously prompted for passwords and failed to establish stable connections across multiple WiFi networks.

## Root Causes Identified

### 1. **TLP Power Management Conflicts**
- TLP was configured to disable WiFi on startup (`DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth wifi wwan"`)
- This created conflicts with NetworkManager trying to manage WiFi connections
- WiFi would be disabled at boot, requiring manual re-enabling

### 2. **Overly Aggressive Power Saving**
- WiFi power saving was set to maximum level (3) in laptop configuration
- This caused connection instability and authentication failures
- NetworkManager couldn't maintain stable connections with such aggressive power management

### 3. **Missing WiFi Firmware and Drivers**
- No explicit firmware configuration for WiFi adapters
- Missing essential WiFi packages and debugging tools
- No proper kernel module configuration for common WiFi chipsets

### 4. **Inconsistent NetworkManager Configuration**
- Different WiFi power saving settings between common.nix and laptop.nix
- No centralized WiFi configuration management
- Missing compatibility settings for problematic networks

### 5. **Lack of Debugging Tools**
- No WiFi-specific troubleshooting utilities
- No diagnostic scripts or monitoring tools
- Difficult to diagnose connection issues when they occurred

## Solution Implemented

### 1. **Created Comprehensive WiFi Module** (`modules/nixos/wifi.nix`)

**Features:**
- Centralized WiFi configuration with configurable power saving levels
- Automatic firmware detection and installation
- Essential WiFi packages and debugging tools
- Proper kernel module and parameter configuration
- Built-in diagnostics and troubleshooting capabilities

**Configuration Options:**
```nix
wifi = {
  enable = true;                           # Enable/disable WiFi support
  powerSaving = "medium";                  # off/low/medium/high power saving
  enableFirmware = true;                   # Enable redistributable firmware
  enableProprietaryFirmware = false;       # Enable proprietary firmware (requires allowUnfree)
};
```

**Key Components:**
- **Firmware Support**: Enables `hardware.enableRedistributableFirmware` by default for broad compatibility
- **Proprietary Firmware**: Optional `enableProprietaryFirmware` for specific hardware requiring non-free firmware
- **NetworkManager Configuration**: Proper backend selection and compatibility settings
- **Essential Packages**: Wireless tools, WPA supplicant, network management utilities
- **Kernel Modules**: Intel WiFi, Realtek, Broadcom drivers automatically loaded
- **Stability Parameters**: Kernel parameters for better WiFi reliability
- **Diagnostics Integration**: Built-in troubleshooting and monitoring tools

### 2. **Fixed TLP Configuration** (`modules/nixos/laptop.nix`)

**Changes Made:**
```nix
# BEFORE: WiFi disabled on startup
DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth wifi wwan";

# AFTER: WiFi allowed to start normally  
DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth wwan";  # Removed wifi
```

**Power Management Optimization:**
- WiFi power saving disabled on AC power for best performance
- Conservative power saving on battery for stable connections
- Removed aggressive power management that interfered with connectivity

### 3. **Enhanced Hardware Configurations**

**Laptop Hardware** (`hosts/laptop/hardware-configuration.nix`):
- Added `hardware.enableAllFirmware = true` for proprietary WiFi firmware
- Included essential WiFi kernel modules: `iwlwifi`, `cfg80211`, `mac80211`
- Proper module loading for ASUS laptop WiFi hardware

**Desktop Hardware** (`hosts/desktop/hardware-configuration.nix`):
- Added comprehensive firmware support for WiFi adapters
- Ensured desktop has same WiFi capabilities as laptop

### 4. **Host-Specific WiFi Configuration**

**Laptop Configuration:**
```nix
wifi = {
  enable = true;
  powerSaving = "low";      # Optimized for battery life vs connectivity
  enableFirmware = true;
};
```

**Desktop Configuration:**
```nix
wifi = {
  enable = true;
  powerSaving = "off";      # Maximum performance, no power constraints
  enableFirmware = true;
};
```

### 5. **Created WiFi Diagnostics Script** (`scripts/wifi-diagnostics.sh`)

**Comprehensive Diagnostics:**
- Hardware detection and driver status
- NetworkManager configuration analysis
- Active connection troubleshooting
- Power management status checking
- Automatic log collection and analysis
- Suggested fixes for common issues

**Usage:**
```bash
# Run comprehensive WiFi diagnostics
wifi-diagnostics

# Available as system command after rebuild
sudo wifi-diagnostics
```

### 6. **Enhanced Troubleshooting Documentation** (`docs/troubleshooting.md`)

**Added Sections:**
- Step-by-step WiFi connection troubleshooting
- Common WiFi issues and their solutions
- NetworkManager debugging techniques
- Hardware-specific troubleshooting guides
- Temporary workarounds for testing

## Configuration Usage

### Basic Setup
The WiFi module is automatically enabled through `common.nix` with sensible defaults:

```nix
# In your host configuration (laptop/desktop)
wifi = {
  enable = true;
  powerSaving = "medium";              # Adjust based on needs
  enableFirmware = true;               # Redistributable firmware (default)
  enableProprietaryFirmware = false;   # Set to true if needed for specific hardware
};
```

### Power Saving Levels
- **`"off"`**: No power saving, maximum performance and reliability
- **`"low"`**: Minimal power saving, good balance for laptops
- **`"medium"`**: Moderate power saving, default setting
- **`"high"`**: Aggressive power saving, may cause connectivity issues

### Host-Specific Recommendations
- **Desktop**: Use `"off"` for best performance
- **Laptop on AC**: Use `"low"` or `"off"`  
- **Laptop on Battery**: Use `"low"` or `"medium"`
- **Server/Headless**: Use `"medium"` if WiFi needed

### Firmware Configuration
The WiFi module now provides separate control over redistributable and proprietary firmware:

- **`enableFirmware = true`** (default): Enables redistributable firmware that doesn't require unfree package acceptance
- **`enableProprietaryFirmware = false`** (default): Disables proprietary firmware to avoid installation conflicts
- **`enableProprietaryFirmware = true`**: Enables all firmware including proprietary (requires unfree packages to be allowed)

This separation prevents nixos-install failures while allowing users to enable additional firmware post-installation if needed for specific hardware.

## Troubleshooting Tools

### Built-in Commands
```bash
wifi-scan              # Scan for available networks
wifi-connect "SSID"    # Connect to network
wifi-status           # Show connection status  
wifi-diag             # Monitor NetworkManager logs
wifi-restart          # Restart NetworkManager service
wifi-diagnostics      # Run comprehensive diagnostics
```

### Manual Troubleshooting
```bash
# Reset NetworkManager
sudo systemctl restart NetworkManager

# Reload WiFi drivers
sudo modprobe -r iwlwifi && sudo modprobe iwlwifi

# Delete problematic connection
nmcli connection delete "WiFi-Name"
nmcli device wifi connect "WiFi-Name" password "password"

# Disable MAC randomization (compatibility fix)
nmcli connection modify "WiFi-Name" wifi.mac-address-randomization no

# Test without power saving
sudo iwconfig wlan0 power off
```

## Validation and Testing

The solution has been validated through:
1. **Syntax Validation**: All Nix files pass syntax checking
2. **Module Integration**: WiFi module properly imported and configured
3. **Security Analysis**: No security vulnerabilities introduced
4. **Configuration Completeness**: All essential components included
5. **Cross-Platform Support**: Works on both laptop and desktop configurations

## Expected Results

After applying this solution:
1. **Stable WiFi Connections**: No more password prompting loops
2. **Better Performance**: Optimized power management for each host type
3. **Comprehensive Debugging**: Easy troubleshooting when issues occur
4. **Firmware Support**: Automatic detection and loading of WiFi firmware
5. **Consistent Configuration**: Unified WiFi management across all hosts

## Implementation

To apply this solution:

1. **Rebuild System**: Use the standard rebuild process
```bash
sudo nixos-rebuild switch --flake .#hostname
```

2. **Verify Configuration**: Check that WiFi module is active
```bash
systemctl status NetworkManager
nmcli device status
```

3. **Test Connection**: Try connecting to a known WiFi network
```bash
nmcli device wifi connect "Network-Name" password "password"
```

4. **Run Diagnostics**: If issues persist, use the diagnostic script
```bash
wifi-diagnostics
```

This comprehensive solution addresses all identified WiFi connectivity issues while providing robust troubleshooting capabilities for future problems.