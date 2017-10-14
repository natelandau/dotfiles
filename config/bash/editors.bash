if [ ! "$SSH_TTY" ] && command -v subl &> /dev/null; then
  EDITOR='subl'; export EDITOR;
  LESSEDIT='subl %f'; export LESSEDIT;
  VISUAL="$EDITOR"; export VISUAL;

  q () {
    # easy access to SublimeText
    if [ $# -eq 0 ]; then
      subl .;
    else
      subl "$@";
    fi;
  }
else
  EDITOR=$(type micro nano pico 2>/dev/null | sed 's/ .*$//;q')
  export EDITOR;
  VISUAL="$EDITOR"; export VISUAL;
fi



