# ####################### KEYBINDINGS #######################

# alt-x : insert last command result
zmodload -i zsh/parameter
insert-last-command-output() {
    LBUFFER+="$(eval ${history[$((HISTCMD - 1))]})"
}
zle -N insert-last-command-output
bindkey '^[x' insert-last-command-output

# hist zsh plugin undo
bindkey "^_" undo

# [Ctrl-r] - Search backward incrementally for a specified string.
# The string may begin with ^ to anchor the search to the beginning of the line.
bindkey '^r' history-incremental-search-backward

# Navigate by words with alt+right/left arrows
bindkey "^[^[[C" forward-word
bindkey "^[^[[D" backward-word

# [PageUp] - Up a line of history
if [[ -n "$terminfo[kpp]" ]]; then
    bindkey "$terminfo[kpp]" up-line-or-history
fi
# [PageDown] - Down a line of history
if [[ -n "$terminfo[knp]" ]]; then
    bindkey "$terminfo[knp]" down-line-or-history
fi

if [[ -n "$terminfo[khome]" ]]; then
    # [Home] - Go to beginning of line
    bindkey "$terminfo[khome]" beginning-of-line

    # OPTION+left
    bindkey '[D' beginning-of-line
fi
if [[ -n "$terminfo[kend]" ]]; then
    # [End] - Go to end of line
    bindkey "$terminfo[kend]" end-of-line
    # OPTION+right
    bindkey '[C' end-of-line
fi
