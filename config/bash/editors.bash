if [[ ! "$SSH_TTY" && $(command -v subl &> /dev/null) ]]; then
  export EDITOR='subl'
  export LESSEDIT='subl %f'

  q () {
    # easy access to SublimeText
    if [ $# -eq 0 ]; then
      subl .;
    else
      subl "$@";
    fi;
  }

else
  export EDITOR=$(type slap nano pico 2>/dev/null | sed 's/ .*$//;q')
fi
export VISUAL="$EDITOR"

