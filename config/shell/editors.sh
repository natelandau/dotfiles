if [ -f "${HOME}/dotfiles/bin/editor.sh" ]; then
  export EDITOR="${HOME}/dotfiles/bin/editor.sh"
else
  export EDITOR="nano"
fi

q() {
  if [ $# -eq 1 ]; then
    ${EDITOR} "$@"
  elif [ $# -eq 0 ]; then
    if command -v code &>/dev/null; then
      code -r .
    elif command -v subl &>/dev/null; then
      subl .
    fi
  fi
}