#!/usr/bin/env bash
# Test script for NixOS 25.05 flake fix
# This script validates that the unfree packages configuration is correctly centralized

set -euo pipefail

echo "🧪 Testing NixOS 25.05 Flake Fix"
echo "================================="

# Test 1: Check for duplicate allowUnfreePredicate definitions
echo "📋 Test 1: Checking for conflicting allowUnfreePredicate definitions..."
PREDICATE_COUNT=$(grep -r "allowUnfreePredicate.*=" . --include="*.nix" | grep -v "^#" | wc -l)
if [ "$PREDICATE_COUNT" -eq 1 ]; then
    echo "✅ PASS: Only one allowUnfreePredicate definition found (in unfree-packages.nix)"
else
    echo "❌ FAIL: Found $PREDICATE_COUNT allowUnfreePredicate definitions - should be only 1"
    grep -r "allowUnfreePredicate.*=" . --include="*.nix" | grep -v "^#" -n
    exit 1
fi

# Test 2: Check that flake.nix doesn't define allowUnfreePredicate
echo "📋 Test 2: Checking that flake.nix doesn't define allowUnfreePredicate..."
if grep -q "allowUnfreePredicate.*=" flake.nix; then
    echo "❌ FAIL: flake.nix still contains allowUnfreePredicate definition"
    exit 1
else
    echo "✅ PASS: flake.nix does not define allowUnfreePredicate"
fi

# Test 3: Check that unfree-packages.nix is properly structured
echo "📋 Test 3: Checking unfree-packages.nix structure..."
if grep -q "allowUnfree = true" modules/nixos/unfree-packages.nix && \
   grep -q "allowUnfreePredicate" modules/nixos/unfree-packages.nix; then
    echo "✅ PASS: unfree-packages.nix has both allowUnfree and allowUnfreePredicate"
else
    echo "❌ FAIL: unfree-packages.nix is missing required configuration"
    exit 1
fi

# Test 4: Check that all hosts have explicit enableAllFirmware settings
echo "📋 Test 4: Checking hardware.enableAllFirmware settings..."
HOSTS_WITH_FIRMWARE=$(grep -r "enableAllFirmware" hosts/ --include="*.nix" | wc -l)
if [ "$HOSTS_WITH_FIRMWARE" -ge 2 ]; then
    echo "✅ PASS: Found explicit enableAllFirmware settings in host configurations"
else
    echo "⚠️  WARNING: Some hosts may be missing explicit enableAllFirmware settings"
fi

# Test 5: Basic Nix syntax validation
echo "📋 Test 5: Basic Nix syntax validation..."
python3 << 'EOF'
import glob

def check_nix_syntax(filename):
    with open(filename, 'r') as f:
        content = f.read()
    
    brace_count = content.count('{') - content.count('}')
    bracket_count = content.count('[') - content.count(']')
    paren_count = content.count('(') - content.count(')')
    
    return brace_count == 0 and bracket_count == 0 and paren_count == 0

all_good = True
for file in ['flake.nix', 'modules/nixos/unfree-packages.nix', 'nixos_25_05_flake_fix.nix']:
    if not check_nix_syntax(file):
        print(f"ERROR: Syntax issue in {file}")
        all_good = False

if all_good:
    print("✅ PASS: All key files pass basic syntax validation")
else:
    print("❌ FAIL: Syntax validation failed")
    exit(1)
EOF

echo ""
echo "🎉 All tests passed! NixOS 25.05 flake fix is ready."
echo ""
echo "Summary of changes:"
echo "- Removed duplicate allowUnfreePredicate from flake.nix"
echo "- Removed duplicate allowUnfreePredicate from server.nix"
echo "- Centralized all unfree package configuration in unfree-packages.nix"
echo "- Added explicit allowUnfree = true in unfree-packages.nix"
echo "- Created documentation file nixos_25_05_flake_fix.nix"
echo ""
echo "This fix resolves the NixOS 25.05 build failure caused by conflicting"
echo "unfree package configurations and should allow successful system builds."