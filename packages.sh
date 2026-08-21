#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing packages via brew bundle..."
brew bundle --file="$SCRIPT_DIR/Brewfile"
echo "==> Packages installed."

if command -v npm &>/dev/null && [[ -s "$SCRIPT_DIR/npm-globals.txt" ]]; then
  echo "==> Installing npm globals..."
  xargs npm install -g < "$SCRIPT_DIR/npm-globals.txt"
fi

if command -v bun &>/dev/null && [[ -s "$SCRIPT_DIR/bun-globals.txt" ]]; then
  echo "==> Installing bun globals..."
  xargs -I{} bun install -g {} < "$SCRIPT_DIR/bun-globals.txt"
fi
