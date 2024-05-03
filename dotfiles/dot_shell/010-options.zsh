# shellcheck disable=SC2016,SC2154,SC2086,SC1087,SC2157
# ####################### COMPLETIONS #######################
# Force rehash when command not found
_force_rehash() {
    ((CURRENT == 1)) && rehash
    return 1
}
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${HOME}/.zsh/cache"

zstyle ':completion:*' list-colors ''
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*' completer _oldlist _expand _force_rehash _complete _match # forces zsh to realize new commands
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'                              # matches case insensitive for lowercase
zstyle ':completion:*' insert-tab pending                                        # pasting with tabs doesn't perform completion
zstyle ':completion:*' menu select=2                                             # menu if nb items > 2
zstyle ':completion:*' special-dirs true                                         # Show dotfiles in completions

zstyle ':completion:*:functions' ignored-patterns '_*' #Ignore completion functions for commands you don't have
zstyle ':completion:*' squeeze-slashes true            #f you end up using a directory as argument, this will remove the trailing slash (useful in ln)

# Tweak the UX of the autocompletion menu to match even if we made a typo and enable navigation using the arrow keys
zstyle ':completion:*' menu select   # select completions with arrow keys
zstyle ':completion:*' group-name '' # group results by category

zstyle ':completion:::::' completer _expand _complete _ignored _approximate # enable approximate matches for completion

# Make zsh know about hosts already accessed by SSH
zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

setopt auto_menu # show completion menu on successive tab press
setopt complete_in_word
setopt always_to_end

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

# History Search with alt+up/down arrows
bindkey '^[^[[A' history-substring-search-up
bindkey '^[^[[B' history-substring-search-down

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
