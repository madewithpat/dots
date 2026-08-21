# Shared shell config (bash + zsh)

path_add() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in
  *":$1:"*) ;;
  *) PATH="$1:$PATH" ;;
  esac
}

path_add "$HOME/.local/bin"
path_add "$HOME/bin"

export EDITOR="${EDITOR:-vim}"
export PAGER="${PAGER:-less}"
