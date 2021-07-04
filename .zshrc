#!/usr/bin/env bash

# If not running interactively, don't do anything
case $- in
  *i*) ;;
  *) return ;;
esac
[ -z "$PS1" ] && return

# IMPORTANT: Edit this to reflect the location of this repository
DOTFILES_LOCATION="${HOME}/repos/dotfiles"

# Build PATH
export PATH="/usr/local/bin:${PATH}:/usr/local/sbin:${HOME}/bin:${HOME}/.local/bin"

# Encoding
export LANG='en_US.UTF-8'
export LC_CTYPE='en_US.UTF-8'

# Enable completion with compinit cache
autoload -Uz compinit
typeset -i updated_at=$(date +'%j' -r ~/.zcompdump 2>/dev/null || stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)
if [ "$(date +'%j')" != "$updated_at" ]; then
  compinit -i
else
  compinit -C -i
fi
zmodload -i zsh/complist

# Set Options
setopt auto_cd       # cd by typing directory name if it's not a command
setopt correct_all   # autocorrect commands
setopt auto_list     # automatically list choices on ambiguous completion
setopt auto_menu     # automatically use menu completion
setopt always_to_end # move cursor to end if word had one match

# Don’t clear the screen after quitting a manual page.
export MANPAGER='less -X'

## SOURCE ZSH CONFIGS ###
# Locations containing files *.bash to be sourced to your environment
configFileLocations=(
  "${DOTFILES_LOCATION}/shell"
  "${HOME}/repos/dotfiles-private/shell"
)

for configFileLocation in "${configFileLocations[@]}"; do
  if [ -d "${configFileLocation}" ]; then
    while read -r configFile; do
      source "$configFile"
    done < <(find "${configFileLocation}" \
      -maxdepth 1 \
      -type f \
      -name '*.zsh' \
      -o -name '*.sh' | sort)
  fi
done

# Source History substring search if available
if [ -f ${HOME}/Library/Caches/antibody/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-history-substring-search/zsh-history-substring-search.zsh ]; then
  source ${HOME}/Library/Caches/antibody/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-history-substring-search/zsh-history-substring-search.zsh
fi

export PATH="/usr/local/opt/mysql-client/bin:$PATH"
