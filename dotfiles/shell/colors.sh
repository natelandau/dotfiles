# shellcheck disable=SC2154

colors() {
    # Prints all tput colors to terminal
    for i in {0..255}; do print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " ${${(M)$((i%6)):#3}:+$'\n'}; done
}

mycolors() {
    # Prints my own color scheme to terminal
    printf "%s\n" "${underline} This is underlined text ${reset}"
    printf "%s\n" "${reverse} This is reversed text ${reset}"
    printf "%s\n" "${gray} This is gray text${reset}"
    printf "%s\n" "${white} This is white text ${reset}"
    printf "%s\n" "${bold} This is bold text ${reset}"
    printf "%s\n" "${blue} This is blue text ${reset}"
    printf "%s\n" "${yellow} This is yellow text"
    printf "%s\n" "${purple} This is purple text${reset}"
    printf "%s\n" "${red} This is red text ${reset}"
    printf "%s\n" "${green} This is green text${reset}"

    printf "%s\n" "${white}${reverse} This is white reversed text ${reset}"
    printf "%s\n" "${gray}${reverse} This is gray reversed text${reset}"
    printf "%s\n" "${blue}${reverse} This is blue reversed text ${reset}"
    printf "%s\n" "${yellow}${reverse} This is yellow reversed text"
    printf "%s\n" "${purple}${reverse} This is purple reversed text${reset}"
    printf "%s\n" "${red}${reverse} This is red reversed text ${reset}"
    printf "%s\n" "${green}${reverse} This is green reversed text${reset}"
}

# Add color to terminal
export CLICOLOR=1
#export LSCOLORS="ExDxCxDxCxegedabagacad"
#export LSCOLORS="GxFxCxDxBxegedabagaced"
#export LSCOLORS="ExFxBxDxCxegedabagacad"
export LSCOLORS="GxFxCxDxCxegedabagaced"
# LESS man page colors
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

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
            green=$(tput setaf 82)
            red=$(tput setaf 9)
            purple=$(tput setaf 171)
            gray=$(tput setaf 250)
        else
            white=$(tput setaf 7)
            blue=$(tput setaf 38)
            yellow=$(tput setaf 3)
            green=$(tput setaf 2)
            red=$(tput setaf 9)
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
