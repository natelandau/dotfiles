#!/usr/bin/env bash

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return ;;
esac
[ -z "$PS1" ] && return

# set default umask
umask 002

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

### SOURCE BASH PLUGINS ###
# IMPORTANT: Edit this to reflect the location of this repository
DOTFILES_LOCATION="${HOME}/repos/dotfiles"

# Locations containing files *.bash to be sourced to your environment
configFileLocations=(
    "${DOTFILES_LOCATION}/dotfiles/shell"
    "${HOME}/repos/dotfiles-private/assets/shell"
)

for configFileLocation in "${configFileLocations[@]}"; do
    if [ -d "${configFileLocation}" ]; then
        while read -r configFile; do
            # shellcheck disable=SC1090
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
    builtin cd "$@" || return
    ll
}

# Shell completions for 1password CLI
if command -v op &>/dev/null; then
    # shellcheck disable=SC1090
    source <(op completion bash)
fi

if [ -f "${HOME}/.dotfiles.local" ]; then
    # shellcheck disable=SC1091
    source "${HOME}/.dotfiles.local"
fi
