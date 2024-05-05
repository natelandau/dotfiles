# Set Options
#############################################
setopt always_to_end  # When completing a word, move the cursor to the end of the word
setopt append_history # this is default, but set for share_history
setopt auto_cd        # cd by typing directory name if it's not a command
setopt auto_list      # automatically list choices on ambiguous completion
setopt auto_menu      # show completion menu on successive tab press
setopt auto_menu      # automatically use menu completion
setopt auto_pushd     # Make cd push each old directory onto the stack
setopt complete_in_word
setopt completeinword # If unset, the cursor is set to the end of the word
# setopt correct_all            # autocorrect commands
setopt extended_glob          # treat #, ~, and ^ as part of patterns for filename generation
setopt extended_history       # save each command's beginning timestamp and duration to the history file
setopt glob_dots              # dot files included in regular globs
setopt hash_list_all          # when command completion is attempted, ensure the entire  path is hashed
setopt hist_expire_dups_first # # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_find_no_dups      # When searching history don't show results already cycled through twice
setopt hist_ignore_dups       # Do not write events to history that are duplicates of previous events
setopt hist_ignore_space      # remove command line from history list when first character is a space
setopt hist_reduce_blanks     # remove superfluous blanks from history items
setopt hist_verify            # show command with history expansion to user before running it
setopt histignorespace        # remove commands from the history when the first character is a space
setopt inc_append_history     # save history entries as soon as they are entered
setopt interactivecomments    # allow use of comments in interactive code (bash-style comments)
setopt longlistjobs           # display PID when suspending processes as well
setopt no_beep                # silence all bells and beeps
setopt nocaseglob             # global substitution is case insensitive
setopt nonomatch              ## try to avoid the 'zsh: no matches found...'
setopt noshwordsplit          # use zsh style word splitting
setopt notify                 # report the status of backgrounds jobs immediately
setopt numeric_glob_sort      # globs sorted numerically
setopt prompt_subst           # allow expansion in prompts
setopt pushd_ignore_dups      # Don't push duplicates onto the stack
setopt share_history          # share history between different instances of the shell

#Disable autocorrect
unsetopt correct_all
unsetopt correct

HISTFILE=${HOME}/.zsh_history
HISTSIZE=100000
SAVEHIST=${HISTSIZE}

DISABLE_CORRECTION="true"

# automatically remove duplicates from these arrays
#############################################
typeset -U path cdpath fpath manpath

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
