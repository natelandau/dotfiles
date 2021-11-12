#!/usr/bin/env zsh
# This zshrc file uses zinit as a zsh plugin manager.
# More information: https://github.com/zdharma-continuum/zinit

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return ;;
esac
[ -z "$PS1" ] && return

# If zsh is emulating another shell, don't source .zshrc

if [[ $0 == 'ksh' ]] || [[ $0 == 'sh' ]]; then
    source "${HOME}/.shrc"
    exit
elif [[ $0 == 'bash' ]]; then
    source "${HOME}/.bashrc"
    exit
fi

# IMPORTANT: Edit this to reflect the location of this repository
DOTFILES_LOCATION="${HOME}/repos/dotfiles"

# Build PATH
_myPaths=(
    "${HOME}/.local/bin"
    "/usr/local/bin"
    "/opt/homebrew/bin"
    "${HOME}/bin"
)

for _path in "${_myPaths[@]}"; do
    if [[ -d ${_path} ]]; then
        if ! printf "%s" "${_path}" | grep -q "${PATH}"; then
            PATH="${_path}:${PATH}"
        fi
    fi
done

# Encoding
export LANG='en_US.UTF-8'
export LC_CTYPE='en_US.UTF-8'

# Insall zinit if not present
if [[ ! -d "${HOME}/.zinit" ]] && [[ ! -f "${HOME}/.zinit/bin/zinit.zsh" ]]; then
    # Favor cloning a git repository over sending a curl request straight to sh
    if command -v git >/dev/null 2>&1; then
        printf "%s\n\n" "Initializing zinit (https://github.com/zdharma-continuum/zinit)"
        mkdir "${HOME}/.zinit"
        git clone https://github.com/zdharma-continuum/zinit.git "${HOME}/.zinit/bin"
    else
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/master/doc/install.sh)"
    fi
fi

# Initialize zinit
source "${HOME}/.zinit/bin/zinit.zsh"
# autoload -Uz _zinit
# (( ${+_comps} )) && _comps[zinit]=_zinit

# Self update
# zinit self-update &>/dev/null

# Plugin parallel update
# zinit update --parallel &>/dev/null

# Zinit prompt
# zinit light "bhilburn/powerlevel9k"
# zinit light "denysdovhan/spaceship-prompt"
zinit ice depth=1
zinit light romkatv/powerlevel10k

# Zinit plugins
zinit light "zsh-users/zsh-autosuggestions"
zinit light "zsh-users/zsh-syntax-highlighting"
zinit light "zsh-users/zsh-history-substring-search"
zinit load "rupa/z"
zinit light "zsh-users/zsh-completions"

autoload -Uz compinit
compinit

# CONFIGURE PLUGINS
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242' # Use a lighter gray for the suggested text
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"

########################################################3
# Enable completion with compinit cache
# autoload -Uz compinit
# typeset -i updated_at=$(date +'%j' -r ~/.zcompdump 2>/dev/null || stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)
# if [ "$(date +'%j')" != "$updated_at" ]; then
#     compinit -i
# else
#     compinit -C -i
# fi
# zmodload -i zsh/complist

# Set Options
setopt always_to_end          # move cursor to end if word had one match
setopt append_history         # this is default, but set for share_history
setopt auto_cd                # cd by typing directory name if it's not a command
setopt AUTO_PUSHD             # Make cd push each old directory onto the stack
setopt PUSHD_IGNORE_DUPS      # Don't push duplicates onto the stack
setopt auto_list              # automatically list choices on ambiguous completion
setopt auto_menu              # automatically use menu completion
setopt completeinword         # not just at the end
setopt correct_all            # autocorrect commands
setopt extended_history       # save each command's beginning timestamp and duration to the history file
setopt hash_list_all          # when command completion is attempted, ensure the entire  path is hashed
setopt HIST_EXPIRE_DUPS_FIRST # # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt HIST_IGNORE_ALL_DUPS   # remove older duplicate entries from history
setopt HIST_IGNORE_DUPS       # don't record a duplicate entry in HISTFILE
setopt histignorespace        # remove commands from the history when the first character is a space
setopt HIST_REDUCE_BLANKS     # remove superfluous blanks from history items
setopt HIST_VERIFY            # show command with history expansion to user before running it
setopt INC_APPEND_HISTORY     # save history entries as soon as they are entered
setopt interactivecomments    # allow use of comments in interactive code
setopt longlistjobs           # display PID when suspending processes as well
setopt nonomatch              ## try to avoid the 'zsh: no matches found...'
setopt noshwordsplit          # use zsh style word splitting
setopt notify                 # report the status of backgrounds jobs immediately
setopt prompt_subst           # allow expansion in prompts
setopt SHARE_HISTORY          # share history between different instances of the shell
HISTFILE=${HOME}/.zsh_history
HISTSIZE=100000
SAVEHIST=${HISTSIZE}

# automatically remove duplicates from these arrays
typeset -U path cdpath fpath manpath

# Don’t clear the screen after quitting a manual page.
export MANPAGER='less -X'

# Set a variable so I can check if I'm running zsh
export ZSH_VERSION=$(zsh --version | awk '{print $2}')

## SOURCE ZSH CONFIGS ###
# Locations containing files *.bash to be sourced to your environment
configFileLocations=(
    "${DOTFILES_LOCATION}/shell"
    "${HOME}/repos/dotfiles-private/shell"
)

for configFileLocation in "${configFileLocations[@]}"; do
    if [ -d "${configFileLocation}" ]; then
        while read -r configFile; do
            source "${configFile}"
        done < <(find "${configFileLocation}" \
            -maxdepth 1 \
            -type f \
            -name '*.zsh' \
            -o -name '*.sh' | sort)
    fi
done
