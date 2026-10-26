# Login shells on Ubuntu source .bash_profile, not .bashrc.
# Keep everything in .bashrc and source it from here.

# bun — set before sourcing .bashrc so .bashrc's ~/.local/bin lands ahead of
# ~/.bun/bin on PATH. scripts/.local/bin/qmd overrides bun's qmd shim, which
# can't run without node.
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

[[ -f "$HOME/.bashrc" ]] && source "$HOME/.bashrc"
