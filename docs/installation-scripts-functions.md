# Installation Scripts Function Reference

This document provides detailed documentation for all functions in the bootstrap.sh and install.sh scripts.

## Bootstrap.sh Functions

### Output Functions

#### `print_status(message)`
- **Purpose**: Display informational messages with blue color coding
- **Parameters**: `message` - The status message to display
- **Usage**: `print_status "Starting installation..."`

#### `print_success(message)`
- **Purpose**: Display success messages with green color coding
- **Parameters**: `message` - The success message to display
- **Usage**: `print_success "Installation completed"`

#### `print_error(message)`
- **Purpose**: Display error messages with red color coding  
- **Parameters**: `message` - The error message to display
- **Usage**: `print_error "Failed to install git"`

## Install.sh Functions

### Configuration and Global Variables

```bash
# Read-only configuration
readonly HOSTNAME="desktop"
readonly DEFAULT_USERNAME="hbohlen"
readonly DEFAULT_DISK_DEVICE="/dev/nvme0n1"
readonly REPO_URL="https://github.com/hbohlen/nixos"
readonly MOUNT_POINT="/mnt"

# Mutable globals (populated during configuration)
DISK_DEVICE="$DEFAULT_DISK_DEVICE"
USERNAME="$DEFAULT_USERNAME"
```

### Output and User Interface Functions

#### `print_status(message)`
- **Purpose**: Display informational messages with blue [INFO] prefix
- **Color**: Blue text
- **Example**: `[INFO] Installing tools...`

#### `print_success(message)`
- **Purpose**: Display success messages with green [SUCCESS] prefix
- **Color**: Green text
- **Example**: `[SUCCESS] Installation completed`

#### `print_warning(message)`
- **Purpose**: Display warning messages with yellow [WARNING] prefix
- **Color**: Yellow text
- **Example**: `[WARNING] Disk will be erased`

#### `print_error(message)`
- **Purpose**: Display error messages with red [ERROR] prefix
- **Color**: Red text
- **Example**: `[ERROR] Failed to mount filesystem`

#### `print_step(message)`
- **Purpose**: Display major step indicators with cyan [STEP] prefix
- **Color**: Cyan text
- **Example**: `[STEP] Setting up ZFS pool...`

#### `prompt_user(prompt, default)`
- **Purpose**: Interactive user input with default value
- **Parameters**: 
  - `prompt` - Question to ask user
  - `default` - Default value if user presses enter
- **Returns**: User input or default value
- **TTY Handling**: Reads from `/dev/tty` for proper interactive behavior

#### `confirm_action(prompt)`
- **Purpose**: Yes/No confirmation dialog
- **Parameters**: `prompt` - Confirmation question
- **Returns**: Success (0) if user confirms with Y/y, failure (1) otherwise
- **Example**: `confirm_action "Delete all data?"`

### Validation and Prerequisites Functions

#### `check_root()`
- **Purpose**: Verify script is running with root privileges
- **Behavior**: Exits with error if not root (`$EUID -ne 0`)
- **Error Handling**: Calls `handle_error` if not root

#### `check_tty()`
- **Purpose**: Ensure TTY is available for interactive input
- **Behavior**: Redirects stdin to `/dev/tty` if not available
- **Important**: Required for interactive prompts when script is piped

#### `check_prerequisites()`
- **Purpose**: Comprehensive environment validation
- **Validations**:
  - Verifies `flake.nix` exists (correct directory)
  - Checks host configuration directory exists (`hosts/$HOSTNAME`)
  - Validates disko configuration file exists
  - Verifies required commands are available
- **Required Commands**: git, nixos-generate-config, cryptsetup, zpool, zfs

#### `install_tools()`
- **Purpose**: Install required tools via nix-shell
- **Tools Installed**: git, disko, zfs, cryptsetup
- **Method**: `nix-shell -p git disko zfs cryptsetup --run "..."`
- **Error Handling**: Exits on failure to install tools

### Configuration Collection Functions

#### `collect_configuration()`
- **Purpose**: Gather installation parameters from user and environment
- **Process**:
  1. Prompt for username (with default)
  2. Determine target disk device (environment variable or default)
  3. Display detected block devices for reference
  4. Show final configuration summary
  5. Validate disk device exists
  6. Get user confirmation for destructive operation
- **Environment Variables**: Reads `INSTALL_DISK_DEVICE` if set
- **Safety**: Requires explicit user confirmation before proceeding

### Error Handling and Cleanup Functions

#### `handle_error(message)`
- **Purpose**: Central error handler with automatic cleanup
- **Process**:
  1. Display error message
  2. Attempt cleanup via `cleanup_on_error()`
  3. Exit with status 1
- **Usage**: Called automatically by error trap or manually

#### `cleanup_on_error()`
- **Purpose**: Comprehensive resource cleanup on failure
- **Cleanup Operations**:
  - Unmount all filesystems under `$MOUNT_POINT`
  - Close LUKS container (`/dev/mapper/cryptroot`)
  - Export ZFS pool (`rpool`)
- **Safety**: Uses `|| true` to prevent cleanup failures from causing additional errors

### Disk Setup Functions

#### `run_disko()`
- **Purpose**: Execute disko partitioning with ZFS and LUKS
- **Process**:
  1. Enable Nix experimental features
  2. Create temporary disko execution script with TTY handling
  3. Verify nix command availability
  4. Execute disko with parameters:
     - Mode: destroy,format,mount
     - Root mountpoint: `/mnt`
     - Device: User-specified disk
     - Config: Host-specific disko layout
  5. Clean up temporary script
- **Configuration**: Uses `./hosts/$HOSTNAME/hardware/disko-layout.nix`
- **TTY Handling**: Creates wrapper script to ensure proper interactive input

#### `setup_luks()`
- **Purpose**: Verify and open LUKS encryption container
- **Process**:
  1. Wait for partition to be available (sleep 2)
  2. Detect LUKS partition (tries multiple naming schemes)
  3. Open LUKS container if not already open
- **Partition Detection**: Tries `${DISK_DEVICE}p3` then `${DISK_DEVICE}3`
- **Container Name**: Opens as `cryptroot`

#### `setup_zfs()`
- **Purpose**: Import ZFS pool and verify dataset structure
- **Process**:
  1. Import ZFS pool (`rpool`) if not already imported
  2. Verify all required datasets exist
  3. Create blank snapshot for impermanence if missing
- **Required Datasets**:
  - `rpool/local/root` (ephemeral root)
  - `rpool/local/nix` (nix store)
  - `rpool/safe/persist` (persistent data)
  - `rpool/safe/home` (user homes)
- **Snapshot**: Creates `rpool/local/root@blank` for rollback

### Filesystem Management Functions

#### `create_mount_directories()`
- **Purpose**: Create base mount point directory
- **Operation**: `mkdir -p "$MOUNT_POINT"` (creates `/mnt`)

#### `mount_filesystems()`
- **Purpose**: Mount all ZFS datasets and boot partition
- **Mount Order**:
  1. Root dataset (`rpool/local/root` → `/mnt`)
  2. Create subdirectories (`/mnt/boot`, `/mnt/nix`, `/mnt/persist`, `/mnt/home`)
  3. Nix dataset (`rpool/local/nix` → `/mnt/nix`)
  4. Persist dataset (`rpool/safe/persist` → `/mnt/persist`)
  5. Home dataset (`rpool/safe/home` → `/mnt/home`)
  6. Boot partition (ESP → `/mnt/boot`)
- **Boot Partition Detection**: 
  - First tries partition labels (`/dev/disk/by-partlabel/*ESP*`)
  - Falls back to `${DISK_DEVICE}p1` or `${DISK_DEVICE}1`

#### `verify_mounts()`
- **Purpose**: Validate all required filesystems are mounted
- **Verification Points**: `/mnt`, `/mnt/boot`, `/mnt/nix`, `/mnt/persist`, `/mnt/home`
- **Method**: Uses `mountpoint -q` to check each mount

### Installation Functions

#### `create_persistent_directories()`
- **Purpose**: Create directory structure for impermanence
- **System Directories**:
  - `/persist/etc` - System configuration
  - `/persist/var/log` - System logs
  - `/persist/var/lib` - System state
  - `/persist/var/lib/nixos` - NixOS state
  - `/persist/var/lib/systemd` - systemd state
  - `/persist/root` - Root user home
- **User Directories**:
  - `/persist/home/$USERNAME` - User home base
  - `/persist/home/$USERNAME/.ssh` - SSH keys
  - `/persist/home/$USERNAME/.config` - User config
  - `/persist/home/$USERNAME/.local` - Local app data
  - `/persist/home/$USERNAME/Development` - Dev files

#### `generate_hardware_config()`
- **Purpose**: Generate NixOS hardware configuration
- **Command**: `nixos-generate-config --root "$MOUNT_POINT"`
- **Output**: Creates hardware configuration in mounted system

#### `copy_configuration()`
- **Purpose**: Copy NixOS configuration to persistent storage
- **Process**:
  1. Copy entire repository to `/persist/etc/nixos`
  2. Create symlink from `/etc/nixos` to persistent location
- **Persistence**: Ensures configuration survives reboots

#### `install_nixos()`
- **Purpose**: Execute NixOS installation with flake configuration
- **Command**: `nixos-install --root "$MOUNT_POINT" --flake ".#$HOSTNAME" --no-root-passwd`
- **Features**: Uses flake-based configuration, skips root password setup

### Finalization Functions

#### `cleanup_installation()`
- **Purpose**: Clean up resources after successful installation
- **Operations**:
  1. Unmount all filesystems (`umount -R "$MOUNT_POINT"`)
  2. Close LUKS container (`cryptsetup luksClose cryptroot`)
  3. Export ZFS pool (`zpool export rpool`)
- **Error Handling**: Uses warnings instead of errors for cleanup failures

#### `display_final_instructions()`
- **Purpose**: Show post-installation instructions and system summary
- **Information Displayed**:
  - Next steps (remove media, reboot)
  - System configuration summary
  - Important reminders about impermanence
  - First-boot instructions

### Main Function

#### `main()`
- **Purpose**: Orchestrate the complete installation process
- **Execution Flow**:
  1. **Preliminary checks**: TTY, root privileges, prerequisites
  2. **Configuration**: Collect user input and validate settings
  3. **Tool installation**: Install required packages
  4. **Disk setup**: Partition, encrypt, create ZFS pool
  5. **Filesystem mounting**: Mount all datasets and verify
  6. **Preparation**: Create persistent directories
  7. **Configuration**: Generate hardware config and copy files
  8. **Installation**: Install NixOS with flake configuration
  9. **Finalization**: Cleanup and display instructions

### Error Trap

```bash
trap 'handle_error "An unexpected error occurred on line $LINENO"' ERR
```

- **Purpose**: Global error handling for unexpected failures
- **Behavior**: Automatically calls `handle_error` with line number information
- **Coverage**: Catches any command that exits with non-zero status (due to `set -e`)

## Function Dependencies

### Call Graph
```
main()
├── check_tty()
├── check_root()
├── check_prerequisites()
├── collect_configuration()
│   ├── prompt_user()
│   └── confirm_action()
├── install_tools()
├── run_disko()
├── setup_luks()
├── setup_zfs()
├── create_mount_directories()
├── mount_filesystems()
├── verify_mounts()
├── create_persistent_directories()
├── generate_hardware_config()
├── copy_configuration()
├── install_nixos()
├── cleanup_installation()
└── display_final_instructions()

# Error handling (called on any failure)
handle_error()
└── cleanup_on_error()
```

### Critical Error Paths
- Any function failure triggers `handle_error()` via the ERR trap
- `handle_error()` calls `cleanup_on_error()` for resource cleanup
- All cleanup operations are designed to be safe even if resources weren't allocated

This function reference provides the complete API documentation for understanding and maintaining the NixOS installation scripts.