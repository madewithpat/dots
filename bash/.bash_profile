# Login shells on Ubuntu source .bash_profile, not .bashrc.
# Keep everything in .bashrc and source it from here.
[[ -f "$HOME/.bashrc" ]] && source "$HOME/.bashrc"
