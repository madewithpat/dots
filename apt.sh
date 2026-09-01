#!/usr/bin/env bash
# Debian/Ubuntu packages Homebrew shouldn't own (e.g. a compiler with
# unversioned `gcc`/`cc`, unlike the brewed gcc formula). No-op elsewhere.
set -euo pipefail

if ! command -v apt-get &>/dev/null; then
  echo "==> apt-get not found, skipping apt packages."
  exit 0
fi

echo "==> Installing apt packages..."
sudo apt-get update
sudo apt-get install -y build-essential
echo "==> apt packages installed."
