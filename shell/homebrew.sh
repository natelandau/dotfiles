if command -v brew &>/dev/null; then

    # Don't send analytics data
    export HOMEBREW_NO_ANALYTICS=1

    if [[ -s /usr/local/etc/profile.d/autojump.sh ]]; then
        source "/usr/local/etc/profile.d/autojump.sh"
    fi
    if [[ ${SHELL##*/} == "bash" ]]; then
        if [ -f "/usr/local/etc/profile.d/bash_completion.sh" ]; then
            source "/usr/local/etc/profile.d/bash_completion.sh"
        fi
    fi

    if [ -f "$(brew --repository)/bin/src-hilite-lesspipe.sh" ]; then
        export LESSOPEN
        LESSOPEN="| $(brew --repository)/bin/src-hilite-lesspipe.sh %s"
        export LESS=' -R -z-4'
    fi

    # /Applications is now the default but leaving this for posterity
    export HOMEBREW_CASK_OPTS="--appdir=/Applications"

    alias cask='brew cask'
    alias brwe='brew' #typos

    bup() {
        local brewScript="${HOME}/bin/updateHomebrew"
        if [ -e "${brewScript}" ]; then
            "${brewScript}" "$*"
        else
            brew update
            brew upgrade
            brew cleanup
            brew prune
        fi
    }

fi
