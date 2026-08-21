# Dotfiles Plan

**Approach:** GNU Stow
**Target:** Linux VMs (Ubuntu — workstation, homelab agents, batcave) **and** this Mac (macOS/Darwin, personal daily driver)
**Shell:** bash (Linux) + zsh (macOS) — shell choice and OS are independent axes, not the same branch (see Conventions)
**Tools managed:** see Packages section below

---

## Background

This repo already provisioned batcave (10.0.0.159) and is stow-based. A separate tool, chezmoi (`madewithpat/dotfiles.git`), had been covering a narrow slice of this Mac's config (git identity, shared shell snippets) but was going stale from under-use. Decision: consolidate everything onto this repo, retire chezmoi entirely (unstow locally, archive the repo — last step, not first), and extend the package set to cover this Mac's daily-driver config, which chezmoi never reached (`~/.config/nvim`, `.zshrc`).

Compared chezmoi, GNU Stow, and a bare git repo (`git --bare` + work-tree trick) before deciding. Chezmoi's strengths (per-machine templating, secrets injection) don't pay for themselves here — no secrets live in these dotfiles, and OS/shell branching is handled fine by a bootstrap script picking which packages to stow. Bare-repo is arguably simpler still (zero abstraction, files live at their real paths) but has no natural unit of "apply this bundle or don't," which stow's package model gives for free — a real requirement given the batcave/Mac split. Already fluent in stow via `work-dots` (the separate, unrelated WSL2/work-machine repo) was also a factor — one pattern to hold in memory, not two.

**Batcave safety**: confirmed batcave has no auto-pull or auto-restow mechanism (no crontab, no relevant systemd timer). Changes pushed here only reach batcave if someone manually SSHes in and re-runs the bootstrap there. Nothing in this plan can break batcave by accident — it can only be affected by a deliberate, later re-apply.

---

## Directory Structure

```
dots/
├── PLAN.md                   # this file
├── README.md                 # usage, onboarding a new machine
├── Brewfile                  # brew bundle manifest (brew-installable tools)
├── npm-globals.txt           # global npm packages, one per line
├── bun-globals.txt           # global bun packages, one per line
├── bootstrap.sh              # entry point: install deps, run stow
├── packages.sh               # install tools via brew bundle + the manifests above
├── stow.sh                   # wrapper: simulate or apply stow packages, OS-aware
│
├── git/                      # stow package — universal
│   └── .gitconfig            # multi-identity (includeIf per work dir), SSH URL
│                              # rewrites, git-lfs, aliases — ported from this
│                              # Mac's real config, supersedes the old
│                              # single-identity placeholder
│
├── shell-common/             # stow package — universal, sourced by both bash and zsh
│   └── .config/shell/
│       ├── common.sh              # PATH additions, EDITOR/PAGER
│       └── common-interactive.sh  # ll/la/l, gs/gd/gl, lab-fix-term aliases
│                              # ported from chezmoi's .config/shell/*
│
├── bash/                     # stow package — Linux
│   └── .bashrc               # sources shell-common
│
├── zsh/                      # stow package — macOS (portable in principle;
│   └── .zshrc                # only actually deployed on this Mac for now).
│                              # No Mac-specific hardcoding — Homebrew path
│                              # detection lives in one shared conditional,
│                              # same pattern bootstrap.sh already uses.
│                              # Sources shell-common.
│
├── tmux/                     # stow package — universal
│   └── .tmux.conf
│
├── starship/                 # stow package — universal
│   └── .config/starship.toml
│
├── claude/                   # stow package — universal
│   └── .claude/
│       ├── settings.json         # ported from this Mac's live config —
│       │                          # includes fileSuggestion, model, tui,
│       │                          # effortLevel that the old version lacked
│       └── statusline-command.sh
│
├── nvim/                     # stow package — universal
│   └── .config/nvim/         # replaced with the full LazyVim config built
│                              # this session (obsidian.nvim, render-markdown,
│                              # Snacks.image/picker, checkbox keymaps) —
│                              # supersedes the bare LazyVim skeleton that
│                              # was here (empty lua/plugins/, one-line
│                              # init.lua)
│
├── ornith/                    # stow package — macOS only, this Mac specifically
│   ├── .local/bin/
│   │   ├── ornith                        # start/stop/status/config CLI —
│   │   │                                  # relocated 2026-08-21 from the
│   │   │                                  # second-brain vault's .scripts/
│   │   │                                  # (was ornith-ctl.sh there)
│   │   ├── llama-server-ornith-wrapper.sh # invoked by the launchd plist below
│   │   └── ollama-ornith-setup.sh         # one-time/occasional model pull
│   └── Library/LaunchAgents/
│       └── com.mwp.llama-server-ornith.plist  # ProgramArguments now points
│                                                # at the stowed $HOME path,
│                                                # not the vault
│
├── omp/                       # stow package — macOS only
│   └── .omp/agent/models.yml  # registers ornith-local at localhost:11434 —
│                               # available, not default (mirrors work-dots'
│                               # precedent, which reaches the same server
│                               # over the LAN instead)
│
└── macos/                    # stow package — macOS only
    └── (TBD — genuinely Mac-only config; scope not yet finalized, see
        Open Questions. `libpq` PATH export currently lives inline in
        zsh/.zshrc — flagged there as a candidate for this package.)
```

Each top-level folder is a **stow package** — a logical grouping of one tool's config. Stow symlinks the contents into `$HOME`, preserving directory structure.

**Deferred packages** (not in initial setup):
- `asdf/` — runtime version management; defer until there's a clear need for per-project language versions

---

## Conventions

- **Shell and OS are independent axes.** A package's OS-scope (universal / Linux-only / macOS-only) is not the same thing as shell choice (bash / zsh). zsh is genuinely portable to Linux (`apt install zsh`) — the `zsh` package itself should stay free of Mac-specific assumptions. What *is* OS-locked (Homebrew's path, `pngpaste`, launchd vs. systemd, Ghostty) belongs in `macos` (or a future Linux-only equivalent), not baked into the shell package boundary.
- **What lives in the repo**: config files only — no secrets, no machine-specific values.
- **What doesn't**: API keys, tokens, SSH keys, anything in `~/.secrets/` or `.env` files.
- **Per-machine overrides**: use a local include pattern where the tool supports it (e.g., `~/.gitconfig.local` included from `.gitconfig`).
- **Shell init order**: keep `.zshrc`/`.bashrc` clean — source `shell-common` first, then tool inits (starship, homebrew, fnm) in a predictable, documented order.
- Don't rely on stow-specific features or symlink tricks inside config files.
- Keep configs self-contained — no hardcoded absolute paths like `/Users/patrick/...` or `/home/patrick/...`. Use `$HOME`, `$XDG_CONFIG_HOME`, and relative paths throughout.

---

## Bootstrap Flow (new machine)

1. **Pre-flight**: check for and back up any existing dotfiles (`~/.gitconfig.bak`, etc.) — already idempotent in `bootstrap.sh`.
2. **Install Homebrew**: existing Darwin/Linux branch in `bootstrap.sh` already handles both paths (`/opt/homebrew` vs. `/home/linuxbrew/.linuxbrew`).
3. **Install packages** via `packages.sh`:
   - `brew bundle --file=./Brewfile`
   - `xargs npm install -g < npm-globals.txt`
   - `xargs -I{} bun install -g {} < bun-globals.txt`
4. **Install curl-pipe tools** (idempotent, `command -v` guarded — same pattern already used for Claude Code):
   - Claude Code: `curl -fsSL https://claude.ai/install.sh | bash` (already present)
   - bun: `curl -fsSL https://bun.sh/install | bash` (new)
5. **Determine OS-appropriate package set** (new — see Stow Usage) and dry-run: `./stow.sh --simulate`
6. **Apply stow**: `./stow.sh`
7. **Source shell config**: `source ~/.zshrc` (macOS) or `source ~/.bashrc` (Linux)

**Explicitly deferred, not in this pass**: `uv`/`uvx` and the `zmk` uv-tool install. `uv` may be worth capturing later if a real need shows up; not currently load-bearing for anything in daily use, easy to add when it is.

---

## Packages (Brewfile + global-package manifests)

**Brewfile — QoL / shell tools**
- `git`, `tree`, `tmux`, `stow`
- `ripgrep` (rg), `fd`, `fzf`, `zoxide`
- `starship`

**Brewfile — Neovim + LazyVim stack**
- `neovim`
- `ripgrep`, `fd`, `fzf` (shared with above — listed once)
- Nerd Fonts (cask — on Linux, install manually from nerd-fonts releases; note in README)

**Brewfile — Dev / cloud tools**
- `gh` (GitHub CLI)
- `awscli`

**Brewfile — AI tools**
- `opencode`
- Claude Code and bun — installed via their official curl installers, not brew (see Bootstrap Flow)

**`npm-globals.txt`**
- Currently near-empty in practice — `tree-sitter-cli` and `@mermaid-js/mermaid-cli` are installed on this Mac but orphaned (were for the now-removed Mermaid rendering support). Open question below: carry them into the manifest as-is, or start clean.

**`bun-globals.txt`**
- `@tobilu/qmd` — load-bearing. This is the vault search tool; `CLAUDE.md`'s Auto-Retrieve workflow depends on it being present. A machine bootstrapped without this manifest entry would look fully set up but have silently broken vault retrieval.

**Future (not in initial Brewfile)**
- `asdf` — deferred
- `uv` — deferred, see Bootstrap Flow

> **On native installers**: the Brewfile (and the npm/bun manifests) track what you want reproducible across machines. If you prefer a native installer for something, skip it here and document the manual step in README instead.

---

## Stow Usage

```bash
# Simulate (dry run — always run this first on a new machine)
stow --simulate --dir=. --target=$HOME <packages...>

# Apply
stow --dir=. --target=$HOME <packages...>

# Remove a package's symlinks (un-stow)
stow --delete --dir=. --target=$HOME <package>
```

### OS-conditional package selection (new)

`stow.sh` needs a Darwin/Linux branch choosing the default package set, since `bash`/`zsh` and `macos` shouldn't both apply everywhere:

```bash
UNIVERSAL=(git shell-common tmux starship claude nvim)
case "$(uname)" in
  Darwin) PACKAGES=("${UNIVERSAL[@]}" zsh macos) ;;
  Linux)  PACKAGES=("${UNIVERSAL[@]}" bash) ;;
esac
```

Still overridable positionally (`./stow.sh git nvim`) for partial applies, same as today.

### Conflict resolution (before first run on a new machine)

For any existing file that conflicts, move it out of the way (or let `bootstrap.sh`'s pre-flight step do it automatically):
```bash
mv ~/.gitconfig ~/.gitconfig.bak
# then run stow
```

---

## Adding New Tools

1. Create a new folder at the top level: `mkdir <toolname>`
2. Mirror the `$HOME` path inside it: e.g., `<toolname>/.config/<toolname>/config.toml`
3. Decide its OS scope — universal, or add it to the Darwin/Linux branch in `stow.sh`
4. Stow it: `stow --dir=. --target=$HOME <toolname>`
5. Commit the new package

---

## Migration from chezmoi (in progress)

chezmoi (`madewithpat/dotfiles.git`) previously managed a narrow slice of this Mac: `.gitconfig`/`.mwp.gitconfig`/`.tm.gitconfig`, `.config/shell/common.sh` + `common-interactive.sh`, `CLAUDE.md`, `README.md`, one docs spec. Being retired in favor of full consolidation here.

**Order matters** — content flows *from* this Mac's live config *into* this repo first, not the reverse, since this Mac's real files are more complete than what was already in this repo for `git` and `claude` (see Directory Structure notes above). Sequence:

1. ✅ Branch (`plan-mac-consolidation`) — done, this plan update lives here first.
2. ✅ Port this Mac's real `.gitconfig` (+ `.mwp.gitconfig`/`.tm.gitconfig`), `.claude/settings.json` (+ `file-suggestion.sh`, not previously in the repo), and chezmoi's shell-common files into their respective packages.
3. ✅ Add the `zsh` package.
4. ✅ Replace the `nvim` package wholesale with this session's LazyVim config.
5. ✅ Add the OS-conditional branch to `stow.sh`, add `npm-globals.txt`/`bun-globals.txt` + their bootstrap/packages.sh steps, add the `bun` curl-installer step.
6. ✅ Add the `ornith` package (relocated from the second-brain vault's `.scripts/` — see Directory Structure) and the `omp` package (`ornith-local` provider pointed at `localhost:11434`, registered not default). Both macOS-only in `stow.sh`.
7. ⬜ `stow --simulate` on this Mac, review the full diff, before applying anything for real. **Not yet run** — packages 2–6 above are built in the repo but not yet applied to this Mac's live `$HOME`, except `ornith` (relocated + live-verified 2026-08-21, see activity log) and `omp` (applied — inert, `~/.omp` didn't previously exist).
8. ⬜ Only once the above is confirmed working: remove chezmoi's deployed files locally, uninstall/stop using chezmoi, archive `madewithpat/dotfiles` on GitHub.

**What chezmoi's own strengths would have offered, and why they're not needed**: per-machine templating (not needed — OS/shell branching handled by `stow.sh`'s conditional package selection) and secrets injection (not needed — no secrets live in these dotfiles by convention; per-machine identity already handled via gitignored local includes like `.gitconfig.local`).

---

## Open Questions (decide before implementing)

- **`macos` package scope**: what actually goes here? Candidates: Ghostty config, anything using `pngpaste`, the `libpq` PATH export currently inline in `zsh/.zshrc`. Needs a real inventory pass, not yet done.
- **Git aliases**: finalized list beyond what's in the ported `.gitconfig`?
- **Nerd Fonts on Linux**: brew casks don't work on Linux — manual install from nerd-fonts releases, or a small script in `bootstrap.sh`? Document clearly in README either way.
- **`.bashrc` vs `.bash_profile`**: on Ubuntu, interactive login shells source `.bash_profile`; non-login interactive shells source `.bashrc`. Decide on the split before touching the `bash` package (currently untouched by this consolidation — Linux-side only).

**Resolved:**
- Approach: GNU Stow, not chezmoi or bare-repo ✓
- Shell/OS as independent axes, not one branch ✓
- Scope: Linux VMs (existing) + this Mac (new) ✓
- Git identity: full multi-identity config, ported from this Mac, not the old single-identity placeholder ✓
- Claude settings: ported from this Mac's live config ✓
- Nvim: replaced wholesale with this session's LazyVim build ✓
- Toolchain-outside-brew: bun + Claude Code curl-installers, npm/bun global manifests — in scope; uv/zmk — deferred ✓
- Batcave risk: confirmed no auto-sync mechanism exists; nothing here can affect it without a deliberate manual re-apply ✓
- asdf: deferred ✓
- Brewfile: yes ✓
- `npm-globals.txt` starting contents: started clean (empty) — `tree-sitter-cli`/`@mermaid-js/mermaid-cli` are orphaned from the removed Mermaid work, not carried forward. Add back if a real need shows up ✓
- `bun-globals.txt` versioning: tracking latest (`@tobilu/qmd`, unpinned) — simpler, matches how it's actually installed today. Revisit pinning only if drift causes a real problem ✓
- `ornith` package: the 3 control/serving scripts + the launchd plist moved from the second-brain vault's `.scripts/` into this repo (2026-08-21) — decided over leaving them in the vault, since PLAN.md's own "no hardcoded vault paths" convention would otherwise be violated by the alias and the plist ✓
- `omp` default: `ornith-local` registered as an available provider, not the default — mirrors the work-dots precedent exactly, lower-surprise ✓
