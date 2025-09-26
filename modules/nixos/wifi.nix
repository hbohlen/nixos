# /modules/nixos/wifi.nix
# Comprehensive WiFi configuration module for NixOS
{ config, pkgs, lib, ... }:

{
  # Module options for WiFi configuration
  options = {
    wifi = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable WiFi support and configuration";
      };
      
      powerSaving = lib.mkOption {
        type = lib.types.enum [ "off" "low" "medium" "high" ];
        default = "medium";
        description = "WiFi power saving mode (off=0, low=1, medium=2, high=3)";
      };
      
      enableFirmware = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable redistributable firmware for WiFi adapters";
      };
    };
  };

  config = lib.mkIf config.wifi.enable {
    # Enable redistributable firmware for WiFi adapters
    hardware.enableRedistributableFirmware = lib.mkDefault config.wifi.enableFirmware;
    
    # Enable all firmware (includes proprietary WiFi firmware)
    hardware.enableAllFirmware = lib.mkDefault config.wifi.enableFirmware;

    # NetworkManager configuration with proper WiFi settings
    networking.networkmanager = {
      enable = true;
      
      # Configure WiFi power saving based on user preference
      wifi.powersave = lib.mkDefault (config.wifi.powerSaving != "off");
      
      # Additional WiFi configuration
      connectionConfig = {
        # Map power saving levels to NetworkManager values
        "wifi.powersave" = lib.mkDefault (
          if config.wifi.powerSaving == "off" then 0
          else if config.wifi.powerSaving == "low" then 1  
          else if config.wifi.powerSaving == "medium" then 2
          else 3  # high
        );
        
        # Improve connection stability
        "wifi.scan-rand-mac-address" = "no";  # Disable MAC randomization for better compatibility
        "wifi.backend" = "wpa_supplicant";    # Use wpa_supplicant backend for better compatibility
      };
      
      # Enable WiFi backend
      wifi.backend = "wpa_supplicant";
      
      # Ensure NetworkManager starts after wpa_supplicant is ready
      insertNameservers = [ "8.8.8.8" "8.8.4.4" ];
    };

    # Install essential WiFi packages
    environment.systemPackages = with pkgs; [
      # Core wireless tools
      wirelesstools      # iwconfig, iwlist, etc.
      wpa_supplicant     # WPA/WPA2 authentication
      wpa_supplicant_gui # GUI for wpa_supplicant
      iw                 # Modern wireless tools
      
      # Network management tools
      networkmanagerapplet  # NetworkManager GUI
      networkmanager-openvpn
      
      # Debugging and monitoring tools
      tcpdump           # Network packet capture
      wireshark-cli     # Network analysis
      iperf3            # Network performance testing
      
      # WiFi scanning and analysis
      wavemon           # WiFi monitoring
      linssid           # WiFi scanner GUI
      
      # WiFi diagnostics script
      (pkgs.writeShellScriptBin "wifi-diagnostics" (builtins.readFile ../../scripts/wifi-diagnostics.sh))
    ];

    # Enable WPA supplicant service
    networking.wireless.enable = lib.mkDefault false;  # Disable wpa_supplicant service (NetworkManager handles this)
    
    # Configure wpa_supplicant for NetworkManager
    networking.wpa_supplicant = {
      enable = false;  # Let NetworkManager handle wpa_supplicant
    };

    # Enable kernel modules for common WiFi adapters
    boot.kernelModules = [
      # Intel WiFi drivers
      "iwlwifi"         # Intel wireless driver
      "iwldvm"          # Intel DVM firmware interface
      "iwlmvm"          # Intel MVM firmware interface
      
      # Common WiFi infrastructure
      "cfg80211"        # WiFi configuration API
      "mac80211"        # WiFi MAC layer
      
      # Realtek drivers (common in USB WiFi adapters)
      "rtw88_core"      # Realtek WiFi core
      "rtw88_pci"       # Realtek PCIe interface
      "rtw88_usb"       # Realtek USB interface
      
      # Broadcom drivers
      "brcmfmac"        # Broadcom FullMAC driver
      "brcmutil"        # Broadcom utilities
    ];

    # Kernel parameters for better WiFi stability
    boot.kernelParams = [
      # Intel WiFi parameters
      "iwlwifi.power_save=0"        # Disable Intel WiFi power saving for stability
      "iwlwifi.uapsd_disable=1"     # Disable U-APSD for compatibility
      "iwlwifi.wd_disable=1"        # Disable watchdog for stability
      
      # General WiFi stability improvements
      "pci=nomsi"                   # Disable MSI for problematic hardware
      "pcie_aspm=off"               # Disable PCIe power management if causing issues
    ];

    # SystemD services for WiFi management
    systemd.services = {
      # WiFi interface setup service
      wifi-setup = {
        description = "WiFi Interface Setup";
        wantedBy = [ "network.target" ];
        before = [ "NetworkManager.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "wifi-setup" ''
            # Bring up wireless interfaces
            for interface in /sys/class/net/wl*; do
              if [ -d "$interface" ]; then
                interface_name=$(basename "$interface")
                echo "Setting up WiFi interface: $interface_name"
                ${pkgs.iproute2}/bin/ip link set "$interface_name" up || true
              fi
            done
          '';
        };
      };
      
      # WiFi diagnostics service (for troubleshooting)
      wifi-diagnostics = {
        description = "WiFi Diagnostics Service";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "wifi-diagnostics" ''
            echo "=== WiFi Diagnostics ===" > /var/log/wifi-diagnostics.log
            echo "Date: $(date)" >> /var/log/wifi-diagnostics.log
            echo "" >> /var/log/wifi-diagnostics.log
            
            echo "WiFi interfaces:" >> /var/log/wifi-diagnostics.log
            ${pkgs.iw}/bin/iw dev >> /var/log/wifi-diagnostics.log 2>&1 || true
            echo "" >> /var/log/wifi-diagnostics.log
            
            echo "PCI WiFi devices:" >> /var/log/wifi-diagnostics.log
            ${pkgs.pciutils}/bin/lspci | grep -i wireless >> /var/log/wifi-diagnostics.log 2>&1 || true
            ${pkgs.pciutils}/bin/lspci | grep -i network >> /var/log/wifi-diagnostics.log 2>&1 || true
            echo "" >> /var/log/wifi-diagnostics.log
            
            echo "Kernel modules:" >> /var/log/wifi-diagnostics.log
            ${pkgs.kmod}/bin/lsmod | grep -E "(iwl|cfg80211|mac80211|rtw|brcm)" >> /var/log/wifi-diagnostics.log 2>&1 || true
            echo "" >> /var/log/wifi-diagnostics.log
            
            echo "NetworkManager status:" >> /var/log/wifi-diagnostics.log
            ${pkgs.networkmanager}/bin/nmcli device status >> /var/log/wifi-diagnostics.log 2>&1 || true
          '';
        };
      };
    };

    # Tmpfiles rules for WiFi
    systemd.tmpfiles.rules = [
      "d /var/log 0755 root root -"
      "f /var/log/wifi-diagnostics.log 0644 root root -"
    ];

    # Environment variables for better WiFi debugging
    environment.variables = {
      # Enable NetworkManager debug logging
      NM_DEBUG = lib.mkDefault "0";  # Set to 1 for debugging
    };

    # Shell aliases for WiFi management
    environment.shellAliases = {
      wifi-scan = "nmcli device wifi list";
      wifi-connect = "nmcli device wifi connect";
      wifi-status = "nmcli device status";
      wifi-diag = "journalctl -u NetworkManager.service -f";
      wifi-restart = "sudo systemctl restart NetworkManager";
    };
  };
}