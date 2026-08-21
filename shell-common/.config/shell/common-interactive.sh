# Shared interactive config (bash + zsh)

# Safer default ls coloring where supported (no-op if unsupported)
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# git shortcuts
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --decorate --graph'

# lab
alias lab-fix-term='infocmp -x | ssh wk "tic -x /dev/stdin" && infocmp -x | ssh hermes "tic -x /dev/stdin"'
