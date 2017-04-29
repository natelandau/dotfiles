
# Enable GO
if command -v go &>/dev/null ; then
  export GOPATH=${HOME}/go
fi

# Make 'less' more with lesspipe
[[ "$(command -v lesspipe.sh)" ]] && eval "$(lesspipe.sh)"

# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
[[ -s "$HOME/.rvm/scripts/rvm" ]] && export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

#Path for Ruby (installed by Homebrew)
export PATH="$PATH:/usr/local/opt/ruby/bin"

if command -v thefuck &>/dev/null; then
  eval "$(thefuck --alias)"
fi

## SOURCE HOMEBREW PACKAGES, if installed ##
if command -v brew &>/dev/null ; then

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
fi

# Run Archey on load
# if type -P archey &>/dev/null; then
#   archey
# fi

# Docker
# if type -P docker-machine &>/dev/null; then
#   eval "$(docker-machine env default)"
# fi