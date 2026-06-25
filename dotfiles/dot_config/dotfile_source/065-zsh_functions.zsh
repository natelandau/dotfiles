# zsh-only helper functions.
#
# These live in a `.zsh` file (sourced only by zsh) rather than a shared `.sh`
# file because their bodies use zsh-specific syntax (print -P, fc -p, the
# ${(b)...}/${(l:...:)...} parameter flags) that bash cannot run.

function smite() {
    # Remove entries from history using fzf
    # https://esham.io/2025/05/shell-history

    setopt LOCAL_OPTIONS ERR_RETURN PIPE_FAIL

    local opts=( -I )
    if [[ $1 == '-a' ]]; then
        opts=()
    elif [[ -n $1 ]]; then
        print >&2 'usage: smite [-a]'
        return 1
    fi

    fc -l -n "$opts" 1 | \
        fzf --no-sort --tac --multi | \
        while IFS='' read -r command_to_delete; do
            printf 'Removing history entry "%s"\n' "$command_to_delete"
            local HISTORY_IGNORE="${(b)command_to_delete}"
            fc -W
            fc -p "$HISTFILE" $HISTSIZE "$SAVEHIST"
        done
}

colors() {
    # Prints all tput colors to terminal
    for i in {0..255}; do print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " ${${(M)$((i%6)):#3}:+$'\n'}; done
}
