# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).
Target: Linux VMs (Ubuntu). Shell: bash.

## Quick start (new machine)

```bash
git clone git@github.com:madewithpat/dots.git ~/dots && ~/dots/bootstrap.sh
```

`bootstrap.sh` is idempotent — safe to re-run.

## What's managed

| Package  | Config                          |
|----------|---------------------------------|
| `git`    | `~/.gitconfig`                  |
| `bash`   | `~/.bashrc`, `~/.bash_profile`  |
| `tmux`   | `~/.tmux.conf`                  |
| `starship` | `~/.config/starship.toml`     |
| `nvim`   | `~/.config/nvim/` (LazyVim)     |

## Manual stow

```bash
# Simulate (always run this first)
./stow.sh --simulate

# Apply all packages
./stow.sh

# Apply specific package(s)
./stow.sh git tmux

# Remove a package's symlinks
stow --delete --dir=. --target=$HOME <package>
```

## Machine-local overrides

These files are gitignored and never committed:

| File | Purpose |
|------|---------|
| `~/.gitconfig.local` | Git identity (`[user]` name/email), per-machine settings |
| `~/.bashrc.local` | Machine-specific shell config, extra PATH entries, etc. |

Minimum `~/.gitconfig.local`:

```ini
[user]
    name = Your Name
    email = you@example.com
```

## Nerd Fonts (Linux)

Brew casks don't work on Linux. Install Nerd Fonts manually:

1. Download a font from <https://www.nerdfonts.com/font-downloads>
   (recommended: `JetBrainsMono` or `FiraCode`)
2. Unzip into `~/.local/share/fonts/`
3. Run `fc-cache -fv`

## Adding a new tool

```bash
mkdir <toolname>
# mirror $HOME structure inside it, e.g.:
mkdir -p <toolname>/.config/<toolname>
# add config files, then stow:
stow --dir=. --target=$HOME <toolname>
# commit
git add <toolname> && git commit -m "add <toolname> config"
```

## Packages installed (Brewfile)

- **Shell**: `git`, `tree`, `tmux`, `stow`, `ripgrep`, `fd`, `fzf`, `zoxide`, `starship`
- **Editor**: `neovim`
- **Dev/cloud**: `gh`, `awscli`
- **AI**: `opencode`, Claude Code (installed separately via `curl` installer)
