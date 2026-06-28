# Load fzf
if command -v fzf >/dev/null && [[ -n ${ZSH_NAME} ]]; then
    fzf_version_minor=$(fzf --version | awk '{print $1}' | cut -d. -f2)

    if [[ $fzf_version_minor -ge 47 ]]; then
        eval "$(fzf --zsh)"
    elif [ -f "/usr/share/doc/fzf/examples/key-bindings.zsh" ]; then
        source /usr/share/doc/fzf/examples/key-bindings.zsh

        if [ -f "/usr/share/doc/fzf/examples/completion.zsh" ]; then
            source /usr/share/doc/fzf/examples/completion.zsh
        fi
    fi

    # fzf binds Ctrl-R to its own history widget, which clobbers atuin's binding
    # (atuin.sh loads before fzf.sh alphabetically). Restore atuin's Ctrl-R.
    if [[ "$(command -v atuin)" ]]; then
        bindkey '^r' _atuin_search_widget
    fi

elif command -v fzf >/dev/null && [[ -n ${BASH} ]]; then
    eval "$(fzf --bash)"

    # Restore atuin's Ctrl-R binding that `fzf --bash` overrides (see above).
    if [[ "$(command -v atuin)" ]]; then
        bind -x '"\C-r": __atuin_history'
    fi
fi

# Configure fzf
if command -v fzf >/dev/null; then
    # Preferred implementation requires fd, bat, and eza to be installed

    if command -v fd >/dev/null && command -v bat >/dev/null && command -v eza >/dev/null; then
        show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

        export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
        export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
        export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
        export FZF_DEFAULT_OPTS="--preview 'bat --color=always --line-range :500 {}'"

        # Use fd (https://github.com/sharkdp/fd) for listing path candidates.
        # - The first argument to the function ($1) is the base path to start traversal
        # - See the source code (completion.{bash,zsh}) for the details.
        _fzf_compgen_path() {
            fd --hidden --follow --exclude ".git" . "$1"
        }

        # Use fd to generate the list for directory completion
        _fzf_compgen_dir() {
            fd --type d --hidden --follow --exclude ".git" . "$1"
        }

        _fzf_comprun() {
            local command="$1"
            shift

            case "${command}" in
                cd) fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
                export | unset) fzf --preview "eval 'echo \$'{}" "$@" ;;
                ssh) fzf --preview 'dig {}' "$@" ;;
                *) fzf --preview "${show_file_or_dir_preview}" "$@" ;;
            esac
        }
    fi

fi
