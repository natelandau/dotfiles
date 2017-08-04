# Two different sets of LS aliases because Gnu LS and macOS LS use different
# flags for colors

if command -v exa &>/dev/null; then
  alias ls="ls --color=auto"
  alias ll="exa -alh --git"
elif [[ $(which ls) =~ gnubin || "$OSTYPE" =~ linux ]]; then
  alias ls="ls --color=auto"
  alias ll='ls -FlAhp --color=auto'
else
  alias ls="ls -G"
  alias ll='ls -FGlAhp'
fi

# Show directory stack
alias d="dirs -v -l"

# Change to location in stack bu number
alias 1="pushd"
alias 2="pushd +2"
alias 3="pushd +3"
alias 4="pushd +4"
alias 5="pushd +5"
alias 6="pushd +6"
alias 7="pushd +7"
alias 8="pushd +8"
alias 9="pushd +9"

# Clone this location
alias pc="pushd \$(pwd)"

# Push new location
alias pu="pushd"

# Pop current location
alias po="popd"

function dirsHelp() {
  echo "Directory Navigation Alias Usage"
  echo
  echo "Use the power of directory stacking to move"
  echo "between several locations with ease."
  echo
  echo "d   : Show directory stack."
  echo "po  : Remove current location from stack."
  echo "pc  : Adds current location to stack."
  echo "pu <dir>: Adds given location to stack."
  echo "1 : Chance to stack location 1."
  echo "2 : Chance to stack location 2."
  echo "3 : Chance to stack location 3."
  echo "4 : Chance to stack location 4."
  echo "5 : Chance to stack location 5."
  echo "6 : Chance to stack location 6."
  echo "7 : Chance to stack location 7."
  echo "8 : Chance to stack location 8."
  echo "9 : Chance to stack location 9."
}

# ADD BOOKMARKing functionality
# usage:

if [ ! -f ~/.dirs ]; then  # if doesn't exist, create it
  touch ~/.dirs
else
  source ~/.dirs
fi

alias L='cat ~/.dirs'


G () {
  # goes to destination dir otherwise, stay in the dir
  # example '$ G ..'
  cd "${1:-$(pwd)}" ;
}

S () {
  # 'save a bookmark'
  # example '$ S mybkmrk'

  [[ $# -eq 1 ]] || { echo "${FUNCNAME[0]} function requires 1 argument"; return 1; }

  sed "/${*}/d" ~/.dirs > ~/.dirs1;
  echo "${*}=\"$(pwd)\"" >> ~/.dirs;
  source ~/.dirs ;
}

R () {
  # 'remove a bookmark'
  # example '$ R mybkmrk'

  [[ $# -eq 1 ]] || { echo "${FUNCNAME[0]} function requires 1 argument"; return 1; }

  sed "/$*/d" ~/.dirs > ~/.dirs1;
}

alias U='source ~/.dirs'  # Update BOOKMARK stack

# set the bash option so that no '$' is required when using the above facility
shopt -s cdable_vars