#!/usr/bin/env bash

# If not running interactively, don't do anything
case $- in
  *i*) ;;
  *) return ;;
esac
[ -z "$PS1" ] && return

# IMPORTANT: Edit this to reflect the location of this repository
DOTFILES_LOCATION="${HOME}/repos/dotfiles"

# set default umask
umask 002

# Build PATH and put /usr/local/bin before existing PATH
export PATH="/usr/local/bin:${PATH}:/usr/local/sbin:${HOME}/bin:${HOME}/.local/bin"

### SOURCE BASH PLUGINS ###

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
      -name '*.bash' \
      -o -name '*.sh' \
      | sort)
  fi
done

# Always list directory contents upon 'cd'.
# (Somehow this always failed when I put it in a sourced file)
cd() {
  builtin cd "$@"
  ll
}
