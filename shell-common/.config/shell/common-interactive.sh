# Shared interactive config (bash + zsh)

# eza-backed listings where eza is installed (Brewfile); plain ls otherwise.
if command -v eza >/dev/null 2>&1; then
  # eza 0.23+ reads a non-terminal stdin as its list of paths, so a bare `eza`
  # prints nothing under agents, scripts, and CI (eza-community/eza#1568).
  # There, list `.` unless a path argument is given. The word after a flag that
  # requires a value (-L 2, -I foo, -s size) is not a path; give optional
  # values with `=` (--color=never).
  _eza() {
    if [ ! -t 0 ]; then
      local arg is_value=
      for arg in "$@"; do
        if [ -n "$is_value" ]; then
          is_value=
          continue
        fi
        case "$arg" in
          --level | --width | --ignore-glob | --sort | --time | --time-style | \
            --color-scale-mode | -[LwIst] | -[!-]*[LwIst])
            is_value=1
            ;;
          -*) ;;
          *)
            command eza "$@"
            return
            ;;
        esac
      done
      set -- "$@" .
    fi
    command eza "$@"
  }

  alias ll='_eza -la --group-directories-first'
  alias la='_eza -a --group-directories-first'

  # List Tree: hidden files, type markers, directories first, one level deep,
  # skipping .git and anything gitignored. A leading number sets the depth:
  # `lst 3 src` shows three levels of src.
  lst() {
    local level=1
    case "${1:-}" in
      '' | *[!0-9]*) ;;
      *)
        level="$1"
        shift
        ;;
    esac
    _eza --tree --level="$level" -a --group-directories-first \
      --classify=always --git-ignore "$@"
  }
else
  alias ll='ls -alF'
  alias la='ls -A'
fi
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
