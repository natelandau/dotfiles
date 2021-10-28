# Record each line as it gets issued
#PROMPT_COMMAND='history -a' # depreciated due to 'autojump'
# Here is autojump's recommended prompt-command
export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND ;} history -a"

# Allow use to re-edit a failed history substitution.
shopt -s histreedit

# Save multi-line commands as one command
shopt -s cmdhist

# History expansions will be verified before execution.
shopt -s histverify

# Append to the history file, don't overwrite it
shopt -s histappend

# Give history timestamps.
export HISTTIMEFORMAT="[%F %T] "

# Lots o' history.
export HISTSIZE=10000
export HISTFILESIZE=10000

# Avoid duplicate entries
HISTCONTROL="erasedups:ignoreboth"

# commands with leading space do not get added to history
HISTCONTROL=ignorespace

# Don't record some commands
export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

# Enable incremental history search with up/down arrows (also Readline goodness)
# Learn more about this here: http://codeinthehole.com/writing/the-most-important-command-line-tip-incremental-history-searching-with-inputrc/
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\e[C": forward-char'
bind '"\e[D": backward-char'
