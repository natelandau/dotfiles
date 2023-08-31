# Setup fzf
# ---------
if [[ -d /opt/homebrew/opt/fzf/bin ]]; then

    if [[ $PATH != */opt/homebrew/opt/fzf/bin* ]]; then
        export PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
    fi

    # Auto-completion
    # ---------------
    [[ $- == *i* ]] && source "/opt/homebrew/opt/fzf/shell/completion.zsh" 2>/dev/null

    # Key bindings
    # ------------
    source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
elif [[ -d /usr/local/opt/fzf/bin ]]; then

    if [[ $PATH != */usr/local/opt/fzf/bin* ]]; then
        export PATH="${PATH:+${PATH}:}/usr/local/opt/fzf/bin"
    fi

    # Auto-completion
    # ---------------
    [[ $- == *i* ]] && source "/usr/local/opt/fzf/shell/completion.zsh" 2>/dev/null

    # Key bindings
    # ------------
    source "/usr/local/opt/fzf/shell/key-bindings.zsh"

elif [[ -d /usr/share/doc/fzf/examples ]]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh

fi
