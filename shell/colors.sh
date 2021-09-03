showcolors() {
    # will print all tput colors to terminal
    local x y i os
    (
        x=$(tput op) y=$(printf %$((COLUMNS - 6))s)
        for i in {0..256}; do
            o=00$i
            echo -e ${o:${#o}-3:3} "$(
                tput setaf $i
                tput setab $i
            )"${y// /=}$x
        done
    )
}

mycolors() {
    echo "${underline} This is underlined text ${reset}"
    echo "${reverse} This is reversed text ${reset}"
    echo "${gray} This is gray text${reset}"
    echo "${white} This is white text ${reset}"
    echo "${bold} This is bold text ${reset}"
    echo "${blue} This is blue text ${reset}"
    echo "${yellow} This is yellow text"
    echo "${purple} This is purple text${reset}"
    echo "${red} This is red text ${reset}"
    echo "${green} This is green text${reset}"

    echo "${white}${reverse} This is white reversed text ${reset}"
    echo "${gray}${reverse} This is gray reversed text${reset}"
    echo "${blue}${reverse} This is blue reversed text ${reset}"
    echo "${yellow}${reverse} This is yellow reversed text"
    echo "${purple}${reverse} This is purple reversed text${reset}"
    echo "${red}${reverse} This is red reversed text ${reset}"
    echo "${green}${reverse} This is green reversed text${reset}"
}

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

if [[ $COLORTERM == gnome-* && $TERM == xterm ]] && infocmp gnome-256color >/dev/null 2>&1; then
    export TERM=gnome-256color
elif infocmp xterm-256color >/dev/null 2>&1; then
    export TERM=xterm-256color
else
    export TERM=xterm-256color
fi

# Set colors
_setColors_() {
    # DESC: Sets colors use for alerts.
    # ARGS:		None
    # OUTS:		None
    # USAGE:  echo "${blue}Some text${reset}"

    if tput setaf 1 &>/dev/null; then
        bold=$(tput bold)
        underline=$(tput smul)
        reverse=$(tput rev)
        reset=$(tput sgr0)

        if [[ $(tput colors) -ge 256 ]] 2>/dev/null; then
            white=$(tput setaf 231)
            blue=$(tput setaf 38)
            yellow=$(tput setaf 11)
            tan=$(tput setaf 3)
            green=$(tput setaf 82)
            red=$(tput setaf 1)
            purple=$(tput setaf 171)
            gray=$(tput setaf 250)
        else
            white=$(tput setaf 7)
            blue=$(tput setaf 38)
            yellow=$(tput setaf 3)
            tan=$(tput setaf 3)
            green=$(tput setaf 2)
            red=$(tput setaf 1)
            purple=$(tput setaf 13)
            gray=$(tput setaf 7)
        fi
    else
        bold="\033[4;37m"
        reset="\033[0m"
        underline="\033[4;37m"
        reverse=""
        white="\033[0;37m"
        blue="\033[0;34m"
        yellow="\033[0;33m"
        tan="\033[0;33m"
        green="\033[1;32m"
        red="\033[0;31m"
        purple="\033[0;35m"
        gray="\033[0;37m"
    fi
}
_setColors_

export bold
export underline
export reverse
export reset
export white
export blue
export yellow
export green
export red
export purple
export gray
