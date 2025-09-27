# PR Memory Context: WiFi Connectivity Issues Fix

## Problem Statement
- **Issue**: WiFi connectivity issues with repeated password prompts after every reboot
- **Root Cause**: NetworkManager using wpa_supplicant backend instead of modern IWD, combined with incomplete impermanence configuration
- **Impact**: Users had to re-enter WiFi passwords after each reboot due to credentials not persisting properly

## Solution Summary
Simplified NetworkManager configuration by switching to IWD backend and fixing impermanence persistence for WiFi credentials.

## Files Modified

### 1. `modules/nixos/wifi.nix`
**Key Changes:**
- Switched NetworkManager WiFi backend from `wpa_supplicant` to `iwd`
- Added IWD service configuration with proper settings:
  ```nix
  networking.wireless.iwd = {
    enable = true;
    settings = {
      General = {
        EnableNetworkConfiguration = false;  # Let NetworkManager handle this
      };
      Settings = {
        AutoConnect = true;
      };
    };
  };
  ```
- Explicitly disabled wpa_supplicant to prevent conflicts: `networking.wireless.enable = false;`
- Updated package list to include `iwd` instead of `wpa_supplicant` and `wpa_supplicant_gui`

### 2. `modules/nixos/impermanence.nix`
**Key Changes:**
- Added `/var/lib/iwd` to persistence directories list
- Updated activation script `setupNetworkManagerPersistence` to:
  - Create IWD persistence directory: `mkdir -p /persist/var/lib/iwd`
  - Set correct permissions: `chmod 700 /persist/var/lib/iwd` (more restrictive than NetworkManager)
  - Set ownership: `chown root:root /persist/var/lib/iwd`

### 3. `hosts/desktop/default.nix`
**Verification:**
- Confirmed WiFi module is properly imported via `common.nix`
- Existing WiFi configuration remains compatible:
  ```nix
  wifi = {
    enable = true;
    powerSaving = lib.mkForce "off";  # Desktop optimized
    enableFirmware = true;
    enableProprietaryFirmware = false;
  };
  ```

## Technical Details

### IWD vs wpa_supplicant
- **IWD**: Modern Intel WiFi daemon, better power management, more reliable
- **wpa_supplicant**: Legacy daemon, more resource intensive, connection stability issues
- **Migration**: Seamless switch via NetworkManager backend configuration

### Impermanence Configuration
- **NetworkManager**: Persists at `/etc/NetworkManager/system-connections` (755 permissions)
- **IWD**: Persists at `/var/lib/iwd` (700 permissions - more secure)
- **Activation Scripts**: Automatically create directories and set permissions on boot

### Architecture Integration
```
common.nix
├── imports wifi.nix
│   ├── NetworkManager with IWD backend
│   ├── IWD service configuration  
│   └── Package management
└── desktop.nix uses wifi options

impermanence.nix
├── Persists NetworkManager connections
├── Persists IWD state
└── Activation scripts for directory setup
```

## Expected Outcomes
1. **No more password prompts**: WiFi credentials persist across reboots
2. **Better connection stability**: IWD provides more reliable connections
3. **Improved power management**: IWD has better power saving algorithms
4. **Simplified troubleshooting**: Single backend reduces configuration complexity

## Testing Checklist
- [ ] System builds successfully with new configuration
- [ ] IWD service starts properly on boot
- [ ] NetworkManager recognizes WiFi networks
- [ ] WiFi connections persist after reboot
- [ ] No conflicts between IWD and wpa_supplicant
- [ ] Impermanence directories created with correct permissions

## Future Maintenance Notes
- IWD configuration files are stored in `/var/lib/iwd/`
- NetworkManager still manages connection profiles in `/etc/NetworkManager/system-connections/`
- If issues arise, can temporarily revert to wpa_supplicant by changing `backend = "wpa_supplicant"` in wifi.nix
- Monitor IWD logs: `journalctl -u iwd -f`
- Monitor NetworkManager logs: `journalctl -u NetworkManager -f`

## Related Documentation
- NixOS NetworkManager options: https://search.nixos.org/options?query=networking.networkmanager
- IWD documentation: https://wiki.archlinux.org/title/Iwd
- Impermanence module: https://github.com/nix-community/impermanence

## Commit Reference
- Initial fix: `Switch WiFi backend to IWD and fix impermanence configuration`
- Branch: `copilot/fix-3f695752-c420-407b-938e-1eff9cd03569`