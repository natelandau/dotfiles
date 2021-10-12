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

    # Fix common typo
    alias brwe='brew'

    # Favor gnu tools when available from homebrew
    if [ -d "/usr/local/opt/findutils/libexec/gnubin" ]; then
        PATH="/usr/local/opt/findutils/libexec/gnubin:${PATH}"
    fi
    if [ -d "/usr/local/opt/gnu-sed/libexec/gnubin" ]; then
        PATH="/usr/local/opt/gnu-sed/libexec/gnubin:${PATH}"
    fi
    if [ -d "/usr/local/opt/grep/libexec/gnubin" ]; then
        PATH="/usr/local/opt/grep/libexec/gnubin:${PATH}"
    fi
    if [ -d "/usr/local/opt/coreutils/libexec/gnubin" ]; then
        PATH="/usr/local/opt/coreutils/libexec/gnubin:${PATH}"
    fi
    if [ -d "/usr/local/opt/gnu-tar/libexec/gnubin" ]; then
        PATH="/usr/local/opt/gnu-tar/libexec/gnubin:${PATH}"
    fi
    if [ -d "/usr/local/opt/gnu-getopt/bin" ]; then
        PATH="/usr/local/opt/gnu-getopt/bin:${PATH}"
    fi

fi
