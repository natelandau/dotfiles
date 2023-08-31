# Setup fzf
# ---------

if [[ -d /opt/homebrew/opt/fzf/bin ]]; then
    if [[ $PATH != */opt/homebrew/opt/fzf/bin* ]]; then
        export PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
    fi

    # Auto-completion
    # ---------------
    [[ $- == *i* ]] && source "/opt/homebrew/opt/fzf/shell/completion.bash" 2>/dev/null

    # Key bindings
    # ------------
    source "/opt/homebrew/opt/fzf/shell/key-bindings.bash"

elif [[ -d /usr/local/opt/fzf/bin ]]; then
    if [[ $PATH != */usr/local/opt/fzf/bin* ]]; then
        export PATH="${PATH:+${PATH}:}/usr/local/opt/fzf/bin"
    fi

    # Auto-completion
    # ---------------
    [[ $- == *i* ]] && source "/usr/local/opt/fzf/shell/completion.bash" 2>/dev/null

    # Key bindings
    # ------------
    source "/usr/local/opt/fzf/shell/key-bindings.bash"

elif [[ -d /usr/share/doc/fzf/examples ]]; then
    source /usr/share/doc/fzf/examples/key-bindings.bash
    [[ -f /usr/share/bash-completion/completions/fzf ]] && source /usr/share/bash-completion/completions/fzf
fi
