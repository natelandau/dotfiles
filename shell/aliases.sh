# Saner Defaults
alias cp='cp -iv'                   # Preferred 'cp' implementation
alias mv='mv -iv'                   # Preferred 'mv' implementation
alias mkdir='mkdir -pv'             # Preferred 'mkdir' implementation
alias grep='grep --color=always'    # Always color grep
alias cd..='cd ../'                 # Go back 1 directory level (for fast typers)
alias ..='cd ../'                   # Go back 1 directory level
alias ...='cd ../../'               # Go back 2 directory levels
alias .3='cd ../../../'             # Go back 3 directory levels
alias .4='cd ../../../../'          # Go back 4 directory levels
alias .5='cd ../../../../../'       # Go back 5 directory levels
alias .6='cd ../../../../../../'    # Go back 6 directory levelss
alias ~="cd ~"                      # ~:      Go Home
alias path='echo -e ${PATH//:/\\n}' # path:     Echo all executable Paths
alias fix_stty='stty sane'          # fix_stty:   Restore terminal settings when screwed up
alias kill='kill -9'                # kill:     Preferred 'kill' implementation
alias ax='chmod a+x'                # ax:     Make a file executable
alias rm='rm -i'
alias rmd='rm -rf'
alias shfmt="shfmt -ci -bn -i 2" # preferred shellformat implementation

# Prefer `bat` over `cat`
[[ "$(command -v bat)" ]] \
    && alias cat="bat"

# Prefer `prettyping` over `ping`
[[ "$(command -v prettyping)" ]] \
    && alias ping="prettyping --nolegend"

# Prefer we like TLDR
[[ "$(command -v tldr)" ]] \
    && alias help="tldr"

# Prefer `htop` over `top`
[[ "$(command -v htop)" ]] \
    && alias top="htop"

# Custom commands
[[ ${SHELL##*/} == "bash" ]] \
    && alias sourcea='source ${HOME}/.bash_profile'
[[ ${SHELL##*/} == "zsh" ]] \
    && alias sourcea='source ${HOME}/.zshrc'

mcd() {
    mkdir -pv "$1"
    cd "$1" || exit
}

mkcd() {
    mcd "$1"
}

mine() { ps "$@" -u "$USER" -o pid,%cpu,%mem,start,time,bsdtime,command; }
alias memHogs='ps wwaxm -o pid,stat,vsize,rss,time,command | head -10'
alias cpuHogs='ps wwaxr -o pid,stat,%cpu,time,command | head -10'

titlebar() { echo -n $'\e]0;'"$*"$'\a'; } # Set the terminal's title bar.

# Use the scripts in /bin
if command -v cleanFilenames &>/dev/null; then
    alias cf="cleanFilenames" # Alias to invoke my clean filenames script
fi

# Preferred implementation of shellcheck
alias sc='shellcheck --exclude=1090,2005,2034,2086,1083,2119,2120,2059,2001,2002,2148,2129,1117'
