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
    echo "1. Reset NetworkManager:"
    echo "   sudo systemctl restart NetworkManager"
    echo
    echo "2. Reload WiFi drivers:"
    echo "   sudo modprobe -r iwlwifi && sudo modprobe iwlwifi"
    echo
    echo "3. Delete and recreate WiFi connection:"
    echo "   nmcli connection delete 'WiFi-Name'"
    echo "   nmcli device wifi connect 'WiFi-Name' password 'password'"
    echo
    echo "4. Disable MAC address randomization:"
    echo "   nmcli connection modify 'WiFi-Name' wifi.mac-address-randomization no"
    echo
    echo "5. Disable power saving temporarily:"
    echo "   sudo iwconfig wlan0 power off"
    echo
    echo "6. Check NixOS WiFi configuration:"
    echo "   Ensure 'wifi.enable = true' and 'hardware.enableRedistributableFirmware = true'"
    echo
    
    success "WiFi diagnostics completed!"
    echo
    info "Log saved to: /tmp/wifi-diagnostics-\$(date +%Y%m%d-%H%M%S).log"
}

# Check if running as script or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Save output to log file
    LOG_FILE="/tmp/wifi-diagnostics-$(date +%Y%m%d-%H%M%S).log"
    main 2>&1 | tee "$LOG_FILE"
fi