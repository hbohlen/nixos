#!/usr/bin/env bash
set -euo pipefail

MODE_NIX_ONLY=false
MODE_CHECK=false
for arg in "$@"; do
  case "$arg" in
    --nix-only) MODE_NIX_ONLY=true ;;
    --check) MODE_CHECK=true ;;
  esac
done

run_prettier() {
  if command -v npm >/dev/null 2>&1 && [ -f package.json ]; then
    if [ ! -d node_modules ]; then
      npm install --silent || true
    fi
    if [ "$MODE_CHECK" = true ]; then
      npx --yes prettier --check "**/*.{md,json,yml,yaml}" || true
    else
      npx --yes prettier --write "**/*.{md,json,yml,yaml}" || true
    fi
  fi
}

if [ "$MODE_NIX_ONLY" = false ]; then
  run_prettier
fi

if command -v nix >/dev/null 2>&1; then
  echo "Using nix fmt via flake formatter..."
  if [ "$MODE_CHECK" = true ]; then
    # nix fmt has no check mode; we diff instead
    tmpdir=$(mktemp -d)
    rsync -a --exclude '.git' --exclude 'node_modules' ./ "$tmpdir/" >/dev/null 2>&1 || true
    (cd "$tmpdir" && nix fmt >/dev/null 2>&1 || true)
    if ! git --no-pager diff --no-index --quiet . "$tmpdir"; then
      echo "Nix files are not formatted." >&2
      exit 1
    fi
    rm -rf "$tmpdir"
  else
    nix fmt
  fi
  exit 0
fi

if command -v nixfmt >/dev/null 2>&1; then
  echo "Using nixfmt directly..."
  if [ "$MODE_CHECK" = true ]; then
    if ! nixfmt --check -r .; then
      echo "Nix files are not formatted." >&2
      exit 1
    fi
  else
    nixfmt -r .
  fi
  exit 0
fi

if command -v docker >/dev/null 2>&1; then
  echo "Using Alejandra via Docker (no Nix available)..."
  if [ "$MODE_CHECK" = true ]; then
    docker run --rm -v "$PWD":/work -w /work ghcr.io/kamadorueda/alejandra:latest --check . || {
      echo "Nix files are not formatted." >&2; exit 1; }
  else
    docker run --rm -v "$PWD":/work -w /work ghcr.io/kamadorueda/alejandra:latest -q .
  fi
  exit 0
fi

cat >&2 <<'EOF'
No Nix or nixfmt found.

Options:
1) Install Nix, then run: nix fmt
   curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
   . "$HOME/.nix-profile/etc/profile.d/nix.sh"

2) Install nixfmt locally (if available for your OS) or use Docker:
  docker run --rm -v "$PWD":/work -w /work ghcr.io/kamadorueda/alejandra:latest -q .
EOF
exit 1
