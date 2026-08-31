#!/usr/bin/env bash
# Bootstrap a new machine with these dotfiles.
# Safe to re-run — all steps are idempotent.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Step 1: Pre-flight — back up any conflicting dotfiles ─────────────────────
echo "==> Checking for existing dotfiles..."
for f in .gitconfig .mwp.gitconfig .tm.gitconfig .bashrc .bash_profile .zshrc; do
  target="$HOME/$f"
  if [[ -f "$target" && ! -L "$target" ]]; then
    echo "    Backing up $target -> ${target}.bak"
    mv "$target" "${target}.bak"
  fi
done

for dir in .config/nvim .config/starship.toml .config/tmux .config/shell \
  .claude/settings.json .claude/statusline-command.sh .claude/file-suggestion.sh \
  .omp/agent/models.yml \
  .local/bin/ornith .local/bin/llama-server-ornith-wrapper.sh .local/bin/ollama-ornith-setup.sh \
  Library/LaunchAgents/com.mwp.llama-server-ornith.plist; do
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

# ── Step 4b: Install bun ──────────────────────────────────────────────────────
if ! command -v bun &>/dev/null; then
  echo "==> Installing bun..."
  curl -fsSL https://bun.sh/install | bash
else
  echo "==> bun already installed, skipping."
fi

# ── Step 4c: Install oh-my-pi (omp) — macOS only for now, see stow.sh ─────────
if [[ "$(uname)" == "Darwin" ]] && ! command -v omp &>/dev/null; then
  echo "==> Installing oh-my-pi (omp)..."
  curl -fsSL https://omp.sh/install | sh
elif [[ "$(uname)" == "Darwin" ]]; then
  echo "==> omp already installed, skipping."
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
  echo "    Run: source ~/.bashrc (Linux) or source ~/.zshrc (macOS)"
else
  echo "==> Stow skipped. Run './stow.sh' when ready."
fi

# ── Post-bootstrap reminders ──────────────────────────────────────────────────
echo ""
echo "Reminders:"
echo "  - Set up git identity: create ~/.gitconfig.local with [user] name/email/signingkey and any [url \"...\"] insteadOf rewrites for your GitHub orgs (required — this repo's git config signs commits by default; see README). Need a per-directory identity override (e.g. work vs. client repos)? Create ~/.mwp.gitconfig-style files too — see README."
echo "  - Nerd Fonts: install manually from https://www.nerdfonts.com/font-downloads"
echo "    (brew casks don't work on Linux)"
echo "  - Machine-specific shell config: ~/.bashrc.local"
if [[ "$(uname)" == "Darwin" ]]; then
  echo "  - Ornith (local LLM server) is NOT auto-started by this script —"
  echo "    it pulls a ~22GB model. When ready: ollama-ornith-setup.sh, then"
  echo "    'ornith start' (loads the launchd agent for the first time)."
fi
echo "  - tmux plugins: start tmux, then press prefix+I to install via TPM"
