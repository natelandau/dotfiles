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
alias kill='kill -9'
alias rm='rm -i'
alias rmd='rm -rf'
alias ax='chmod a+x'                      # system: make file executable
alias path='echo -e ${PATH//:/\\n}'       # system: Echo all executable Paths
alias shfmt="shfmt -ci -bn -i 2"          # dev: Preferred shellformat implementation
alias sc='shellcheck --exclude=2001,2148' # dev: Preferred shellcheck implementation

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

alias memHogs='ps wwaxm -o pid,stat,vsize,rss,time,command | head -10' # system: Show top 10 memory hogs
alias cpuHogs='ps wwaxr -o pid,stat,%cpu,time,command | head -10'      # system: Show top 10 cpu hogs
mine() {
    # system: Show all processes owned by user
    ps "$@" -u "${USER}" -o pid,%cpu,%mem,start,time,bsdtime,command
}
