# ── Guard: non-interactive shells get nothing ─────────────────────────────────
[[ $- != *i* ]] && return

# ── Homebrew (Linuxbrew) ──────────────────────────────────────────────────────
if [[ -d /home/linuxbrew/.linuxbrew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -d /usr/local/Homebrew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ── PATH additions ────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

# ── History ───────────────────────────────────────────────────────────────────
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
HISTIGNORE='ls:ll:la:cd:pwd:exit:history'
shopt -s histappend
PROMPT_COMMAND='history -a'

# ── Shell options ─────────────────────────────────────────────────────────────
shopt -s checkwinsize
shopt -s globstar
shopt -s cdspell
shopt -s dirspell

# ── Editor ────────────────────────────────────────────────────────────────────
export EDITOR=nvim
export VISUAL=nvim

# ── fzf ──────────────────────────────────────────────────────────────────────
if command -v fzf &>/dev/null; then
  eval "$(fzf --bash)"
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

# ── zoxide ────────────────────────────────────────────────────────────────────
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash)"
fi

# ── starship prompt ───────────────────────────────────────────────────────────
if command -v starship &>/dev/null; then
  eval "$(starship init bash)"
fi

# ── Aliases ───────────────────────────────────────────────────────────────────
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias mkdir='mkdir -p'
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# git shorthand (beyond what's in .gitconfig)
alias g='git'
alias gs='git st'
alias gd='git diff'
alias gc='git commit'
alias gp='git push'
alias gl='git lg'

# ── Local overrides (machine-specific, not committed) ─────────────────────────
[[ -f "$HOME/.bashrc.local" ]] && source "$HOME/.bashrc.local"
