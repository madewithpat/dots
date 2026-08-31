# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).
Target: Linux VMs (Ubuntu, bash) **and** this Mac (macOS, zsh) — see PLAN.md
for the full rationale and OS-conditional package selection.

## Quick start (new machine)

```bash
git clone git@github.com:madewithpat/dots.git ~/dots && ~/dots/bootstrap.sh
```

`bootstrap.sh` is idempotent — safe to re-run.

## What's managed

| Package  | Config                          | Scope |
|----------|----------------------------------|-------|
| `git`    | `~/.gitconfig` (identity comes from `~/.gitconfig.local`, `~/.mwp.gitconfig`, etc. — see [Machine-local overrides](#machine-local-overrides)) | universal |
| `shell-common` | `~/.config/shell/common.sh`, `common-interactive.sh` | universal |
| `bash`   | `~/.bashrc`, `~/.bash_profile`  | Linux |
| `zsh`    | `~/.zshrc`                       | macOS |
| `tmux`   | `~/.tmux.conf`                  | universal |
| `starship` | `~/.config/starship.toml`     | universal |
| `nvim`   | `~/.config/nvim/` (LazyVim)     | universal |
| `claude` | `~/.claude/settings.json`, `statusline-command.sh`, `file-suggestion.sh` | universal |
| `ornith` | `~/.local/bin/ornith` (+ 2 helper scripts), `~/Library/LaunchAgents/com.mwp.llama-server-ornith.plist` | macOS (this Mac only — the local LLM server) |
| `omp`    | `~/.omp/agent/models.yml` — registers `ornith-local` at `localhost:11434`, not default | macOS |
| `dvc`    | `~/.local/bin/dvc`, `~/.config/dvc/config.json` — profile-based devcontainer wrapper (`dvc build/up/exec/shell/status/...`); named `dvc` not `dc` since `/usr/bin/dc` (the calculator) already owns that name. Ported from work-dots' `dc` package — `bootstrap`/`doctor` subcommands are wired but inert until the matching `devcontainer/` package is also ported. | universal |

`shell-common` and `bash`/`zsh` are independent axes — see PLAN.md
Conventions. `stow.sh` picks the right set for `$(uname)` automatically;
override with explicit package names when you want a partial apply.

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

These files are gitignored (or, for `.mwp.gitconfig`/`.tm.gitconfig`, simply never shipped by this repo) and never committed:

| File | Purpose |
|------|---------|
| `~/.gitconfig.local` | Default git identity (`[user]` name/email/signingkey) + any `[url "..."] insteadOf` SSH host-alias rewrites for your employer/client GitHub orgs — these name real orgs, so they don't belong in a public repo |
| `~/.mwp.gitconfig`, `~/.tm.gitconfig`, ... | Directory-scoped identity overrides, targeted by `git/.gitconfig`'s `includeIf "gitdir:**/<name>/"` blocks. Same shape as `~/.gitconfig.local`'s `[user]` section, one file per identity you need. Not shipped by this repo (they'd carry real emails) — create the ones you need locally. |
| `~/.bashrc.local` | Machine-specific shell config, extra PATH entries, etc. |

`~/.gitconfig.local` (this repo's `[gpg]`/`[commit]` config expects SSH-format commit signing, so `signingkey` is required unless you also set `commit.gpgsign = false` locally):

```ini
[user]
    name = Your Name
    email = you@example.com
    signingkey = ~/.ssh/your_key.pub

[url "git@gh-someorg:someorg"]
    insteadOf = git@github.com:someorg
```

A directory-scoped override (e.g. `~/.mwp.gitconfig`, matched by `[includeIf "gitdir:**/mwp/"]`) has the same `[user]` shape, no `[url]` section needed.

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
