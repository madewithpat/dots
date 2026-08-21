# Shared config
[ -f "$HOME/.config/shell/common.sh" ] && source "$HOME/.config/shell/common.sh"
[ -f "$HOME/.config/shell/common-interactive.sh" ] && source "$HOME/.config/shell/common-interactive.sh"


eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=("$HOME/.docker/completions" $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

# fnm setup
eval "$(fnm env --use-on-cd)"

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section

export EDITOR=nvim
export COLORTERM=truecolor

. "$HOME/.local/bin/env"

fpath+=~/.zfunc; autoload -Uz compinit; compinit

zstyle ':completion:*' menu select

alias tmux-help="cat ~/.config/tmux/cheatsheet"

if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
  source "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration"
  [[ -n $TMUX ]] && export TERM_PROGRAM=ghostty
fi

# ── fzf ──────────────────────────────────────────────────────────────────────
if command -v fzf &>/dev/null; then
  eval "$(fzf --zsh)"
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

# Claudesidian launcher - auto-generated
alias claudesidian='(cd "$HOME/src/second-brain" && (claude --resume 2>/dev/null || claude))'

# timekeeping vars
export TIMEKEEPING_BW_ITEM="c718552e-2a4a-4344-8fa4-b46401024006"
alias bwunlock='export BW_SESSION=$(bw unlock --raw)'

# direnv hook
eval "$(direnv hook zsh)"

# ── yazi ──────────────────────────────────────────────────────────────────────
if command -v yazi &>/dev/null; then
  function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    command rm -f -- "$tmp"
  }
fi

alias sp='sesh-picker'

# Hermes Agent — ensure ~/.local/bin is on PATH
export PATH="$HOME/.local/bin:$PATH"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# libpq is keg-only (not linked by brew) — TODO: candidate for a future
# macos-only package once that package's scope is decided (see PLAN.md).
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# Ornith-1.5-35B local LLM server control now lives in the `ornith` package
# (~/.local/bin/ornith, already on PATH above) — no alias needed here.
