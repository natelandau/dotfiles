if [ -d "${HOME}/.pyenv" ]; then
    export PYENV_ROOT="${HOME}/.pyenv"
    command -v pyenv &>/dev/null || export PATH="${PYENV_ROOT}/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

function with_no_poetry() {
    # Prefixing any command with wnp runs it outside the virtualenv if a virtualenv is active.
    local last_env
    if [[ -v VIRTUAL_ENV ]]; then
        last_env="${VIRTUAL_ENV}"
        deactivate
    fi
    "$@"
    ret=$?
    # shellcheck disable=SC1091
    if [[ -v last_env ]]; then
        . "${last_env}/bin/activate"
    fi
    return ${ret}
}

alias wnp='with_no_poetry' # dev: Run a command outside the virtualenv

if [ -d "/opt/homebrew/anaconda3/bin" ]; then
    export PATH="/opt/homebrew/anaconda3/bin:${PATH}"
elif [ -d "/usr/local/anaconda3/bin" ]; then
    export PATH="/opt/homebrew/anaconda3/condabin:${PATH}"
fi
