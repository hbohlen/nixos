#!/usr/bin/env bash
# /scripts/install.sh
# Comprehensive NixOS installation script for disko-ZFS-impermanence setup
#
# This script handles the complete installation process including:
# - Disko partitioning with ZFS+LUKS
# - ZFS pool setup and dataset creation
# - Impermanence configuration with persistent directories
# - Proper mounting of all filesystems
# - NixOS installation with host-specific configuration
#
# Usage:
#   1. Boot from NixOS live ISO
#   2. Run: sudo -i
#   3. Run: nix-shell -p git
#   4. Run: cd /tmp && git clone https://github.com/hbohlen/nixos
#   5. Run: cd nixos && ./scripts/install.sh

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Configuration variables - modify these as needed
readonly DEFAULT_HOSTNAME="desktop"
readonly DEFAULT_USERNAME="hbohlen"
readonly TARGET_DISK_SIZE="2T"  # Change this to match your target disk size
readonly REPO_URL="https://github.com/hbohlen/nixos"
readonly MOUNT_POINT="/mnt"

# Global variable for disk device
DISK_DEVICE=""

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Function to handle errors and cleanup
handle_error() {
    print_error "$1"
    print_status "Attempting cleanup..."
    cleanup_on_error
    exit 1
}

# Cleanup function for error scenarios
cleanup_on_error() {
    # Unmount everything if possible
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        print_status "Unmounting filesystems..."
        umount -R "$MOUNT_POINT" 2>/dev/null || true
    fi
    
    # Close LUKS container if open
    if [ -e "/dev/mapper/cryptroot" ]; then
        print_status "Closing LUKS container..."
        cryptsetup luksClose cryptroot 2>/dev/null || true
    fi
    
    # Export ZFS pool if imported
    if zpool list rpool 2>/dev/null >/dev/null; then
        print_status "Exporting ZFS pool..."
        zpool export rpool 2>/dev/null || true
    fi
}

# Function to prompt for user input with default
prompt_user() {
    local prompt="$1"
    local default="$2"
    local result
    
    echo -ne "${YELLOW}$prompt${NC} [${default}]: "
    read -r result
    echo "${result:-$default}"
}

# Function to confirm critical actions
confirm_action() {
    local prompt="$1"
    local response
    
    echo -ne "${YELLOW}$prompt${NC} [y/N]: "
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        handle_error "This script must be run as root. Please run: sudo -i"
    fi
    print_success "Running as root"
}

# Function to validate prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if we're in the correct directory
    if [[ ! -f "flake.nix" ]]; then
        handle_error "flake.nix not found. Please run this script from the repository root."
    fi
    
    # Check for required commands
    local required_commands=("git" "nixos-generate-config" "cryptsetup" "zpool" "zfs")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            handle_error "Required command '$cmd' not found. Please install it first."
        fi
    done
    
    print_success "All prerequisites satisfied"
}

# Function to install necessary tools
install_tools() {
    print_step "Installing necessary tools..."
    
    # Install tools in a nix-shell environment
    nix-shell -p git disko zfs cryptsetup --run "echo 'Tools available in environment'" || \
        handle_error "Failed to install necessary tools"
    
    print_success "Tools installed successfully"
}

# Function to find the target disk by size
find_target_disk() {
    print_step "Searching for ${TARGET_DISK_SIZE} disk..."
    
    # Get all disks with their sizes
    local disk_info
    disk_info=$(lsblk -d -o NAME,SIZE -b | grep -E "(nvme|sd)" | grep -v "^loop")
    
    # Convert target size to bytes for comparison
    local target_size_bytes
    case "$TARGET_DISK_SIZE" in
        *T) target_size_bytes=$(echo "${TARGET_DISK_SIZE%T} * 1024 * 1024 * 1024 * 1024" | bc) ;;
        *G) target_size_bytes=$(echo "${TARGET_DISK_SIZE%G} * 1024 * 1024 * 1024" | bc) ;;
        *M) target_size_bytes=$(echo "${TARGET_DISK_SIZE%M} * 1024 * 1024" | bc) ;;
        *K) target_size_bytes=$(echo "${TARGET_DISK_SIZE%K} * 1024" | bc) ;;
        *) target_size_bytes="$TARGET_DISK_SIZE" ;;
    esac
    
    print_status "Target size in bytes: $target_size_bytes"
    
    # Find disks that match the target size (with some tolerance)
    local tolerance=1073741824  # 1GB tolerance in bytes
    local candidate_disks=()
    
    while IFS= read -r line; do
        if [[ $line =~ ^([^[:space:]]+)[[:space:]]+([0-9]+) ]]; then
            local disk_name="/dev/${BASH_REMATCH[1]}"
            local disk_size="${BASH_REMATCH[2]}"
            
            print_status "Checking disk: $disk_name with size: $disk_size bytes"
            
            # Check if disk size is within tolerance of target
            local size_diff=$((disk_size - target_size_bytes))
            size_diff=${size_diff#-}  # Absolute value
            
            if [ "$size_diff" -le "$tolerance" ]; then
                candidate_disks+=("$disk_name:$disk_size")
                print_status "Found matching disk: $disk_name"
            fi
        fi
    done <<< "$disk_info"
    
    if [ ${#candidate_disks[@]} -eq 0 ]; then
        print_error "No disks matching ${TARGET_DISK_SIZE} found!"
        print_status "Available disks:"
        lsblk -d -o NAME,SIZE,MODEL | grep -E "(nvme|sd)" | grep -v "^loop" || true
        return 1
    fi
    
    # Format disk sizes for display
    print_status "Found ${#candidate_disks[@]} disk(s) matching ${TARGET_DISK_SIZE}:"
    
    local disk_options=()
    for i in "${!candidate_disks[@]}"; do
        local disk_info="${candidate_disks[i]}"
        local disk_path="${disk_info%%:*}"
        local disk_size_bytes="${disk_info#*:}"
        
        # Convert bytes to human readable format
        local disk_size_hr
        if [ "$disk_size_bytes" -ge $((1024 * 1024 * 1024 * 1024)) ]; then
            disk_size_hr=$(echo "scale=1; $disk_size_bytes / (1024^4)" | bc)"T"
        elif [ "$disk_size_bytes" -ge $((1024 * 1024 * 1024)) ]; then
            disk_size_hr=$(echo "scale=1; $disk_size_bytes / (1024^3)" | bc)"G"
        elif [ "$disk_size_bytes" -ge $((1024 * 1024)) ]; then
            disk_size_hr=$(echo "scale=1; $disk_size_bytes / (1024^2)" | bc)"M"
        else
            disk_size_hr=$(echo "scale=1; $disk_size_bytes / 1024" | bc)"K"
        fi
        
        # Get disk model if available
        local disk_model
        disk_model=$(lsblk -d -o MODEL "$disk_path" | tail -n 1 | xargs)
        
        disk_options+=("$disk_path")
        echo "  $((i+1)). $disk_path (${disk_size_hr}) - $disk_model"
    done
    
    # If only one candidate, use it
    if [ ${#candidate_disks[@]} -eq 1 ]; then
        DISK_DEVICE="${disk_options[0]}"
        print_success "Automatically selected: $DISK_DEVICE"
        return 0
    fi
    
    # If multiple candidates, ask user to choose
    local choice
    while true; do
        echo -ne "${YELLOW}Select disk (1-${#candidate_disks[@]}):${NC} "
        read -r choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#candidate_disks[@]}" ]; then
            DISK_DEVICE="${disk_options[$((choice-1))]}"
            print_success "Selected: $DISK_DEVICE"
            break
        else
            print_error "Invalid selection"
        fi
    done
    
    return 0
}

# Function to collect user configuration
collect_configuration() {
    print_step "Collecting installation configuration..."
    
    # Get hostname
    HOSTNAME=$(prompt_user "Enter hostname" "$DEFAULT_HOSTNAME")
    
    # Get username
    USERNAME=$(prompt_user "Enter username" "$DEFAULT_USERNAME")
    
    # Find the target disk
    print_status "Available disk devices:"
    lsblk -d -o NAME,SIZE,MODEL | grep -E "(nvme|sd)" | grep -v "^loop" || true
    echo
    
    if ! find_target_disk; then
        print_warning "Automatic detection failed. Please select disk manually."
        
        local available_disks=()
        while IFS= read -r line; do
            if [[ $line =~ ^([nvme|sd]+[a-z0-9]+) ]]; then
                available_disks+=("/dev/${BASH_REMATCH[1]}")
            fi
        done < <(lsblk -d -o NAME,SIZE,MODEL | grep -E "(nvme|sd)" | grep -v "^loop")
        
        if [ ${#available_disks[@]} -eq 0 ]; then
            handle_error "No suitable disk devices found"
        fi
        
        echo "Available disks:"
        for i in "${!available_disks[@]}"; do
            local disk_path="${available_disks[i]}"
            local disk_size
            disk_size=$(lsblk -d -o SIZE "$disk_path" | tail -n 1 | xargs)
            local disk_model
            disk_model=$(lsblk -d -o MODEL "$disk_path" | tail -n 1 | xargs)
            echo "  $((i+1)). $disk_path (${disk_size}) - $disk_model"
        done
        
        local choice
        while true; do
            echo -ne "${YELLOW}Select disk (1-${#available_disks[@]}):${NC} "
            read -r choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#available_disks[@]}" ]; then
                DISK_DEVICE="${available_disks[$((choice-1))]}"
                break
            else
                print_error "Invalid selection"
            fi
        done
    fi
    
    # Validate disk device exists
    if [[ ! -b "$DISK_DEVICE" ]]; then
        handle_error "Disk device '$DISK_DEVICE' does not exist"
    fi
    
    # Check if hostname configuration exists
    if [[ ! -d "hosts/$HOSTNAME" ]]; then
        handle_error "Host configuration for '$HOSTNAME' not found in hosts/ directory"
    fi
    
    print_success "Configuration collected:"
    print_status "  Hostname: $HOSTNAME"
    print_status "  Username: $USERNAME"
    print_status "  Disk: $DISK_DEVICE"
    print_status "  Mount point: $MOUNT_POINT"
    
    # Final confirmation
    if ! confirm_action "⚠️  WARNING: This will DESTROY all data on $DISK_DEVICE. Continue?"; then
        print_status "Installation cancelled by user"
        exit 0
    fi
}

# Function to run disko partitioning
run_disko() {
    print_step "Running disko to partition the disk..."
    
    # Enable experimental features for this session
    export NIX_CONFIG="experimental-features = nix-command flakes"
    
    # Run disko with the host-specific configuration using the flake's disko configuration
    print_status "Partitioning disk with disko for host: $HOSTNAME..."
    nix --experimental-features 'nix-command flakes' run github:nix-community/disko -- \
        --mode zap_create_mount \
        --disk main "$DISK_DEVICE" \
        ./hosts/"$HOSTNAME"/hardware/disko-layout.nix || \
        handle_error "Disko partitioning failed"
    
    print_success "Disko partitioning completed successfully"
}

# Function to setup LUKS encryption
setup_luks() {
    print_step "Setting up LUKS encryption..."
    
    # Wait for partition to be available
    sleep 2
    
    # Check if LUKS partition exists
    local luks_partition="${DISK_DEVICE}p3"  # Assuming GPT partitioning
    if [[ ! -b "$luks_partition" ]]; then
        # Try alternative naming scheme
        luks_partition="${DISK_DEVICE}3"
    fi
    
    if [[ ! -b "$luks_partition" ]]; then
        handle_error "LUKS partition not found. Expected $luks_partition"
    fi
    
    # Open LUKS container (it should already be formatted by disko)
    print_status "Opening LUKS container..."
    if [[ ! -e "/dev/mapper/cryptroot" ]]; then
        # If not already opened, try to open it
        # Note: This assumes disko already formatted it
        cryptsetup luksOpen "$luks_partition" cryptroot || \
            handle_error "Failed to open LUKS container"
    fi
    
    print_success "LUKS container opened successfully"
}

# Function to setup ZFS pool and datasets
setup_zfs() {
    print_step "Setting up ZFS pool and datasets..."
    
    # Import ZFS pool if not already imported
    if ! zpool list rpool >/dev/null 2>&1; then
        print_status "Importing ZFS pool..."
        zpool import -f rpool || handle_error "Failed to import ZFS pool"
    fi
    
    # Verify datasets exist
    local datasets=("rpool/local/root" "rpool/local/nix" "rpool/safe/persist" "rpool/safe/home")
    for dataset in "${datasets[@]}"; do
        if ! zfs list "$dataset" >/dev/null 2>&1; then
            handle_error "Dataset '$dataset' not found"
        fi
    done
    
    # Create blank snapshot if it doesn't exist
    if ! zfs list -t snapshot rpool/local/root@blank >/dev/null 2>&1; then
        print_status "Creating blank snapshot..."
        zfs snapshot rpool/local/root@blank || handle_error "Failed to create blank snapshot"
    fi
    
    print_success "ZFS pool and datasets ready"
}

# Function to create mount directories
create_mount_directories() {
    print_step "Creating mount directories..."
    
    local directories=("$MOUNT_POINT" "$MOUNT_POINT/boot" "$MOUNT_POINT/nix" 
                      "$MOUNT_POINT/persist" "$MOUNT_POINT/home")
    
    for dir in "${directories[@]}"; do
        mkdir -p "$dir" || handle_error "Failed to create directory $dir"
    done
    
    print_success "Mount directories created"
}

# Function to mount filesystems
mount_filesystems() {
    print_step "Mounting filesystems..."
    
    # Mount root dataset
    print_status "Mounting root dataset..."
    mount -t zfs rpool/local/root "$MOUNT_POINT" || \
        handle_error "Failed to mount root dataset"
    
    # Mount nix dataset
    print_status "Mounting nix dataset..."
    mount -t zfs rpool/local/nix "$MOUNT_POINT/nix" || \
        handle_error "Failed to mount nix dataset"
    
    # Mount persist dataset
    print_status "Mounting persist dataset..."
    mount -t zfs rpool/safe/persist "$MOUNT_POINT/persist" || \
        handle_error "Failed to mount persist dataset"
    
    # Mount home dataset
    print_status "Mounting home dataset..."
    mount -t zfs rpool/safe/home "$MOUNT_POINT/home" || \
        handle_error "Failed to mount home dataset"
    
    # Mount boot partition
    print_status "Mounting boot partition..."
    # Look for the boot partition
    local boot_partition
    boot_partition=$(find /dev/disk/by-partlabel/ -name "*ESP*" -o -name "*EFI*" 2>/dev/null | head -1)
    if [[ -z "$boot_partition" ]]; then
        boot_partition="${DISK_DEVICE}p1"  # Fallback
        if [[ ! -b "$boot_partition" ]]; then
            boot_partition="${DISK_DEVICE}1"  # Alternative naming
        fi
    fi
    
    mount "$boot_partition" "$MOUNT_POINT/boot" || \
        handle_error "Failed to mount boot partition"
    
    print_success "All filesystems mounted successfully"
}

# Function to verify mounts
verify_mounts() {
    print_step "Verifying mount points..."
    
    local mount_points=("$MOUNT_POINT" "$MOUNT_POINT/boot" "$MOUNT_POINT/nix" 
                        "$MOUNT_POINT/persist" "$MOUNT_POINT/home")
    
    for mount_point in "${mount_points[@]}"; do
        if ! mountpoint -q "$mount_point"; then
            handle_error "$mount_point is not mounted"
        fi
        print_success "$mount_point is mounted"
    done
    
    print_success "All mount points verified"
}

# Function to create persistent directories
create_persistent_directories() {
    print_step "Creating persistent directories..."
    
    # System-level persistent directories
    local system_dirs=(
        "$MOUNT_POINT/persist/etc"
        "$MOUNT_POINT/persist/var/log"
        "$MOUNT_POINT/persist/var/lib"
        "$MOUNT_POINT/persist/var/lib/nixos"
        "$MOUNT_POINT/persist/var/lib/systemd"
        "$MOUNT_POINT/persist/root"
    )
    
    for dir in "${system_dirs[@]}"; do
        mkdir -p "$dir" || handle_error "Failed to create directory $dir"
    done
    
    # User-level persistent directories
    local user_dirs=(
        "$MOUNT_POINT/persist/home/$USERNAME"
        "$MOUNT_POINT/persist/home/$USERNAME/.ssh"
        "$MOUNT_POINT/persist/home/$USERNAME/.config"
        "$MOUNT_POINT/persist/home/$USERNAME/.local"
        "$MOUNT_POINT/persist/home/$USERNAME/Development"
    )
    
    for dir in "${user_dirs[@]}"; do
        mkdir -p "$dir" || handle_error "Failed to create directory $dir"
    done
    
    print_success "Persistent directories created"
}

# Function to generate hardware configuration
generate_hardware_config() {
    print_step "Generating hardware configuration..."
    
    nixos-generate-config --root "$MOUNT_POINT" || \
        handle_error "Failed to generate hardware configuration"
    
    print_success "Hardware configuration generated"
}

# Function to copy configuration
copy_configuration() {
    print_step "Copying NixOS configuration..."
    
    # Copy the entire configuration to persistent storage
    cp -r . "$MOUNT_POINT/persist/etc/nixos" || \
        handle_error "Failed to copy configuration to persistent storage"
    
    # Create symlink in target system
    ln -sf "/persist/etc/nixos" "$MOUNT_POINT/etc/nixos" || \
        handle_error "Failed to create nixos configuration symlink"
    
    print_success "Configuration copied successfully"
}

# Function to install NixOS
install_nixos() {
    print_step "Installing NixOS..."
    
    # Set NIX_CONFIG for the installation
    export NIX_CONFIG="experimental-features = nix-command flakes"
    
    # Install NixOS with the specific host configuration
    nixos-install --root "$MOUNT_POINT" --flake ".#$HOSTNAME" --no-root-passwd || \
        handle_error "NixOS installation failed"
    
    print_success "NixOS installation completed successfully"
}

# Function to perform cleanup
cleanup_installation() {
    print_step "Performing post-installation cleanup..."
    
    # Unmount all filesystems
    print_status "Unmounting filesystems..."
    umount -R "$MOUNT_POINT" || print_warning "Some filesystems may still be mounted"
    
    # Close LUKS container
    print_status "Closing LUKS container..."
    cryptsetup luksClose cryptroot || print_warning "LUKS container may still be open"
    
    # Export ZFS pool
    print_status "Exporting ZFS pool..."
    zpool export rpool || print_warning "ZFS pool may still be imported"
    
    print_success "Post-installation cleanup completed"
}

# Function to display final instructions
display_final_instructions() {
    print_success "🎉 NixOS installation completed successfully!"
    echo
    print_status "Final steps:"
    print_status "1. Remove the installation media"
    print_status "2. Reboot the system: reboot"
    print_status "3. On first boot, you may need to enter the LUKS passphrase"
    print_status "4. Log in with your user account: $USERNAME"
    print_status "5. Consider changing the initial password: passwd"
    echo
    print_status "The system is configured with:"
    print_status "  • ZFS with LUKS encryption"
    print_status "  • Impermanence (ephemeral root)"
    print_status "  • Persistent data in /persist"
    print_status "  • Host configuration: $HOSTNAME"
    echo
    print_warning "Remember: The root filesystem is ephemeral!"
    print_warning "Only data in /persist and /home will survive reboots."
}

# Main installation function
main() {
    print_status "🚀 Starting NixOS installation with disko-ZFS-impermanence setup"
    echo
    
    # Step 1: Preliminary checks
    check_root
    check_prerequisites
    
    # Step 2: Collect configuration
    collect_configuration
    
    # Step 3: Install tools
    install_tools
    
    # Step 4: Disk setup
    run_disko
    setup_luks
    setup_zfs
    
    # Step 5: Mount filesystems
    create_mount_directories
    mount_filesystems
    verify_mounts
    
    # Step 6: Prepare persistent directories
    create_persistent_directories
    
    # Step 7: Generate and copy configuration
    generate_hardware_config
    copy_configuration
    
    # Step 8: Install NixOS
    install_nixos
    
    # Step 9: Cleanup and finish
    cleanup_installation
    display_final_instructions
}

# Error handling for the entire script
trap 'handle_error "An unexpected error occurred on line $LINENO"' ERR

# Run main function
main "$@"
