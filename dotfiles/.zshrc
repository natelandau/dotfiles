#!/usr/bin/env zsh

# This zshrc file uses zinit as a zsh plugin manager.
# More information: https://github.com/zdharma-continuum/zinit

# If not running interactively, don't do anything
#############################################
case $- in
    *i*) ;;
    *) return ;;
esac
[ -z "$PS1" ] && return

# duplicates slow down searching
#############################################
builtin declare -aU fpath
builtin declare -aU path
builtin declare -aU manpath
# FPATH should not be exported
builtin declare +x FPATH
# duplicates slow down searching and
# mess up OMZ fpath check if should remove zcompdump
fpath=(${(u)fpath})
path=(${(u)path})
manpath=(${(u)manpath})

# If zsh is emulating another shell, don't source .zshrc
#############################################
if [[ $0 == 'ksh' ]] || [[ $0 == 'sh' ]]; then
    source "${HOME}/.shrc"
    exit
elif [[ $0 == 'bash' ]]; then
    source "${HOME}/.bashrc"
    exit
fi

# Build PATH
#############################################
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

unset _myPaths _path

# Encoding
#############################################
export LANG='en_US.UTF-8'
export LC_CTYPE='en_US.UTF-8'


# Load Plugins
# https://github.com/mattmc3/zsh_unplugged - Build your own zsh plugin manager
#############################################
# clone your plugin, set up an init.zsh, source it, and add to your fpath
_pluginload_() {
    local giturl="$1"
    local plugin_name=${${1##*/}%.git}
    local plugindir="${ZPLUGINDIR:-$HOME/.zsh/plugins}/$plugin_name"

    # clone if the plugin isn't there already
    if [[ ! -d "${plugindir}" ]]; then
        command git clone --depth 1 --recursive --shallow-submodules "${giturl}" "${plugindir}"
        [[ $? -eq 0 ]] || { echo "plugin-load: git clone failed $1" && return 1; }
    fi

    # symlink an init.zsh if there isn't one so the plugin is easy to source
    if [[ ! -f $plugindir/init.zsh ]]; then
        local initfiles=(
          # look for specific files first
          $plugindir/$plugin_name.plugin.zsh(N)
          $plugindir/$plugin_name.zsh(N)
          $plugindir/$plugin_name(N)
          $plugindir/$plugin_name.zsh-theme(N)
          # then do more aggressive globbing
          $plugindir/*.plugin.zsh(N)
          $plugindir/*.zsh(N)
          $plugindir/*.zsh-theme(N)
          $plugindir/*.sh(N)
        )
        [[ ${#initfiles[@]} -gt 0 ]] || { >&2 echo "plugin-load: no plugin init file found" && return 1; }
        command ln -s ${initfiles[1]} $plugindir/init.zsh
    fi

    # source the plugin
    source $plugindir/init.zsh

    # modify fpath
    fpath+=$plugindir
    [[ -d $plugindir/functions ]] && fpath+=$plugindir/functions
}

# set where we should store Zsh plugins
ZPLUGINDIR=${HOME}/.zsh/plugins

# add your plugins to this list
plugins=(
    # core plugins
    zsh-users/zsh-autosuggestions
    zsh-users/zsh-completions

    # # user plugins
    peterhurford/up.zsh                 # Cd to parent directories (ie. up 3)
    marlonrichert/zsh-hist              # Run hist -h for help
    reegnz/jq-zsh-plugin                # Write interactive jq queries (Requires jq and fzf)
    MichaelAquilina/zsh-you-should-use  # Recommends aliases when typed
    rupa/z                              # Tracks your most used directories, based on 'frequency'

    # Additional completions
    sudosubin/zsh-github-cli
    zpm-zsh/ssh

    # prompts
    # denysdovhan/spaceship-prompt
    romkatv/powerlevel10k

    # load these last
    # zsh-users/zsh-syntax-highlighting
    zdharma-continuum/fast-syntax-highlighting
    zsh-users/zsh-history-substring-search
)

mac_plugins=(
      ellie/atuin     # Replace history search with a sqlite database
)

# load your plugins (clone, source, and add to fpath)
for repo in ${plugins[@]}; do
  _pluginload_ https://github.com/${repo}.git
done
unset repo

if [[ ${OSTYPE} == "darwin"* ]]; then
  for mac_repo in ${mac_plugins[@]}; do
    _pluginload_ https://github.com/${mac_repo}.git
  done
  unset mac_repo
fi

# Update ZSH Plugins
function zshup () {
  local plugindir="${ZPLUGINDIR:-$HOME/.zsh/plugins}"
  for d in $plugindir/*/.git(/); do
    echo "Updating ${d:h:t}..."
    command git -C "${d:h}" pull --ff --recurse-submodules --depth 1 --rebase --autostash
  done
}

if [ -d "${HOME}/.zfunc" ]; then
  fpath+=${HOME}/.zfunc
fi

# Load Completions
#############################################
autoload -Uz compinit
compinit -i

# CONFIGURE PLUGINS
#############################################
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242' # Use a lighter gray for the suggested text
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"
FAST_HIGHLIGHT[use_brackets]=1

# Set Options
#############################################
setopt always_to_end          # When completing a word, move the cursor to the end of the word
setopt append_history         # this is default, but set for share_history
setopt auto_cd                # cd by typing directory name if it's not a command
setopt auto_list              # automatically list choices on ambiguous completion
setopt auto_menu              # automatically use menu completion
setopt auto_pushd             # Make cd push each old directory onto the stack
setopt completeinword         # If unset, the cursor is set to the end of the word
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
HISTFILE=${HOME}/.zsh_history
HISTSIZE=100000
SAVEHIST=${HISTSIZE}

#Disable autocorrect
unsetopt correct_all
unsetopt correct
DISABLE_CORRECTION="true"

# automatically remove duplicates from these arrays
#############################################
typeset -U path cdpath fpath manpath

# Set a variable so I can check if I'm running zsh
export ZSH_VERSION=$(zsh --version | awk '{print $2}')

# SOURCE Dotfiles
#############################################

# Location of this repository
DOTFILES_LOCATION="${HOME}/repos/dotfiles"

# Locations containing files *.bash to be sourced to your environment
configFileLocations=(
    "${DOTFILES_LOCATION}/dotfiles/shell"
    "${HOME}/repos/dotfiles-private/dotfiles/shell"
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

unset DOTFILES_LOCATION configFileLocations configFileLocation

# Set man pager
#############################################
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
#man 2 select

# Install/Configure atuin (https://github.com/ellie/atuin)
#############################################

_atuin_() {
    if command -v atuin &>/dev/null; then
        export ATUIN_NOBIND="true"
        eval "$(atuin init zsh)"
        bindkey '^r' _atuin_search_widget
    else
        if hostnamectl | grep -q Raspbian &>/dev/null; then
            return 0
        elif [ -f "${HOME}/.zsh/plugins/atuin/install.sh" ]; then
            if ${HOME}/.zsh/plugins/atuin/install.sh; then
                if command -v atuin &>/dev/null; then
                    export ATUIN_NOBIND="true"
                    eval "$(atuin init zsh)"
                    bindkey '^r' _atuin_search_widget
                    atuin import zsh
                fi
            else
                printf "%s\n" "ERROR: Could not install Atuin. Docs: https://github.com/ellie/atuin"
            fi
        fi
    fi
}
if [[ ${OSTYPE} == "darwin"* ]]; then
    _atuin_
fi


# Shell completions for 1password CLI
if command -v op &>/dev/null; then
    eval "$(op completion zsh)"; compdef _op op
fi

if [ -f "${HOME}/.dotfiles.local" ]; then
    source "${HOME}/.dotfiles.local"
fi
