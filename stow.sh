#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME"
SIMULATE=false

# Shell and OS are independent axes — see PLAN.md Conventions.
UNIVERSAL=(git shell-common tmux starship claude nvim dvc)
case "$(uname)" in
  Darwin) PACKAGES=("${UNIVERSAL[@]}" zsh ornith omp omp-ggt) ;;
  Linux)  PACKAGES=("${UNIVERSAL[@]}" bash) ;;
  *)      PACKAGES=("${UNIVERSAL[@]}") ;;
esac

usage() {
  echo "Usage: $0 [--simulate] [package ...]"
  echo ""
  echo "  --simulate    Dry run — show what stow would do without changing anything"
  echo "  package ...   Stow only these packages (default: OS-appropriate set below)"
  echo ""
  echo "Default packages for $(uname): ${PACKAGES[*]}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --simulate|-n) SIMULATE=true; shift ;;
    --help|-h) usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "Unknown flag: $1"; usage; exit 1 ;;
    *) break ;;
  esac
done

# If extra positional args remain, use them as the package list
if [[ $# -gt 0 ]]; then
  PACKAGES=("$@")
fi

# --no-folding: without it, stow "folds" a package's only file into a
# symlink of its *parent directory* when that directory doesn't yet exist
# on the target (e.g. omp/.omp/agent/models.yml, the first time, became one
# symlink for the whole ~/.omp/agent directory). Fine for read-only config,
# but a real bug for any directory a tool also writes runtime state into —
# hit this for real with omp's session/model caches landing inside this git
# repo. Individual file symlinks only, always.
STOW_FLAGS=(--dir="$SCRIPT_DIR" --target="$TARGET" --verbose=1 --no-folding)
if $SIMULATE; then
  STOW_FLAGS+=(--simulate)
  echo "==> Simulating stow (no changes will be made)..."
else
  echo "==> Applying stow packages: ${PACKAGES[*]}"
fi

stow "${STOW_FLAGS[@]}" "${PACKAGES[@]}"

if $SIMULATE; then
  echo "==> Simulation complete. Re-run without --simulate to apply."
else
  echo "==> Done. Run 'source ~/.bashrc' (Linux) or 'source ~/.zshrc' (macOS) to apply shell changes."
fi
