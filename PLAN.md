# Dotfiles Plan

**Approach:** GNU Stow (with a clear migration path to Chezmoi)
**Target:** Linux VMs (Ubuntu) — workstation, homelab agents, etc.
**Shell:** bash
**Tools managed:** see Packages section below

---

## Directory Structure

```
dotfiles/
├── PLAN.md                   # this file
├── README.md                 # usage, onboarding a new machine
├── Brewfile                  # brew bundle manifest (all managed packages)
├── bootstrap.sh              # entry point: install deps, run stow
├── packages.sh               # install tools via brew bundle
├── stow.sh                   # wrapper: simulate or apply stow packages
│
├── git/                      # stow package
│   └── .gitconfig            # single identity + aliases (lg, etc.)
│
├── bash/                     # stow package
│   └── .bashrc
│
├── tmux/                     # stow package
│   └── .tmux.conf
│
├── starship/                 # stow package
│   └── .config/
│       └── starship.toml
│
└── nvim/                     # stow package
    └── .config/
        └── nvim/             # LazyVim config directory
```

Each top-level folder is a **stow package** — a logical grouping of one tool's config. Stow symlinks the contents into `$HOME`, preserving directory structure.

**Deferred packages** (not in initial setup):
- `asdf/` — runtime version management; defer until there's a clear need for per-project language versions

---

## Bootstrap Flow (new machine)

1. **Pre-flight**: check for and back up any existing dotfiles (`~/.gitconfig.bak`, etc.)
2. **Install Homebrew** (Linuxbrew): `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
3. **Install packages** via `packages.sh`: runs `brew bundle --file=./Brewfile`
4. **Install Claude Code**: `curl -fsSL https://claude.ai/install.sh | bash`
5. **Dry run stow** first: `./stow.sh --simulate` — review conflicts before touching anything
6. **Apply stow**: `./stow.sh` — symlinks all packages into `$HOME`
7. **Source shell config**: `source ~/.bashrc`

The bootstrap script should be idempotent — safe to re-run on an already-configured machine.


---

## Packages (Brewfile)

Organized into logical groups for readability in the Brewfile:

**QoL / shell tools**
- `git`, `tree`, `tmux`, `stow`
- `ripgrep` (rg), `fd`, `fzf`, `zoxide`
- `starship`

**Neovim + LazyVim stack**
- `neovim`
- `ripgrep`, `fd`, `fzf` (shared with above — listed once in Brewfile)
- Nerd Fonts (cask — on Linux, install manually from nerd-fonts releases; note this in README)

**Dev / cloud tools**
- `gh` (GitHub CLI)
- `awscli`

**AI tools**
- `opencode`
- Claude Code — installed separately via `curl -fsSL https://claude.ai/install.sh | bash` (not a brew package)

**Future (not in initial Brewfile)**
- `asdf` — deferred

> **On native installers**: the Brewfile tracks what you want reproducible across machines. If you prefer a native installer for something (e.g., a specific neovim nightly), skip it in the Brewfile and document the manual step in README instead.

---

## Stow Usage

```bash
# Simulate (dry run — always run this first on a new machine)
stow --simulate --dir=. --target=$HOME git tmux starship zsh asdf

# Apply all packages
stow --dir=. --target=$HOME git tmux starship zsh asdf

# Add a new package later
stow --dir=. --target=$HOME <new-package>

# Remove a package's symlinks (un-stow)
stow --delete --dir=. --target=$HOME <package>
```

### Conflict resolution (before first run)
For any existing file that conflicts, move it out of the way:
```bash
mv ~/.gitconfig ~/.gitconfig.bak
# then run stow
```

---

## Conventions

- **What lives in the repo**: config files only — no secrets, no machine-specific values
- **What doesn't**: API keys, tokens, SSH keys, anything in `~/.secrets/` or `.env` files
- **Per-machine overrides**: use a local include pattern where the tool supports it (e.g., `~/.gitconfig.local` included from `.gitconfig`)
- **Shell init order**: keep `.zshrc` clean — source tool inits (asdf, starship, homebrew) in a predictable, documented order

---

## Adding New Tools

1. Create a new folder at the top level: `mkdir <toolname>`
2. Mirror the `$HOME` path inside it: e.g., `<toolname>/.config/<toolname>/config.toml`
3. Stow it: `stow --dir=. --target=$HOME <toolname>`
4. Commit the new package

---

## Chezmoi Migration Path

Chezmoi is a natural next step if you need:
- Per-machine config templating (e.g., different `$EDITOR` on Mac vs Linux)
- Secret injection (Age/SOPS integration, 1Password, etc.)
- Encrypted files in the repo

### Why Stow now is not a dead end

The dotfiles themselves are portable — Chezmoi manages the same files, just differently. Migration is a tooling swap, not a rewrite:

1. `chezmoi init` in the existing repo
2. `chezmoi import` each config file — Chezmoi renames them (`dot_gitconfig`, etc.) and takes over management
3. Replace `stow.sh` with `chezmoi apply` in the bootstrap
4. Add templates (`{{ if eq .chezmoi.os "linux" }}`) only where you actually need branching

### Migration triggers (when to consider it)

- You need Mac support (different Homebrew path, different tools)
- You want secrets injected at apply time rather than manually placed
- You're managing dotfiles across 5+ machines and per-machine overrides get unwieldy

### What to avoid in the Stow phase (to keep migration easy)

- Don't rely on stow-specific features or symlink tricks inside config files
- Keep configs self-contained — no hardcoded absolute paths like `/home/patrick/...`
- Use `$HOME`, `$XDG_CONFIG_HOME`, and relative paths throughout

---

## Open Questions (decide before writing code)

- **Git aliases**: finalized list beyond `lg`? Worth capturing now so `.gitconfig` is complete on first write.
- **Nerd Fonts on Linux**: brew casks don't work on Linux — manual install from nerd-fonts releases, or a small script in `bootstrap.sh`? Document clearly in README either way.
- **`.bashrc` vs `.bash_profile`**: on Ubuntu, interactive login shells source `.bash_profile`; non-login interactive shells source `.bashrc`. Decide on the split before writing shell config.

**Resolved:**
- Shell: bash ✓
- Git identity: single `.gitconfig` with aliases ✓
- asdf: deferred ✓
- Brewfile: yes ✓
