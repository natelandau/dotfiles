# shellcheck disable=SC2154

if [[ ${SHELL##*/} == "bash" ]]; then
    ## GENERAL PREFERENCES ##
    export BLOCKSIZE=1k
    export LANG="en_US"
    export LC_ALL="en_US.UTF-8"
    export LESS_TERMCAP_md="${yellow}" # Highlight section titles in manual pages
    export MANPAGER="less -X"          # Don’t clear the screen after quitting a man page
    set -o noclobber                   # Prevent file overwrite on stdout redirection
    shopt -s checkwinsize              # Update window size after every command
    PROMPT_DIRTRIM=3                   # Automatically trim long paths in the prompt (requires Bash 4.x)

    ## BETTER DIRECTORY NAVIGATION ##
    shopt -s autocd               # Prepend cd to directory names automatically
    shopt -s dirspell             # Correct spelling errors during tab-completion
    shopt -s cdspell              # Correct spelling errors in arguments supplied to cd
    shopt -s nocaseglob           # Case-insensitive globbing (used in pathname expansion)
    shopt -s globstar 2>/dev/null # Recursive globbing (enables ** to recurse all directories)
    CDPATH=".:~"                  # This defines where cd looks for targets

    ## SMARTER TAB-COMPLETION (Readline bindings) ##
    bind "set completion-ignore-case on"     # Perform file completion in a case insensitive fashion
    bind "set completion-map-case on"        # Treat hyphens and underscores as the same
    bind "set show-all-if-ambiguous on"      # Display matches for ambiguous patterns at first tab press
    bind "set mark-symlinked-directories on" # Add trailing slash when autocompleting symlinks to directories
    bind Space:magic-space                   # typing !!<space> will replace the !! with your last command
fi

# SSH auto-completion based on entries in known_hosts.
if [[ -e ~/.ssh/known_hosts ]]; then
    complete -o default -W "$(sed 's/[, ].*//' "${HOME}/.ssh/known_hosts" | sort | uniq | grep -v '[0-9]')" ssh scp sftp
fi
