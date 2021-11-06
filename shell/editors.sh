if [ -f "${DOTFILES_LOCATION:-}/bin/editor.sh" ]; then
    export EDITOR="${DOTFILES_LOCATION}/bin/editor.sh"
else
    export EDITOR="nano"
fi

q() {
    if [ $# -eq 1 ]; then
        $EDITOR "$@"
    elif [ $# -eq 0 ]; then
        if command -v code &>/dev/null; then
            code -r .
        fi
    fi
}
