_raspberryPi_ () {
  local me
  me=$(whoami)

  if [[ "$me" == "pi" ]]; then

    # Aliases
    alias shutdown='sudo shutdown -h now'
    alias temp='vcgencmd measure_temp'

    # Fix raspberry pie locale issues
    export LC_ALL=C

    # set variable identifying the chroot you work in (used in the prompt below)
    if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
      debian_chroot=$(cat /etc/debian_chroot)
    fi

    # enable programmable completion features (you don't need to enable
    # this, if it's already enabled in /etc/bash.bashrc and /etc/profile
    # sources /etc/bash.bashrc).
    if ! shopt -oq posix; then
      if [ -f /usr/share/bash-completion/bash_completion ]; then
        # shellcheck disable=1091
        . /usr/share/bash-completion/bash_completion
      elif [ -f /etc/bash_completion ]; then
        # shellcheck disable=1091
        . /etc/bash_completion
      fi
    fi
  fi

}
_raspberryPi_
