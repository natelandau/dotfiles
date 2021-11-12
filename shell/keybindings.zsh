# alt-x : insert last command resultwhic
zmodload -i zsh/parameter
insert-last-command-output() {
    LBUFFER+="$(eval ${history[$((HISTCMD - 1))]})"
}
zle -N insert-last-command-output
bindkey '^[x' insert-last-command-output

# Navigate by words with alt+right/left arrows
bindkey "^[^[[C" forward-word
bindkey "^[^[[D" backward-word

# History Search with alt+up/down arros
bindkey '^[^[[A' history-substring-search-up
bindkey '^[^[[B' history-substring-search-down

# [Ctrl-r] - Search backward incrementally for a specified string.
# The string may begin with ^ to anchor the search to the beginning of the line.
bindkey '^r' history-incremental-search-backward
# [PageUp] - Up a line of history
if [[ -n "$terminfo[kpp]" ]]; then
    bindkey "$terminfo[kpp]" up-line-or-history
fi
# [PageDown] - Down a line of history
if [[ -n "$terminfo[knp]" ]]; then
    bindkey "$terminfo[knp]" down-line-or-history
fi
# start typing + [Up-Arrow] - fuzzy find history forward
if [[ -n "$terminfo[kcuu1]" ]]; then
    bindkey "$terminfo[kcuu1]" history-substring-search-up
fi
# start typing + [Down-Arrow] - fuzzy find history backward
if [[ -n "$terminfo[kcud1]" ]]; then
    bindkey "$terminfo[kcud1]" history-substring-search-down
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
