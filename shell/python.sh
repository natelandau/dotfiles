if ! command -v pyenv &>/dev/null && [ -d "${HOME}/.pyenv/bin" ]; then
    export PATH="${HOME}/.pyenv/bin:${PATH}"
fi

if command -v pyenv &>/dev/null; then
    export PYENV_ROOT="${HOME}/.pyenv"
    export PATH="${PYENV_ROOT}/bin:${PATH}"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi
