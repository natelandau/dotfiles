# shellcheck disable=SC2154

######################## HISTORY #######################
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
export HISTFILE={{ .xdgStateDir }}/bash/history

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

####################### GENERAL #######################

export BLOCKSIZE=1k
export LESS_TERMCAP_md="${yellow}" # Highlight section titles in manual pages
set -o noclobber                   # Prevent file overwrite on stdout redirection
shopt -s checkwinsize              # Update window size after every command
PROMPT_DIRTRIM=3                   # Automatically trim long paths in the prompt (requires Bash 4.x)

####################### DIRECTORY NAVIGATION #######################

shopt -s autocd               # Prepend cd to directory names automatically
shopt -s dirspell             # Correct spelling errors during tab-completion
shopt -s cdspell              # Correct spelling errors in arguments supplied to cd
shopt -s nocaseglob           # Case-insensitive globbing (used in pathname expansion)
shopt -s globstar 2>/dev/null # Recursive globbing (enables ** to recurse all directories)
CDPATH=".:~"                  # This defines where cd looks for targets

####################### SMARTER TAB-COMPLETION (Readline bindings)  #######################

bind "set completion-ignore-case on"     # Perform file completion in a case insensitive fashion
bind "set completion-map-case on"        # Treat hyphens and underscores as the same
bind "set show-all-if-ambiguous on"      # Display matches for ambiguous patterns at first tab press
bind "set mark-symlinked-directories on" # Add trailing slash when autocompleting symlinks to directories
bind Space:magic-space                   # typing !!<space> will replace the !! with your last command

####################### SSH AUTOCOMPLETION #######################
# SSH auto-completion based on entries in known_hosts.
if [[ -e ~/.ssh/known_hosts ]]; then
    complete -o default -W "$(sed 's/[, ].*//' "${HOME}/.ssh/known_hosts" | sort | uniq | grep -v '[0-9]')" ssh scp sftp
fi
