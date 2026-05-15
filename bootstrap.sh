#!/usr/bin/env bash
# Bootstrap a new machine with these dotfiles.
# Safe to re-run — all steps are idempotent.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Step 1: Pre-flight — back up any conflicting dotfiles ─────────────────────
echo "==> Checking for existing dotfiles..."
for f in .gitconfig .bashrc .bash_profile; do
  target="$HOME/$f"
  if [[ -f "$target" && ! -L "$target" ]]; then
    echo "    Backing up $target -> ${target}.bak"
    mv "$target" "${target}.bak"
  fi
done

for dir in .config/nvim .config/starship.toml .config/tmux; do
  target="$HOME/$dir"
  if [[ -e "$target" && ! -L "$target" ]]; then
    echo "    Backing up $target -> ${target}.bak"
    mv "$target" "${target}.bak"
  fi
done

# ── Step 2: Install Homebrew (Linuxbrew) ──────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add brew to PATH for the rest of this script
  if [[ -d /home/linuxbrew/.linuxbrew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [[ -d /usr/local/Homebrew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "==> Homebrew already installed, skipping."
fi

# ── Step 3: Install packages ──────────────────────────────────────────────────
"$SCRIPT_DIR/packages.sh"

# ── Step 4: Install Claude Code ───────────────────────────────────────────────
if ! command -v claude &>/dev/null; then
  echo "==> Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
else
  echo "==> Claude Code already installed, skipping."
fi

# ── Step 5: Bootstrap TPM ────────────────────────────────────────────────────
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  echo "==> Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  echo "==> TPM already installed, skipping."
fi

# ── Step 6: Dry-run stow — review before committing ──────────────────────────
echo ""
echo "==> Simulating stow (dry run)..."
"$SCRIPT_DIR/stow.sh" --simulate
echo ""

# Prompt before applying
read -r -p "Apply stow symlinks? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
  # ── Step 7: Apply stow ───────────────────────────────────────────────────
  "$SCRIPT_DIR/stow.sh"

  # ── Step 8: Source shell config ──────────────────────────────────────────
  echo ""
  echo "==> Bootstrap complete!"
  echo "    Run: source ~/.bashrc"
else
  echo "==> Stow skipped. Run './stow.sh' when ready."
fi

# ── Post-bootstrap reminders ──────────────────────────────────────────────────
echo ""
echo "Reminders:"
echo "  - Set up git identity: create ~/.gitconfig.local with [user] name/email"
echo "  - Nerd Fonts: install manually from https://www.nerdfonts.com/font-downloads"
echo "    (brew casks don't work on Linux)"
echo "  - Machine-specific shell config: ~/.bashrc.local"
echo "  - tmux plugins: start tmux, then press prefix+I to install via TPM"
