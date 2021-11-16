# Different sets of LS aliases because Gnu LS and macOS LS use different
# flags for colors.  Also, prefer gem colorls or exa when available.

if command -v exa &>/dev/null; then
    alias ls='exa --git --icons'
    alias l='exa --git --icons -lF'
    alias ll='exa -lahF --git'
    alias lll="exa -1F --git --icons"
    alias llm='ll --sort=modified'
    alias la='ls -lbhHigUmuSa --color-scale'
    alias lx='ls -lbhHigUmuSa@ --color-scale'
    alias lt='exa --tree --level=2'
    alias llt='exa -lahF --tree --level=2'
elif
    command -v colorls &>/dev/null
then
    alias ll="colorls -1A --git-status"
    alias ls="colorls -A"
elif [[ $(command -v ls) =~ gnubin || $OSTYPE =~ linux ]]; then
    alias ls="ls --color=auto"
    alias ll='ls -FlAhpv --color=auto'
else
    alias ls="ls -G"
    alias ll='ls -FGlAhpv'
fi

cd() {
    builtin cd "$@" || return 1
    ll
}

mcd() {
    # DESC: Create a directory and enter it
    # USAGE: mcd [dirname]
    mkdir -pv "$1"
    cd "$1" || exit
}
