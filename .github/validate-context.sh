#!/usr/bin/env bash
# Validation script for ByteRover MCP knowledge base
# This script demonstrates how the context can be quickly accessed and validated

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GITHUB_DIR="$REPO_ROOT/.github"

echo "🔍 ByteRover MCP Knowledge Base Validation"
echo "========================================="
echo

# Check all knowledge base files exist
echo "📁 Checking knowledge base files..."
required_files=(
    "byterover-index.md"
    "byterover-context.md"  
    "module-patterns.md"
    "development-workflows.md"
    "copilot-instructions.md"
)

for file in "${required_files[@]}"; do
    if [[ -f "$GITHUB_DIR/$file" ]]; then
        lines=$(wc -l < "$GITHUB_DIR/$file")
        echo "  ✅ $file ($lines lines)"
    else
        echo "  ❌ $file - MISSING"
        exit 1
    fi
done

echo
echo "📊 Knowledge Base Statistics:"
total_lines=$(wc -l "$GITHUB_DIR"/byterover-*.md "$GITHUB_DIR"/*patterns*.md "$GITHUB_DIR"/*workflow*.md | tail -1 | awk '{print $1}')
echo "  Total context lines: $total_lines"

# Test key information is accessible
echo
echo "🔎 Testing knowledge accessibility..."

# Check repository identity
if grep -q "hbohlen/nixos" "$GITHUB_DIR/byterover-index.md"; then
    echo "  ✅ Repository identity documented"
else
    echo "  ❌ Repository identity missing"
    exit 1
fi

# Check host configurations
if grep -qi "desktop.*laptop.*server\|hosts.*desktop.*laptop.*server" "$GITHUB_DIR/byterover-context.md" || \
   (grep -qi "desktop" "$GITHUB_DIR/byterover-context.md" && grep -qi "laptop" "$GITHUB_DIR/byterover-context.md" && grep -qi "server" "$GITHUB_DIR/byterover-context.md"); then
    echo "  ✅ Host configurations documented"
else
    echo "  ❌ Host configurations missing"
    exit 1
fi

# Check module patterns
if grep -q "Module Dependency Graph" "$GITHUB_DIR/module-patterns.md"; then
    echo "  ✅ Module patterns documented"
else
    echo "  ❌ Module patterns missing" 
    exit 1
fi

# Check workflows
if grep -q "Standard Development Cycle" "$GITHUB_DIR/development-workflows.md"; then
    echo "  ✅ Development workflows documented"
else
    echo "  ❌ Development workflows missing"
    exit 1
fi

# Check integration with copilot instructions
if grep -q "byterover-index.md" "$GITHUB_DIR/copilot-instructions.md"; then
    echo "  ✅ Copilot instructions integrated with knowledge base"
else
    echo "  ❌ Copilot instructions not integrated"
    exit 1
fi

echo
echo "🎯 Context Completeness Check:"

# Essential architecture components
essential_concepts=(
    "Ephemeral Root"
    "ZFS.*LUKS" 
    "Impermanence"
    "Home Manager"
    "Nix Flakes"
    "Opnix.*1Password"
)

all_files="$GITHUB_DIR/byterover-*.md $GITHUB_DIR/*patterns*.md $GITHUB_DIR/*workflow*.md"

for concept in "${essential_concepts[@]}"; do
    if grep -qiE "$concept" $all_files; then
        echo "  ✅ $concept"
    else
        echo "  ❌ $concept - Missing from context"
        exit 1
    fi
done

echo
echo "🚀 Quick Reference Test:"

# Test that common tasks are documented
common_tasks=(
    "nixos-rebuild.*build"
    "./scripts/rebuild.sh"
    "nix flake check"
    "rollback"
)

for task in "${common_tasks[@]}"; do
    if grep -qE "$task" $all_files; then
        echo "  ✅ $task workflow documented"
    else
        echo "  ❌ $task workflow missing"
        exit 1
    fi
done

echo
echo "✅ ByteRover MCP Knowledge Base Validation PASSED"
echo "📚 Context is complete and accessible for AI assistance"
echo "🔗 Access via: .github/byterover-index.md"
echo