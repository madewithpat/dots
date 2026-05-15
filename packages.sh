#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing packages via brew bundle..."
brew bundle --file="$SCRIPT_DIR/Brewfile"
echo "==> Packages installed."
