# Shared interactive config (bash + zsh)

# Safer default ls coloring where supported (no-op if unsupported)
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# git shortcuts
alias g='git'
alias gs='git st'
alias gf='git fetch'
alias gd='git diff'
alias gc='git commit'
alias gp='git push'
alias gl='git lg'

# lab
alias lab-fix-term='infocmp -x | ssh wk "tic -x /dev/stdin" && infocmp -x | ssh hermes "tic -x /dev/stdin"'
