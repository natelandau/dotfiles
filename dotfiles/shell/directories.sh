# Different sets of LS aliases because Gnu LS and macOS LS use different
# flags for colors.  Also, prefer gem colorls or eza when available.

if eza --icons &>/dev/null; then
    alias ls='eza --git --icons'                             # system: List filenames on one line
    alias l='eza --git --icons -lF'                          # system: List filenames with long format
    alias ll='eza -lahF --git --icons'                       # system: List all files
    alias llm='ll --sort=modified'                           # system: List files by last modified
    alias la='eza -lbhHigUmuSa --color-scale --git --icons'  # system: List files with attributes
    alias lx='eza -lbhHigUmuSa@ --color-scale --git --icons' # system: List files with extended attributes
    alias lt='eza --tree --level=2 --icons'                  # system: List files in a tree view
    alias llt='eza -lahF --tree --level=2 --icons'           # system: List files in a tree view with long format
    alias ltt='eza -lahF --icons | grep "$(date +"%d %b")"'  # system: List files modified today
elif command -v eza &>/dev/null; then
    alias ls='eza --git'
    alias l='eza --git -lF'
    alias ll='eza -lahF --git'     # system: List all files
    alias llm='ll --sort=modified' # system: List files by last modified date
    alias la='eza -lbhHigUmuSa --color-scale --git'
    alias lx='eza -lbhHigUmuSa@ --color-scale --git'
    alias lt='eza --tree --level=2'                 # system: List files in a tree view
    alias llt='eza -lahF --tree --level=2'          # system: List files in a tree view with long format
    alias ltt='eza -lahF | grep "$(date +"%d %b")"' # system: List files modified today
elif command -v colorls &>/dev/null; then
    alias ll="colorls -1A --git-status"
    alias ls="colorls -A"
    alias ltt='colorls -A | grep "$(date +"%d %b")"'
elif [[ $(command -v ls) =~ gnubin || $OSTYPE =~ linux ]]; then
    alias ls="ls --color=auto"
    alias ll='ls -FlAhpv --color=auto'
    alias ltt='ls -FlAhpv| grep "$(date +"%d %b")"' # system: List files modified today
else
    alias ls="ls -G"
    alias ll='ls -FGlAhpv'
    alias ltt='ls -FlAhpv| grep "$(date +"%d %b")"' # system: List files modified this day
fi

cd() {
    # Always print contents of directory when entering
    builtin cd "$@" || return 1
    ll
}

mcd() {
    # DESC: Create a directory and enter it
    # USAGE: mcd [dirname]
    mkdir -pv "$1"
    cd "$1" || exit
}
