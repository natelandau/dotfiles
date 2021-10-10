# Saner Defaults
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'
alias grep='grep --color=always'
alias cd..='cd ../'
alias ..='cd ../'
alias ...='cd ../../'
alias .3='cd ../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../../'
alias .6='cd ../../../../../../'
alias ~="cd ~"
alias path='echo -e ${PATH//:/\\n}' # system: Echo all executable Paths
alias fix_stty='stty sane'          # system:   Restore terminal settings when screwed up
alias kill='kill -9'
alias ax='chmod a+x'
alias rm='rm -i'
alias rmd='rm -rf'
alias shfmt="shfmt -ci -bn -i 2" # dev: Preferred shellformat implementation

# Prefer `bat` over `cat`
[[ "$(command -v bat)" ]] \
    && alias cat="bat"

# Prefer `prettyping` over `ping`
[[ "$(command -v prettyping)" ]] \
    && alias ping="prettyping --nolegend"

# Prefer `htop` over `top`
[[ "$(command -v htop)" ]] \
    && alias top="htop"

# Custom commands
if [[ ${SHELL##*/} == "bash" ]]; then
    alias sourcea='source ${HOME}/.bash_profile' # system: Source .bash_profile or .zshrc
elif [[ ${SHELL##*/} == "zsh" ]]; then
    alias sourcea='source ${HOME}/.zshrc' # system: Source .bash_profile or .zshrc
fi

mcd() {
    mkdir -pv "$1"
    cd "$1" || exit
}

mkcd() {
    mcd "$1"
}

mine() { ps "$@" -u "$USER" -o pid,%cpu,%mem,start,time,bsdtime,command; }
alias memHogs='ps wwaxm -o pid,stat,vsize,rss,time,command | head -10' # system: show top 10 memory hogs
alias cpuHogs='ps wwaxr -o pid,stat,%cpu,time,command | head -10'      # system: show top 10 cpu hogs

titlebar() { echo -n $'\e]0;'"$*"$'\a'; } # Set the terminal's title bar.

alias sc='shellcheck --exclude=1090,2005,2034,2086,1083,2119,2120,2059,2001,2002,2148,2129,1117' # dev: Preferred shellcheck implementation
