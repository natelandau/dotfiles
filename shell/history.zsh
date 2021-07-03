setopt HIST_IGNORE_ALL_DUPS # remove older duplicate entries from history
setopt HIST_REDUCE_BLANKS   # remove superfluous blanks from history items
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt HIST_EXPIRE_DUPS_FIRST
setopt INC_APPEND_HISTORY   # save history entries as soon as they are entered
setopt SHARE_HISTORY        # share history between different instances of the shell
setopt EXTENDED_HISTORY     # add timestamps to history

HISTFILE=${HOME}/.zsh_history
HISTSIZE=100000
SAVEHIST=${HISTSIZE}
