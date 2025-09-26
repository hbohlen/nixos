#!/usr/bin/env bash
# WiFi Diagnostics Script for NixOS
# Comprehensive WiFi troubleshooting and information gathering

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

info() {
    echo -e "${CYAN}[INFO]${NC} $*"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to run command and capture output with error handling
run_cmd() {
    local cmd="$1"
    local description="$2"
    
    echo
    info "Running: $description"
    echo "Command: $cmd"
    echo "----------------------------------------"
    
    if eval "$cmd" 2>&1; then
        success "$description completed"
    else
        warning "$description failed or returned error"
    fi
}

# Main diagnostic function
main() {
    echo
    echo "=================================="
    echo "    WiFi Diagnostics for NixOS    "
    echo "=================================="
    echo
    
    # Basic system information
    info "System Information:"
    run_cmd "uname -a" "System kernel information"
    run_cmd "hostnamectl" "System hostname and OS info"
    
    # Network interfaces
    info "Network Interface Information:"
    run_cmd "ip link show" "Network interfaces"
    run_cmd "iwconfig" "Wireless interface configuration"
    run_cmd "iw dev" "Wireless device information"
    
    # Hardware detection
    info "Hardware Detection:"
    run_cmd "lspci | grep -i -E '(network|wireless)'" "PCI WiFi hardware"
    run_cmd "lsusb | grep -i wireless" "USB WiFi hardware"
    run_cmd "rfkill list" "WiFi/Bluetooth radio status"
    
    # Driver and firmware status
    info "Driver and Firmware Status:"
    run_cmd "lsmod | grep -E '(iwl|cfg80211|mac80211|rtw|brcm)'" "Loaded WiFi kernel modules"
    run_cmd "dmesg | grep -i -E '(firmware|iwl|wifi|wireless)' | tail -20" "Recent WiFi/firmware messages"
    
    # NetworkManager status
    if command_exists nmcli; then
        info "NetworkManager Information:"
        run_cmd "nmcli --version" "NetworkManager version"
        run_cmd "nmcli general status" "NetworkManager general status"
        run_cmd "nmcli device status" "Device status"
        run_cmd "nmcli connection show" "Network connections"
        run_cmd "nmcli device wifi list" "Available WiFi networks"
        
        # Check active connections
        if nmcli connection show --active | grep -q wifi; then
            info "Active WiFi connection details:"
            run_cmd "nmcli connection show --active" "Active connections"
        else
            warning "No active WiFi connections found"
        fi
    else
        error "NetworkManager (nmcli) not found"
    fi
    
    # WPA Supplicant status
    info "WPA Supplicant Status:"
    run_cmd "systemctl status wpa_supplicant || echo 'wpa_supplicant service not active'" "WPA Supplicant service status"
    
    # Power management status
    info "Power Management:"
    if ls /sys/class/net/wl* >/dev/null 2>&1; then
        for interface in /sys/class/net/wl*; do
            interface_name=$(basename "$interface")
            if [ -f "$interface/device/power_save" ]; then
                run_cmd "cat $interface/device/power_save" "$interface_name power save status"
            fi
        done
    else
        warning "No wireless interfaces found in /sys/class/net/"
    fi
    
    # DNS and connectivity
    info "DNS and Connectivity:"
    run_cmd "cat /etc/resolv.conf" "DNS configuration"
    run_cmd "ping -c 3 8.8.8.8 || echo 'Ping failed'" "Internet connectivity test"
    
    # Service logs
    info "Recent NetworkManager logs:"
    run_cmd "journalctl -u NetworkManager.service --since '5 minutes ago' --no-pager" "Recent NetworkManager logs"
    
    # Configuration files
    info "Configuration Files:"
    if [ -f /etc/NetworkManager/NetworkManager.conf ]; then
        run_cmd "cat /etc/NetworkManager/NetworkManager.conf" "NetworkManager configuration"
    else
        warning "NetworkManager configuration file not found"
    fi
    
    # Check for common issues
    echo
    info "Common Issue Checks:"
    
    # Check if WiFi is disabled by TLP
    if command_exists tlp-stat; then
        run_cmd "tlp-stat -s | grep -E '(wifi|WIFI)'" "TLP WiFi status"
    fi
    
    # Check for impermanence and persistence issues
    echo
    info "Impermanence and Persistence Checks:"
    
    # Check if system uses impermanence (ZFS root)
    if mount | grep -q "rpool/local/root"; then
        info "System uses impermanence (ephemeral root filesystem)"
        
        # Check if persist mount exists
        if mount | grep -q "/persist"; then
            success "/persist mount found"
            run_cmd "mount | grep persist" "Persistent filesystem mounts"
        else
            error "/persist mount not found - impermanence may not be working"
        fi
        
        # Check NetworkManager system-connections persistence
        if [ -d "/persist/etc/NetworkManager/system-connections" ]; then
            success "NetworkManager connections directory persisted at /persist/etc/NetworkManager/system-connections"
            run_cmd "ls -la /persist/etc/NetworkManager/system-connections/" "Persistent connection files"
            
            # Check bind mount
            if mount | grep -q "/etc/NetworkManager/system-connections"; then
                success "NetworkManager system-connections properly bind-mounted"
            else
                error "NetworkManager system-connections NOT bind-mounted from /persist"
            fi
        else
            error "NetworkManager connections directory NOT found in /persist"
            warning "This will cause WiFi passwords to be lost on reboot"
        fi
        
        # Check permissions on connection files
        if [ -d "/etc/NetworkManager/system-connections" ]; then
            echo
            info "Checking NetworkManager connection file permissions:"
            for conn_file in /etc/NetworkManager/system-connections/*; do
                if [ -f "$conn_file" ]; then
                    perms=$(stat -c "%a" "$conn_file" 2>/dev/null || echo "unknown")
                    owner=$(stat -c "%U:%G" "$conn_file" 2>/dev/null || echo "unknown")
                    if [ "$perms" = "600" ] && [ "$owner" = "root:root" ]; then
                        success "$(basename "$conn_file"): $perms $owner ✓"
                    else
                        error "$(basename "$conn_file"): $perms $owner ✗ (should be 600 root:root)"
                    fi
                fi
            done
        fi
    else
        info "System does not appear to use impermanence"
    fi
    
    # Check for MAC address randomization issues
    if command_exists nmcli; then
        echo
        warning "Checking for MAC address randomization (can cause connection issues):"
        nmcli connection show | while IFS= read -r line; do
            if echo "$line" | grep -q "wifi"; then
                conn_name=$(echo "$line" | awk '{print $1}')
                mac_rand=$(nmcli connection show "$conn_name" | grep "wifi.mac-address-randomization" || echo "not set")
                echo "Connection '$conn_name': $mac_rand"
            fi
        done
    fi
    
    # Suggested fixes
    echo
    echo "=========================================="
    echo "           SUGGESTED FIXES               "
    echo "=========================================="
    echo
    
    info "If experiencing connection issues, try these steps:"
    echo
    echo "=== IMPERMANENCE-SPECIFIC FIXES ==="
    echo "1. Fix NetworkManager persistence (if connections lost after reboot):"
    echo "   # Ensure persistence directory exists"
    echo "   sudo mkdir -p /persist/etc/NetworkManager/system-connections"
    echo "   sudo chown root:root /persist/etc/NetworkManager/system-connections"
    echo "   sudo chmod 755 /persist/etc/NetworkManager/system-connections"
    echo
    echo "2. Fix connection file permissions:"
    echo "   sudo chown root:root /etc/NetworkManager/system-connections/*"
    echo "   sudo chmod 600 /etc/NetworkManager/system-connections/*"
    echo
    echo "3. Manually copy existing connections to persist (if needed):"
    echo "   sudo cp -p /etc/NetworkManager/system-connections/* /persist/etc/NetworkManager/system-connections/"
    echo
    echo "=== GENERAL NETWORK FIXES ==="
    echo "4. Reset NetworkManager:"
    echo "   sudo systemctl restart NetworkManager"
    echo
    echo "5. Reload WiFi drivers:"
    echo "   sudo modprobe -r iwlwifi && sudo modprobe iwlwifi"
    echo
    echo "6. Delete and recreate WiFi connection:"
    echo "   nmcli connection delete 'WiFi-Name'"
    echo "   nmcli device wifi connect 'WiFi-Name' password 'password'"
    echo
    echo "7. Disable MAC address randomization:"
    echo "   nmcli connection modify 'WiFi-Name' wifi.mac-address-randomization no"
    echo
    echo "8. Disable power saving temporarily:"
    echo "   sudo iwconfig wlan0 power off"
    echo
    echo "9. Check NixOS WiFi configuration:"
    echo "   Ensure 'wifi.enable = true' and 'hardware.enableRedistributableFirmware = true'"
    echo
    echo "=== REBUILD SYSTEM ==="
    echo "10. After configuration changes, rebuild:"
    echo "    sudo nixos-rebuild switch --flake .#laptop"
    echo
    
    success "WiFi diagnostics completed!"
    echo
    info "Log saved to: /tmp/wifi-diagnostics-\$(date +%Y%m%d-%H%M%S).log"
    echo
    info "To run automated fixes, use: $0 --repair"
}

# Automatic repair functions
fix_impermanence_persistence() {
    info "Attempting to fix impermanence persistence issues..."
    
    # Check if we're running on an impermanence system
    if ! mount | grep -q "rpool/local/root"; then
        warning "System doesn't appear to use impermanence, skipping fixes"
        return 0
    fi
    
    # Ensure persist directory structure exists
    if [ ! -d "/persist/etc/NetworkManager" ]; then
        info "Creating /persist/etc/NetworkManager directory"
        sudo mkdir -p /persist/etc/NetworkManager/system-connections
        sudo chown root:root /persist/etc/NetworkManager
        sudo chmod 755 /persist/etc/NetworkManager
    fi
    
    if [ ! -d "/persist/etc/NetworkManager/system-connections" ]; then
        info "Creating /persist/etc/NetworkManager/system-connections directory"
        sudo mkdir -p /persist/etc/NetworkManager/system-connections
    fi
    
    # Set correct permissions
    sudo chown root:root /persist/etc/NetworkManager/system-connections
    sudo chmod 755 /persist/etc/NetworkManager/system-connections
    
    # Copy existing connections if they exist and aren't already persisted
    if [ -d "/etc/NetworkManager/system-connections" ]; then
        for conn_file in /etc/NetworkManager/system-connections/*; do
            if [ -f "$conn_file" ]; then
                base_name=$(basename "$conn_file")
                if [ ! -f "/persist/etc/NetworkManager/system-connections/$base_name" ]; then
                    info "Copying connection file: $base_name"
                    sudo cp "$conn_file" "/persist/etc/NetworkManager/system-connections/"
                fi
            fi
        done
    fi
    
    # Fix permissions on all connection files
    if [ -d "/persist/etc/NetworkManager/system-connections" ]; then
        info "Setting correct permissions on connection files"
        sudo chown root:root /persist/etc/NetworkManager/system-connections/* 2>/dev/null || true
        sudo chmod 600 /persist/etc/NetworkManager/system-connections/* 2>/dev/null || true
    fi
    
    success "Impermanence persistence fixes completed"
}

fix_mac_randomization() {
    info "Fixing MAC address randomization on WiFi connections..."
    
    if ! command_exists nmcli; then
        error "nmcli not available, cannot fix MAC randomization"
        return 1
    fi
    
    # Get all WiFi connections and disable MAC randomization
    nmcli connection show | grep wifi | while IFS= read -r line; do
        conn_name=$(echo "$line" | awk '{print $1}')
        info "Disabling MAC randomization for: $conn_name"
        nmcli connection modify "$conn_name" wifi.mac-address-randomization no || true
    done
    
    success "MAC address randomization fixes completed"
}

fix_permissions() {
    info "Fixing NetworkManager connection file permissions..."
    
    if [ -d "/etc/NetworkManager/system-connections" ]; then
        sudo chown root:root /etc/NetworkManager/system-connections/* 2>/dev/null || true
        sudo chmod 600 /etc/NetworkManager/system-connections/* 2>/dev/null || true
        success "Connection file permissions fixed"
    else
        warning "No NetworkManager system connections directory found"
    fi
    
    if [ -d "/persist/etc/NetworkManager/system-connections" ]; then
        sudo chown root:root /persist/etc/NetworkManager/system-connections/* 2>/dev/null || true
        sudo chmod 600 /persist/etc/NetworkManager/system-connections/* 2>/dev/null || true
        success "Persistent connection file permissions fixed"
    fi
}

# Interactive repair menu
repair_wifi() {
    echo
    echo "=========================================="
    echo "        WiFi REPAIR FUNCTIONS           "
    echo "=========================================="
    echo
    
    echo "Available repair options:"
    echo "1. Fix impermanence persistence issues"
    echo "2. Fix MAC address randomization"
    echo "3. Fix file permissions"
    echo "4. All fixes"
    echo "5. Restart NetworkManager"
    echo "q. Quit"
    echo
    
    read -p "Select repair option (1-5, q): " choice
    
    case $choice in
        1)
            fix_impermanence_persistence
            ;;
        2)
            fix_mac_randomization
            ;;
        3)
            fix_permissions
            ;;
        4)
            fix_impermanence_persistence
            fix_mac_randomization
            fix_permissions
            ;;
        5)
            info "Restarting NetworkManager..."
            sudo systemctl restart NetworkManager
            success "NetworkManager restarted"
            ;;
        q|Q)
            info "Exiting repair menu"
            return 0
            ;;
        *)
            error "Invalid option selected"
            ;;
    esac
    
    echo
    read -p "Run another repair? (y/n): " again
    if [[ $again =~ ^[Yy] ]]; then
        repair_wifi
    fi
}

# Check if running as script or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Handle command line arguments
    if [[ "$1" == "--repair" ]] || [[ "$1" == "-r" ]]; then
        repair_wifi
    elif [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "WiFi Diagnostics Script for NixOS"
        echo
        echo "Usage: $0 [options]"
        echo
        echo "Options:"
        echo "  --repair, -r    Run interactive repair menu"
        echo "  --help, -h      Show this help message"
        echo "  (no options)    Run full diagnostics"
        echo
        echo "Examples:"
        echo "  $0              # Run full diagnostics"
        echo "  $0 --repair     # Run repair menu"
        echo
    else
        # Save output to log file
        LOG_FILE="/tmp/wifi-diagnostics-$(date +%Y%m%d-%H%M%S).log"
        main 2>&1 | tee "$LOG_FILE"
    fi
fi