# Force rehash when command not found
_force_rehash() {
    ((CURRENT == 1)) && rehash
    return 1
}
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ${HOME}/.zsh/cache

zstyle ':completion:*' list-colors ''
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*' completer _oldlist _expand _force_rehash _complete _match # forces zsh to realize new commands
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'                              # matches case insensitive for lowercase
zstyle ':completion:*' insert-tab pending                                        # pasting with tabs doesn't perform completion
zstyle ':completion:*' menu select=2                                             # menu if nb items > 2
zstyle ':completion:*' special-dirs true                                         # Show dotfiles in completions

zstyle ':completion:*:functions' ignored-patterns '_*' #Ignore completion functions for commands you don’t have
zstyle ':completion:*' squeeze-slashes true            #f you end up using a directory as argument, this will remove the trailing slash (usefull in ln)

# Tweak the UX of the autocompletion menu to match even if we made a typo and enable navigation using the arrow keys
zstyle ':completion:*' menu select   # select completions with arrow keys
zstyle ':completion:*' group-name '' # group results by category

zstyle ':completion:::::' completer _expand _complete _ignored _approximate # enable approximate matches for completion

# Make zsh know about hosts already accessed by SSH
zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

setopt auto_menu # show completion menu on successive tab press
setopt complete_in_word
setopt always_to_end
