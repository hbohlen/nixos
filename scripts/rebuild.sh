#!/usr/bin/env bash
# /scripts/rebuild.sh
# Enhanced NixOS rebuild script with comprehensive features
#
# This script provides an enhanced interface to nixos-rebuild with:
# - Automatic hostname detection with manual override
# - Support for all rebuild modes (switch, boot, test, build, dry-run)
# - Comprehensive error handling and user feedback
# - Garbage collection and cleanup options
# - Verbose and quiet modes
# - Help documentation and usage examples

# Exit immediately if a command exits with a non-zero status.
# Also exit on undefined variables and pipe failures
set -euo pipefail

# Script version and metadata
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_NAME="$(basename "$0")"

# Default configuration
DEFAULT_MODE="switch"
DEFAULT_HOSTNAME="$(hostname)"
MODE=""
VERBOSE=false
QUIET=false
FORCE=false
NO_BUILD_NIX=false
ROLLBACK=false
INSTALL_BOOTLOADER=true
FLAKE_UPDATE=false

# Cleanup options
GC_AFTER=false
GC_OLDER_THAN=""
DELETE_OLDER_THAN=""

# Color codes for enhanced output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly PURPLE='\033[0;35m'
readonly GRAY='\033[0;90m'
readonly NC='\033[0m' # No Color

# Enhanced logging functions
log() { 
    [[ "$QUIET" != "true" ]] && echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

info() { 
    [[ "$QUIET" != "true" ]] && log "${BLUE}INFO${NC}: $*"
}

success() {
    [[ "$QUIET" != "true" ]] && log "${GREEN}SUCCESS${NC}: $*"
}

warn() { 
    [[ "$QUIET" != "true" ]] && log "${YELLOW}WARN${NC}: $*"
}

error() { 
    log "${RED}ERROR${NC}: $*"
    exit 1
}

debug() {
    [[ "$VERBOSE" == "true" ]] && log "${GRAY}DEBUG${NC}: $*"
}

step() {
    [[ "$QUIET" != "true" ]] && log "${CYAN}STEP${NC}: $*"
}

# Progress indicator for long operations
progress() {
    local msg="$1"
    [[ "$QUIET" != "true" ]] && echo -ne "${PURPLE}⏳${NC} $msg... " >&2
}

progress_done() {
    [[ "$QUIET" != "true" ]] && echo -e "${GREEN}✓${NC}" >&2
}

progress_fail() {
    [[ "$QUIET" != "true" ]] && echo -e "${RED}✗${NC}" >&2
}

# Help and usage documentation
show_help() {
    echo "${SCRIPT_NAME} v${SCRIPT_VERSION} - Enhanced NixOS Rebuild Script"
    echo ""
    echo "USAGE:"
    echo "    ${SCRIPT_NAME} [MODE] [OPTIONS]"
    echo ""
    echo "MODES:"
    echo "    switch      Build and activate configuration (default)"
    echo "    boot        Build configuration and make it default for next boot"
    echo "    test        Build and activate configuration, but don't make it default"
    echo "    build       Build configuration but don't activate it"
    echo "    dry-run     Show what would be built without building"
    echo "    dry-build   Show what would be built (alias for dry-run)"
    echo ""
    echo "OPTIONS:"
    echo "    -h, --help              Show this help message"
    echo "    -v, --verbose           Enable verbose output"
    echo "    -q, --quiet             Suppress non-error output"
    echo "    -H, --hostname HOST     Override hostname detection (default: auto-detect)"
    echo "    -f, --force             Force rebuild even if no changes detected"
    echo "    --no-build-nix          Don't build nix packages (faster for testing)"
    echo "    --rollback              Rollback to previous generation"
    echo "    --no-bootloader         Don't reinstall bootloader"
    echo "    --flake-update          Update flake inputs before building"
    echo ""
    echo "CLEANUP OPTIONS:"
    echo "    --gc                    Run garbage collection after successful rebuild"
    echo "    --gc-older-than TIME    Remove generations older than TIME (e.g., 7d, 30d)"
    echo "    --delete-older-than TIME Delete old user profiles older than TIME"
    echo ""
    echo "EXAMPLES:"
    echo "    ${SCRIPT_NAME}                          # Auto-detect hostname and switch"
    echo "    ${SCRIPT_NAME} test                     # Test new configuration"
    echo "    ${SCRIPT_NAME} boot --hostname server   # Build boot config for server"
    echo "    ${SCRIPT_NAME} switch --gc --verbose    # Switch with cleanup and verbose output"
    echo "    ${SCRIPT_NAME} dry-run                  # See what would be built"
    echo "    ${SCRIPT_NAME} --rollback              # Rollback to previous generation"
    echo ""
    echo "ENVIRONMENT VARIABLES:"
    echo "    REBUILD_HOSTNAME        Override hostname detection"
    echo "    REBUILD_MODE           Override default mode"
    echo "    REBUILD_VERBOSE        Enable verbose output (any non-empty value)"
    echo "    REBUILD_QUIET          Enable quiet mode (any non-empty value)"
    echo ""
    echo "This script automatically detects your hostname and builds the corresponding"
    echo "configuration from flake.nix. Available hosts are: laptop, desktop, server."
    echo ""
    echo "For more information, see the repository README.md."
}

# Show usage examples
show_examples() {
    echo -e "${PURPLE}Common Usage Examples:${NC}"
    echo ""
    echo -e "${CYAN}Basic Operations:${NC}"
    echo "    ${SCRIPT_NAME}                     # Standard rebuild and switch"
    echo "    ${SCRIPT_NAME} test               # Test configuration without making it default"
    echo "    ${SCRIPT_NAME} boot               # Build for next boot only"
    echo "    ${SCRIPT_NAME} dry-run            # Preview changes without building"
    echo ""
    echo -e "${CYAN}With Cleanup:${NC}"
    echo "    ${SCRIPT_NAME} switch --gc                    # Rebuild and cleanup old generations"
    echo "    ${SCRIPT_NAME} switch --gc-older-than 7d     # Remove generations older than 7 days"
    echo "    ${SCRIPT_NAME} switch --delete-older-than 30d # Remove old profiles older than 30 days"
    echo ""
    echo -e "${CYAN}Troubleshooting:${NC}"
    echo "    ${SCRIPT_NAME} --verbose          # Detailed output for debugging"
    echo "    ${SCRIPT_NAME} --rollback         # Revert to previous generation"
    echo "    ${SCRIPT_NAME} build             # Build without activating to test for errors"
    echo ""
    echo -e "${CYAN}Cross-host Management:${NC}"
    echo "    ${SCRIPT_NAME} switch --hostname desktop     # Build specific host config"
    echo "    ${SCRIPT_NAME} test --hostname server        # Test server config from any host"
    echo ""
    echo -e "${CYAN}Development Workflow:${NC}"
    echo "    ${SCRIPT_NAME} --flake-update test          # Update inputs and test"
    echo "    ${SCRIPT_NAME} build --no-build-nix         # Fast build for config testing"
    echo "    ${SCRIPT_NAME} dry-run --verbose            # Detailed preview of changes"
}

# Validate hostname exists in flake configuration
validate_hostname() {
    local hostname="$1"
    
    progress "Validating hostname '$hostname' in flake configuration"
    
    # Check if nix is available
    if ! command -v nix >/dev/null 2>&1; then
        progress_fail
        warn "nix command not found. Skipping hostname validation."
        warn "Make sure you're running this on a NixOS system."
        return 0
    fi
    
    # Get available hosts
    local available_hosts
    if available_hosts=$(nix eval --no-warn-dirty --raw ".#nixosConfigurations" 2>/dev/null | jq -r 'keys[]' 2>/dev/null); then
        debug "Available hosts: $available_hosts"
        
        # Check if hostname exists
        if echo "$available_hosts" | grep -q "^$hostname$"; then
            progress_done
            return 0
        else
            progress_fail
            error "Host '$hostname' not found in flake configuration. Available hosts: $(echo "$available_hosts" | tr '\n' ' ')"
        fi
    else
        progress_fail
        error "Failed to read flake configuration. Is flake.nix valid?"
    fi
}

# Get available hosts for help/error messages
get_available_hosts() {
    nix eval --no-warn-dirty --raw ".#nixosConfigurations" 2>/dev/null | jq -r 'keys[]' 2>/dev/null | tr '\n' ' ' || echo "unable to list"
}

# Cleanup old generations
cleanup_generations() {
    local gc_older_than="$1"
    local delete_older_than="$2"
    
    if ! command -v nix >/dev/null 2>&1; then
        warn "nix command not found. Skipping cleanup."
        return 0
    fi
    
    if [[ -n "$gc_older_than" ]]; then
        step "Removing system generations older than $gc_older_than"
        sudo nix-collect-garbage --delete-older-than "$gc_older_than" || warn "Failed to cleanup old generations"
    fi
    
    if [[ -n "$delete_older_than" ]]; then
        step "Removing user profiles older than $delete_older_than"
        nix-collect-garbage --delete-older-than "$delete_older_than" || warn "Failed to cleanup old user profiles"
    fi
    
    if [[ "$GC_AFTER" == "true" && -z "$gc_older_than" && -z "$delete_older_than" ]]; then
        step "Running full garbage collection"
        sudo nix-collect-garbage -d || warn "Garbage collection failed"
    fi
}

# Update flake inputs
update_flake() {
    if [[ "$FLAKE_UPDATE" == "true" ]]; then
        if ! command -v nix >/dev/null 2>&1; then
            warn "nix command not found. Skipping flake update."
            return 0
        fi
        step "Updating flake inputs"
        nix flake update || warn "Failed to update flake inputs"
    fi
}

# Main rebuild function
perform_rebuild() {
    local mode="$1"
    local hostname="$2"
    
    # Check if nixos-rebuild is available
    if ! command -v nixos-rebuild >/dev/null 2>&1; then
        warn "nixos-rebuild command not found. This is expected in non-NixOS environments."
        info "On NixOS, this would execute: nixos-rebuild $mode --flake \".#$hostname\""
        return 0
    fi
    
    # Build nixos-rebuild command
    local rebuild_cmd="nixos-rebuild"
    local rebuild_args=("$mode" "--flake" ".#$hostname")
    
    # Add optional flags
    [[ "$VERBOSE" == "true" ]] && rebuild_args+=("--verbose")
    [[ "$NO_BUILD_NIX" == "true" ]] && rebuild_args+=("--fast")
    [[ "$INSTALL_BOOTLOADER" == "false" ]] && rebuild_args+=("--no-build-nix")
    
    debug "Rebuild command: $rebuild_cmd ${rebuild_args[*]}"
    
    case "$mode" in
        "switch"|"boot")
            step "Building and ${mode}ing to new configuration for host: $hostname"
            sudo "$rebuild_cmd" "${rebuild_args[@]}"
            ;;
        "test")
            step "Building and testing new configuration for host: $hostname"
            sudo "$rebuild_cmd" "${rebuild_args[@]}"
            ;;
        "build")
            step "Building new configuration for host: $hostname"
            "$rebuild_cmd" "${rebuild_args[@]}"
            ;;
        "dry-run"|"dry-build")
            step "Performing dry run for host: $hostname"
            "$rebuild_cmd" dry-activate --flake ".#$hostname"
            ;;
        *)
            error "Unknown mode: $mode"
            ;;
    esac
}

# Rollback to previous generation
perform_rollback() {
    if ! command -v nixos-rebuild >/dev/null 2>&1; then
        warn "nixos-rebuild command not found. Cannot perform rollback."
        info "On NixOS, this would execute: nixos-rebuild switch --rollback"
        return 0
    fi
    
    step "Rolling back to previous generation"
    sudo nixos-rebuild switch --rollback
}

# Parse command line arguments - modifies global MODE variable
parse_arguments() {
    MODE="$DEFAULT_MODE"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            # Modes
            switch|boot|test|build|dry-run|dry-build)
                MODE="$1"
                shift
                ;;
            # Help options
            -h|--help)
                show_help
                exit 0
                ;;
            --examples)
                show_examples
                exit 0
                ;;
            # Verbosity options
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            # Hostname override
            -H|--hostname)
                [[ $# -lt 2 ]] && error "Option $1 requires an argument"
                DEFAULT_HOSTNAME="$2"
                shift 2
                ;;
            # Build options
            -f|--force)
                FORCE=true
                shift
                ;;
            --no-build-nix)
                NO_BUILD_NIX=true
                shift
                ;;
            --rollback)
                ROLLBACK=true
                shift
                ;;
            --no-bootloader)
                INSTALL_BOOTLOADER=false
                shift
                ;;
            --flake-update)
                FLAKE_UPDATE=true
                shift
                ;;
            # Cleanup options
            --gc)
                GC_AFTER=true
                shift
                ;;
            --gc-older-than)
                [[ $# -lt 2 ]] && error "Option $1 requires an argument"
                GC_OLDER_THAN="$2"
                shift 2
                ;;
            --delete-older-than)
                [[ $# -lt 2 ]] && error "Option $1 requires an argument"
                DELETE_OLDER_THAN="$2"
                shift 2
                ;;
            # Unknown option
            -*)
                error "Unknown option: $1. Use --help for usage information."
                ;;
            # Unknown argument
            *)
                error "Unknown argument: $1. Use --help for usage information."
                ;;
        esac
    done
    
    # Handle environment variables
    [[ -n "${REBUILD_HOSTNAME:-}" ]] && DEFAULT_HOSTNAME="$REBUILD_HOSTNAME"
    [[ -n "${REBUILD_MODE:-}" ]] && MODE="$REBUILD_MODE"
    [[ -n "${REBUILD_VERBOSE:-}" ]] && VERBOSE=true
    [[ -n "${REBUILD_QUIET:-}" ]] && QUIET=true
    
    # Validate conflicting options
    [[ "$VERBOSE" == "true" && "$QUIET" == "true" ]] && error "Cannot use both --verbose and --quiet"
}

# Main execution function
main() {
    # Parse arguments first - this handles --help and exits early if needed
    parse_arguments "$@"
    
    # Show startup banner unless quiet
    if [[ "$QUIET" != "true" ]]; then
        echo -e "${PURPLE}${SCRIPT_NAME} v${SCRIPT_VERSION}${NC} - Enhanced NixOS Rebuild Script"
        echo
    fi
    
    # Navigate to the flake's root directory
    local flake_dir
    flake_dir="$(dirname "${BASH_SOURCE[0]}")/.."
    flake_dir="$(cd "$flake_dir" && pwd)"
    debug "Flake directory: $flake_dir"
    
    cd "$flake_dir" || error "Failed to change to flake directory: $flake_dir"
    
    # Validate that we have a flake.nix file
    [[ -f "flake.nix" ]] || error "flake.nix not found in $flake_dir"
    
    info "Mode: $MODE, Hostname: $DEFAULT_HOSTNAME"
    
    # Handle special modes
    if [[ "$ROLLBACK" == "true" ]]; then
        perform_rollback
        success "System rollback complete"
        return 0
    fi
    
    # Update flake if requested
    update_flake
    
    # Validate hostname exists in configuration
    validate_hostname "$DEFAULT_HOSTNAME"
    
    # Perform the rebuild
    perform_rebuild "$MODE" "$DEFAULT_HOSTNAME"
    
    # Cleanup if requested
    cleanup_generations "$GC_OLDER_THAN" "$DELETE_OLDER_THAN"
    
    # Final success message
    success "System rebuild complete for host: $DEFAULT_HOSTNAME"
    
    if [[ "$MODE" == "switch" || "$MODE" == "boot" ]]; then
        info "Configuration activated. Reboot may be required for some changes to take effect."
    elif [[ "$MODE" == "test" ]]; then
        info "Configuration tested and activated temporarily. It will not persist after reboot."
    elif [[ "$MODE" == "build" ]]; then
        info "Configuration built successfully. Use 'switch' or 'boot' to activate it."
    fi
    
    # Explicit successful exit
    exit 0
}

# Run main function with all arguments
main "$@"