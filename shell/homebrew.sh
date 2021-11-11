if command -v brew &>/dev/null; then

    # Don't send analytics data
    export HOMEBREW_NO_ANALYTICS=1

    if [[ -e "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    # if [[ -s /usr/local/etc/profile.d/autojump.sh ]]; then
    #     source "/usr/local/etc/profile.d/autojump.sh"
    # fi
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

    # Fix common typo
    alias brwe='brew'

    # Favor gnu tools when available from homebrew
    if [ -d "/usr/local/opt/findutils/libexec/gnubin" ]; then
        PATH="/usr/local/opt/findutils/libexec/gnubin:${PATH}"
    elif [ -d "/opt/homebrew/opt/findutils/libexec" ]; then
        PATH="/opt/homebrew/opt/findutils/libexec/gnubin:${PATH}"
    fi
    if [ -d "/usr/local/opt/gnu-sed/libexec/gnubin" ]; then
        PATH="/usr/local/opt/gnu-sed/libexec/gnubin:${PATH}"
    elif [ -d "/opt/homebrew/opt/gnu-sed/libexec" ]; then
        PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:${PATH}"
    fi
    if [ -d "/usr/local/opt/grep/libexec/gnubin" ]; then
        PATH="/usr/local/opt/grep/libexec/gnubin:${PATH}"
    elif [ -d "/opt/homebrew/opt/grep/libexec/gnubin" ]; then
        PATH="/opt/homebrew/opt/grep/libexec/gnubin:${PATH}"
    fi
    if [ -d "/usr/local/opt/coreutils/libexec/gnubin" ]; then
        PATH="/usr/local/opt/coreutils/libexec/gnubin:${PATH}"
    elif [ -d "/opt/homebrew/opt/coreutils/libexec/gnubin" ]; then
        PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:${PATH}"
    fi
    if [ -d "/usr/local/opt/gnu-tar/libexec/gnubin" ]; then
        PATH="/usr/local/opt/gnu-tar/libexec/gnubin:${PATH}"
    elif [ -d "/opt/homebrew/opt/gnu-tar/libexec/gnubin" ]; then
        PATH="/opt/homebrew/opt/gnu-tar/libexec/gnubin:${PATH}"
    fi
    if [ -d "/usr/local/opt/gnu-getopt/bin" ]; then
        PATH="/usr/local/opt/gnu-getopt/bin:${PATH}"
    elif [ -d "/opt/homebrew/opt/gnu-getopt/bin" ]; then
        PATH="/opt/homebrew/opt/gnu-getopt/bin:${PATH}"
    fi

fi
