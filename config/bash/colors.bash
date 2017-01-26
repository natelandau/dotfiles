# HOW BSD COLORS WORK
# The color designators are as follows:
#   a     black
#   b     red
#   c     green
#   d     brown
#   e     blue
#   f     magenta
#   g     cyan
#   h     light grey
#   A     bold black, usually shows up as dark grey
#   B     bold red
#   C     bold green
#   D     bold brown, usually shows up as yellow
#   E     bold blue
#   F     bold magenta
#   G     bold cyan
#   H     bold light grey; looks like bright white
#   x     default foreground or background

# The order of the attributes are as follows:
#   1.   directory
#   2.   symbolic link
#   3.   socket
#   4.   pipe
#   5.   executable
#   6.   block special
#   7.   character special
#   8.   executable with setuid bit set
#   9.   executable with setgid bit set
#   10.  directory writable to others, with sticky bit
#   11.  directory writable to others, without sticky bit


# Add color to terminal
export CLICOLOR=1
#export LSCOLORS="ExDxCxDxCxegedabagacad"
#export LSCOLORS="GxFxCxDxBxegedabagaced"
#export LSCOLORS="ExFxBxDxCxegedabagacad"
export LSCOLORS="GxFxCxDxCxegedabagaced"
# LESS man page colors
# export LESS_TERMCAP_mb=$'\E[01;31m'
# export LESS_TERMCAP_md=$'\E[01;31m'
# export LESS_TERMCAP_me=$'\E[0m'
# export LESS_TERMCAP_se=$'\E[0m'
# export LESS_TERMCAP_so=$'\E[01;44;33m'
# export LESS_TERMCAP_ue=$'\E[0m'
# export LESS_TERMCAP_us=$'\E[01;32m'

if [[ $COLORTERM = gnome-* && $TERM = xterm ]] && infocmp gnome-256color >/dev/null 2>&1; then
  export TERM=gnome-256color
elif infocmp xterm-256color >/dev/null 2>&1; then
  export TERM=xterm-256color
else
  export TERM=xterm-256color
fi

if tput setaf 1 &> /dev/null; then
tput sgr0
if [[ $(tput colors) -ge 256 ]] 2>/dev/null; then
  MAGENTA=$(tput setaf 9)
  ORANGE=$(tput setaf 172)
  GREEN=$(tput setaf 190)
  PURPLE=$(tput setaf 141)
  WHITE=$(tput setaf 15)
  YELLOW=$(tput setaf 3)
  BLUE=$(tput setaf 38)
  RED=$(tput setaf 1)
  BLACK=$(tput setaf 233)
else
  MAGENTA=$(tput setaf 5)
  ORANGE=$(tput setaf 4)
  GREEN=$(tput setaf 2)
  PURPLE=$(tput setaf 1)
  WHITE=$(tput setaf 7)
  YELLOW=$(tput setaf 3)
  BLUE=$(tput setaf 38)
  RED=$(tput setaf 1)
  BLACK=$(tput setaf 8)
fi
  BOLD=$(tput bold)
  RESET=$(tput sgr0)
  UNDERLINE=$(tput sgr 0 1)
else
  MAGENTA="\033[1;31m"
  ORANGE="\033[1;33m"
  GREEN="\033[1;32m"
  PURPLE="\033[1;35m"
  WHITE="\033[1;37m"
  YELLOW="\033[0;33m"
  BLUE="\033[0;34m"
  RED="\033[0;31m"
  BLACK="\033[0;30m"
  BOLD=""
  UNDERLINE=""
  RESET="\033[m"
fi

#Backgrounds
BACKORANGE=$(tput setab 172)
BACKMAGENTA=$(tput setab 9)
BACKORANGE=$(tput setab 172)
BACKGREEN=$(tput setab 190)
BACKPURPLE=$(tput setab 141)
BACKWHITE=$(tput setab 15)
BACKYELLOW=$(tput setab 3)
BACKBLUE=$(tput setab 38)
BACKRED=$(tput setab 1)

export MAGENTA
export ORANGE
export GREEN
export PURPLE
export WHITE
export YELLOW
export BLUE
export RED
export BLACK
export UNDERLINE
export BOLD
export RESET
export BACKORANGE
export BACKMAGENTA
export BACKORANGE
export BACKGREEN
export BACKPURPLE
export BACKWHITE
export BACKYELLOW
export BACKBLUE
export BACKRED