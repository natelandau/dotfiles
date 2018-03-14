if command -v brew &>/dev/null; then

  # Don't send analytics data
  export HOMEBREW_NO_ANALYTICS=1

  if [[ -s $(brew --prefix)/etc/profile.d/autojump.sh ]]; then
    . "$(brew --prefix)/etc/profile.d/autojump.sh"
  fi

  if [ -f "$(brew --prefix)/share/bash-completion/bash_completion" ]; then
    . "$(brew --prefix)/share/bash-completion/bash_completion"
  fi

  if [ -f "$(brew --repository)/etc/profile.d/z.sh" ]; then
    . "$(brew --repository)/etc/profile.d/z.sh"
  fi

  if [ -f "$(brew --repository)/bin/src-hilite-lesspipe.sh" ]; then
    export LESSOPEN
    LESSOPEN="| $(brew --repository)/bin/src-hilite-lesspipe.sh %s"
    export LESS=' -R -z-4'
  fi

  if [ -d "$(brew --cellar)/coreutils" ]; then
    # Use CoreUtils over native commands
    PATH="$(brew --prefix coreutils)/libexec/gnubin:$PATH"
    MANPATH="$(brew --prefix coreutils)/libexec/gnuman:$MANPATH"
  fi

  # /Applications is now the default but leaving this for posterity
  export HOMEBREW_CASK_OPTS="--appdir=/Applications"

  alias cask='brew cask'
  alias brwe='brew' #typos

  bup() {
    local brewScript="${HOME}/bin/updateHomebrew"
    if [ -e "${brewScript}" ]; then
      "${brewScript}"
    else
      brew update
      brew upgrade
      brew cleanup
      brew cask cleanup
      brew prune
    fi
  }

fi
