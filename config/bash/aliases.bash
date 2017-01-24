
# Saner Defaults
alias cp='cp -iv'                     # Preferred 'cp' implementation
alias mv='mv -iv'                     # Preferred 'mv' implementation
alias mkdir='mkdir -pv'               # Preferred 'mkdir' implementation
alias grep='grep --color=always'        # Always color grep
alias cd..='cd ../'                   # Go back 1 directory level (for fast typers)
alias ..='cd ../'                     # Go back 1 directory level
alias ...='cd ../../'                 # Go back 2 directory levels
alias .3='cd ../../../'               # Go back 3 directory levels
alias .4='cd ../../../../'            # Go back 4 directory levels
alias .5='cd ../../../../../'         # Go back 5 directory levels
alias .6='cd ../../../../../../'      # Go back 6 directory levelss
alias ~="cd ~"                        # ~:      Go Home
alias path='echo -e ${PATH//:/\\n}'   # path:     Echo all executable Paths
alias showOptions='shopt'             # Show_options: display bash options settings
alias fix_stty='stty sane'            # fix_stty:   Restore terminal settings when screwed up
alias kill='kill -9'                  # kill:     Preferred 'kill' implementation
alias ax='chmod a+x'                  # ax:     Make a file executable
alias less='less -RXcqeN'             # Preferred 'less' implementation
alias more='less'                     # more: use 'less' instead of 'more'
alias top="top -R -F -s 10 -o rsize"

# Two different sets of LS aliases because Gnu LS and macOS LS use different
# flags for colors

if [[ $(which ls) =~ gnubin ]]; then
  alias ll='ls -FlAhp --color=auto'     # Preferred 'ls' implementation
  alias ls="ls --color=auto"
else
  alias ll='ls -FGlAhp'                 # Preferred 'ls' implementation
  alias ls="ls -G"
fi

# Custom commands
mcd () { mkdir -p "$1" ; cd "$1" || exit; }
mine() { ps "$@" -u "$USER" -o pid,%cpu,%mem,start,time,bsdtime,command ; }
alias memHogs='ps wwaxm -o pid,stat,vsize,rss,time,command | head -10'
alias cpuHogs='ps wwaxr -o pid,stat,%cpu,time,command | head -10'
alias sourcea='source ${HOME}/.bash_profile'
titlebar() { echo -n $'\e]0;'"$*"$'\a' ; } # Set the terminal's title bar.


# Use the commands in /bin
if command -v cleanFilenames &> /dev/null; then
  alias clean='cleanFilenames'          # Alias to invoke my clean filenames script
  alias cf="cleanFilenames"
fi

if command -v trash &> /dev/null; then
  alias rm='trash'
  alias rmd='trash'
else
  alias rm='rm -i'
  alias rmd='rm -rf'
fi

# Preferred implementation of shellcheck
# We are excluding a number of errors here.  The list is:
#   - 1090: Can't follow non-constant source.
#   - 2162: Read without -r will mangle backslashes.
#   - 2005: Useless echo? Instead of 'echo $(cmd)', just use 'cmd'.
alias sc='shellcheck --exclude=1090,2162,2005,2034,2154,2086,2155,2181,2164,1083'


