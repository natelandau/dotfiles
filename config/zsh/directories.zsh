# Different sets of LS aliases because Gnu LS and macOS LS use different
# flags for colors.  Also, prefer gem colorls or exa when available.

if command -v exa &>/dev/null; then
  #alias ls="ls --color=auto"
  alias ll="exa -alh --git"
elif command -v colorls &>/dev/null; then
  alias ll="colorls -1A --git-status"
  alias ls="colorls -A"
  alias lll="exa -alh --git"
elif [[ $(command -v ls) =~ gnubin || "$OSTYPE" =~ linux ]]; then
  alias ls="ls --color=auto"
  alias ll='ls -FlAhp --color=auto'
else
  alias ls="ls -G"
  alias ll='ls -FGlAhp'
fi

cd() {
  builtin cd "$@"
  ll
}