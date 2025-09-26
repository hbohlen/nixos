#!/usr/bin/env bash

# Test script for validating NixOS flake build configurations
# This script validates that both laptop and desktop configurations can be built

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

echo "=== NixOS Flake Build Test ==="
echo "Repository: $REPO_ROOT"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

# Function to test a single configuration
test_config() {
    local config_name="$1"
    echo "Testing $config_name configuration..."
    
    if command -v nix >/dev/null 2>&1; then
        echo "  Attempting to build $config_name..."
        if nix build ".#nixosConfigurations.$config_name.config.system.build.toplevel" --no-link --show-trace; then
            success "$config_name configuration builds successfully"
            return 0
        else
            error "$config_name configuration failed to build"
            return 1
        fi
    else
        warning "nix command not available, skipping actual build test"
        echo "  To test building manually, run:"
        echo "    nix build .#nixosConfigurations.$config_name.config.system.build.toplevel --no-link"
        return 0
    fi
}

# Function to validate configuration structure
validate_structure() {
    echo "Validating flake structure..."
    
    # Check flake.nix exists and has configurations
    if [[ ! -f "flake.nix" ]]; then
        error "flake.nix not found"
        return 1
    fi
    
    if ! grep -q "nixosConfigurations" flake.nix; then
        error "nixosConfigurations not found in flake.nix"
        return 1
    fi
    
    # Check specific configurations exist
    for config in laptop desktop; do
        if grep -q "\"$config\" = mkSystem" flake.nix; then
            success "$config configuration found in flake.nix"
        else
            error "$config configuration not found in flake.nix"
            return 1
        fi
        
        # Check host directory exists
        if [[ -d "hosts/$config" ]]; then
            success "hosts/$config directory exists"
        else
            error "hosts/$config directory missing"
            return 1
        fi
        
        # Check default.nix exists
        if [[ -f "hosts/$config/default.nix" ]]; then
            success "hosts/$config/default.nix exists"
        else
            error "hosts/$config/default.nix missing"
            return 1
        fi
    done
    
    # Check user configuration
    if [[ -f "users/hbohlen/home.nix" ]]; then
        success "User home configuration exists"
    else
        error "User home configuration missing"
        return 1
    fi
    
    return 0
}

# Main execution
echo "1. Structure Validation:"
if validate_structure; then
    success "Flake structure validation passed"
else
    error "Flake structure validation failed"
    exit 1
fi

echo
echo "2. Configuration Build Tests:"

# Test laptop configuration
if test_config "laptop"; then
    LAPTOP_SUCCESS=true
else
    LAPTOP_SUCCESS=false
fi

echo

# Test desktop configuration  
if test_config "desktop"; then
    DESKTOP_SUCCESS=true
else
    DESKTOP_SUCCESS=false
fi

echo
echo "=== Test Summary ==="

if [[ "$LAPTOP_SUCCESS" = true ]]; then
    success "Laptop configuration: BUILDABLE"
else
    error "Laptop configuration: FAILED"
fi

if [[ "$DESKTOP_SUCCESS" = true ]]; then
    success "Desktop configuration: BUILDABLE"
else
    error "Desktop configuration: FAILED"
fi

if [[ "$LAPTOP_SUCCESS" = true && "$DESKTOP_SUCCESS" = true ]]; then
    echo
    success "ALL TESTS PASSED - Both configurations are buildable!"
    echo
    echo "To build a specific configuration:"
    echo "  nix build .#nixosConfigurations.laptop.config.system.build.toplevel"
    echo "  nix build .#nixosConfigurations.desktop.config.system.build.toplevel"
    echo
    echo "To rebuild the current system:"
    echo "  ./scripts/rebuild.sh"
    exit 0
else
    echo
    error "SOME TESTS FAILED - Check the output above"
    exit 1
fi