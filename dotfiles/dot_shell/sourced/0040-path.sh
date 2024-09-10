# Build PATH
_myPaths=(
    "${HOME}/.local/bin"
    "/usr/local/bin"
    "/opt/homebrew/bin"
    "${HOME}/bin"
    "${HOME}/.cargo/bin"
    "/usr/bin/snap"
    "${HOME}.atuin/bin"
)

for _path in "${_myPaths[@]}"; do
    if [[ -d ${_path} ]]; then
        if ! printf "%s" "${_path}" | grep -q "${PATH}"; then
            PATH="${_path}:${PATH}"
        fi
    fi
done
