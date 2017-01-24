  ## GENERAL PREFERENCES ##
  export BLOCKSIZE=1k
  export LANG="en_US"
  export LC_ALL="en_US.UTF-8"
  export LESS_TERMCAP_md="$ORANGE"  # Highlight section titles in manual pages
  export MANPAGER="less -X"         # Don’t clear the screen after quitting a man page
  set -o noclobber          # Prevent file overwrite on stdout redirection
  shopt -s checkwinsize     # Update window size after every command
  PROMPT_DIRTRIM=3          # Automatically trim long paths in the prompt (requires Bash 4.x)

  ## BETTER DIRECTORY NAVIGATION ##
  shopt -s autocd       # Prepend cd to directory names automatically
  shopt -s dirspell     # Correct spelling errors during tab-completion
  shopt -s cdspell      # Correct spelling errors in arguments supplied to cd
  shopt -s nocaseglob;  # Case-insensitive globbing (used in pathname expansion)
  CDPATH=".:~"          # This defines where cd looks for targets

  # This allows you to bookmark your favorite places across the file system
  # Define a variable containing a path and you will be able to cd into it
  # regardless of the directory you're in
  shopt -s cdable_vars
  export dotfiles="$HOME/dotfiles"
  export dropbox="$HOME/Dropbox"

  ## SMARTER TAB-COMPLETION (Readline bindings) ##
  bind "set completion-ignore-case on" # Perform file completion in a case insensitive fashion
  bind "set completion-map-case on"    # Treat hyphens and underscores as equivalent
  bind "set show-all-if-ambiguous on"  # Display matches for ambiguous patterns at first tab press

  # SSH auto-completion based on entries in known_hosts.
  if [[ -e ~/.ssh/known_hosts ]]; then
    complete -o default -W "$(cat ${HOME}/.ssh/known_hosts | sed 's/[, ].*//' | sort | uniq | grep -v '[0-9]')" ssh scp sftp
  fi