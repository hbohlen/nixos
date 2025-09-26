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

# Configuration variables - hardcoded for this installation
readonly HOSTNAME="desktop"
readonly DEFAULT_USERNAME="hbohlen"
readonly DEFAULT_DISK_DEVICE="/dev/nvme1n1"  # Your 2TB SSD (CT2000P310SSD8)
readonly REPO_URL="https://github.com/hbohlen/nixos"
readonly MOUNT_POINT="/mnt"

# Mutable globals populated during configuration
DISK_DEVICE="$DEFAULT_DISK_DEVICE"
USERNAME="$DEFAULT_USERNAME"

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
    read -r result </dev/tty
    echo "${result:-$default}"
}

# Function to confirm critical actions
confirm_action() {
    local prompt="$1"
    local response
    
    echo -ne "${YELLOW}$prompt${NC} [y/N]: "
    read -r response </dev/tty
    [[ "$response" =~ ^[Yy]$ ]]
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        handle_error "This script must be run as root. Please run: sudo -i"
    fi
    print_success "Running as root"
}

# Function to ensure TTY is available for interactive input
check_tty() {
    if [[ ! -t 0 ]]; then
        print_warning "No TTY detected for stdin. Attempting to redirect from /dev/tty"
        # This helps ensure interactive prompts work even when piped
        exec < /dev/tty
    fi
}

# Function to validate prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if we're in the correct directory
    if [[ ! -f "flake.nix" ]]; then
        handle_error "flake.nix not found. Please run this script from the repository root."
    fi
    
    # Check if hostname configuration exists
    if [[ ! -d "hosts/$HOSTNAME" ]]; then
        handle_error "Host configuration for '$HOSTNAME' not found in hosts/ directory"
    fi
    
    if [[ ! -f "hosts/$HOSTNAME/hardware/disko-layout.nix" ]]; then
        handle_error "Hardware configuration not found for '$HOSTNAME'"
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

# Function to collect user configuration
collect_configuration() {
    print_step "Collecting installation configuration..."
    
    # Get username (only prompt)
    USERNAME=$(prompt_user "Enter username" "$DEFAULT_USERNAME")

    # Determine target disk (no prompt by default)
    if [[ -n "${INSTALL_DISK_DEVICE:-}" ]]; then
        DISK_DEVICE="$INSTALL_DISK_DEVICE"
        print_status "Using disk from INSTALL_DISK_DEVICE='$DISK_DEVICE'"
    else
        DISK_DEVICE="$DEFAULT_DISK_DEVICE"
        print_status "Using default disk: $DISK_DEVICE"
    fi

    # Show available disks to help with validation/debugging
    print_status "Detected block devices:"
    lsblk -d -o NAME,SIZE,MODEL || handle_error "Failed to list block devices"
    
    # Show configuration for confirmation
    print_status "Installation configuration:"
    print_status "  Hostname: $HOSTNAME"
    print_status "  Username: $USERNAME"
    print_status "  Disk: $DISK_DEVICE"
    print_status "  Mount point: $MOUNT_POINT"
    echo
    
    # Show disk information
    print_status "Target disk information:"
    lsblk -d -o NAME,SIZE,MODEL "$DISK_DEVICE" || handle_error "Cannot access disk $DISK_DEVICE"

    # Confirm disk device exists, otherwise allow interactive selection as a fallback
    if [[ ! -b "$DISK_DEVICE" ]]; then
        print_warning "Default disk '$DISK_DEVICE' not found."
        local disk_prompt="Enter target disk (will be ERASED)"
        DISK_DEVICE=$(prompt_user "$disk_prompt" "$DEFAULT_DISK_DEVICE")
    fi

    if [[ ! -b "$DISK_DEVICE" ]]; then
        handle_error "Disk device '$DISK_DEVICE' does not exist"
    fi
    echo
    
    # Validate disk device exists
    if [[ ! -b "$DISK_DEVICE" ]]; then
        handle_error "Disk device '$DISK_DEVICE' does not exist"
    fi
    
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
    
    # Ensure we have a proper TTY for interactive input (LUKS password)
    print_status "Partitioning disk with disko for host: $HOSTNAME..."
    print_status "You will be prompted to enter the LUKS encryption password..."
    
    # Create a temporary script to run disko with proper TTY handling
    local disko_script="/tmp/run_disko.sh"
    cat > "$disko_script" << EOF
#!/usr/bin/env bash
# Ensure we have proper TTY access
exec < /dev/tty
exec > /dev/tty
exec 2> /dev/tty

# Inherit the current PATH and NIX_PATH
export PATH="$PATH"
export NIX_PATH="${NIX_PATH:-}"

# Source the Nix environment to ensure nix command is available
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Run disko with the arguments passed to this script
nix --experimental-features 'nix-command flakes' run github:nix-community/disko -- "\$@"
EOF
    chmod +x "$disko_script"
    
    # Verify the script was created successfully
    if [[ ! -x "$disko_script" ]]; then
        handle_error "Failed to create executable disko script at $disko_script"
    fi
    
    # Check if nix is available before running disko
    if ! command -v nix >/dev/null 2>&1; then
        print_warning "nix command not found in PATH: $PATH"
        # Try to source Nix environment
        if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
            print_status "Attempting to source Nix environment..."
            source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        fi
        
        # Check again
        if ! command -v nix >/dev/null 2>&1; then
            handle_error "nix command is not available. Please ensure you're running this from a NixOS live ISO or environment with Nix installed."
        fi
    fi
    
    # Run the disko script with our configuration
    print_status "Executing disko with the following parameters:"
    print_status "  Mode: destroy,format,mount"
    print_status "  Root mountpoint: $MOUNT_POINT"
    print_status "  Device: $DISK_DEVICE"
    print_status "  Config: ./hosts/$HOSTNAME/hardware/disko-layout.nix"
    
    "$disko_script" \
        --mode destroy,format,mount \
        --root-mountpoint "$MOUNT_POINT" \
        --yes-wipe-all-disks \
        --argstr device "$DISK_DEVICE" \
        ./hosts/"$HOSTNAME"/hardware/disko-layout.nix || \
        handle_error "Disko partitioning failed. Check the error messages above for details."
    
    # Clean up the temporary script
    rm -f "$disko_script"
    
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
    
    mkdir -p "$MOUNT_POINT" || handle_error "Failed to create directory $MOUNT_POINT"
    
    print_success "Mount directories created"
}

# Function to mount filesystems
mount_filesystems() {
    print_step "Mounting filesystems..."
    
    # Mount root dataset
    print_status "Mounting root dataset..."
    mount -t zfs rpool/local/root "$MOUNT_POINT" || \
        handle_error "Failed to mount root dataset"

    # Ensure additional mountpoints exist inside the target root
    local subdirectories=(
        "$MOUNT_POINT/boot"
        "$MOUNT_POINT/nix"
        "$MOUNT_POINT/persist"
        "$MOUNT_POINT/home"
    )
    for dir in "${subdirectories[@]}"; do
        mkdir -p "$dir" || handle_error "Failed to create directory $dir"
    done
    
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
    print_status "  • Hostname: $HOSTNAME"
    print_status "  • Username: $USERNAME"
    print_status "  • Disk: $DISK_DEVICE"
    print_status "  • ZFS with LUKS encryption"
    print_status "  • Impermanence (ephemeral root)"
    print_status "  • Persistent data in /persist"
    echo
    print_warning "Remember: The root filesystem is ephemeral!"
    print_warning "Only data in /persist and /home will survive reboots."
}

# Main installation function
main() {
    print_status "🚀 Starting NixOS installation for $HOSTNAME on $DISK_DEVICE"
    echo
    
    # Step 1: Preliminary checks
    check_tty
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
