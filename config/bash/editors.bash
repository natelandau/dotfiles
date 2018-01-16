if command -v subl &>/dev/null; then
  q() {
    # easy access to VisualCode
    if [ $# -eq 0 ]; then
      code .
    else
      code "$@"
    fi
  }
fi

EDITOR=$(type micro nano pico | sed 's/ .*$//;q')
export EDITOR
LESSEDIT="$EDITOR %f" && export LESSEDIT
VISUAL="$EDITOR" && export VISUAL
m() { $EDITOR "$@"; }