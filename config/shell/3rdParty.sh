# Make 'less' more with lesspipe
[[ "$(command -v lesspipe.sh)" ]] && eval "$(lesspipe.sh)"

# RVM complains if it's not here
[[ -s "${HOME}/.rvm/scripts/rvm" ]] && source "${HOME}/.rvm/scripts/rvm"

# ASDF Package Manager
[[ -s "$HOME/.asdf/asdf.sh" ]] && source "$HOME/.asdf/asdf.sh"
[[ -s "$HOME/.asdf/completions/asdf.bash" ]] && source "$HOME/.asdf/completions/asdf.bash"

#nvm (node version manager)
if [ -e "${HOME}/.nvm" ]; then
  export NVM_DIR="${HOME}/.nvm"
  [ -s "${NVM_DIR}/nvm.sh" ] && source "${NVM_DIR}/nvm.sh"
  # suorce completions with bash
  if [[ $currentShell == "bash" ]]; then
    [ -s "${NVM_DIR}/bash_completion" ] && source "${NVM_DIR}/bash_completion"
  fi
  nvm use 8.6.0
fi

# Default to use python 2.7 with npm
if command -v npm &>/dev/null; then
  npm config set python python2.7
fi

# Use Java JDK 1.8
if [[ "$(command -v java)" && -e "/usr/libexec/java_home" ]]; then
  export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
fi

# Path for Ruby (installed by Homebrew)
#export PATH="$PATH:/usr/local/opt/ruby/bin"

[[ "$(command -v thefuck)" ]] \
  && eval "$(thefuck --alias)"

# [[ "$(command -v archey)" ]] && archey

[[ "$(command -v docker-machine)" ]] \
  && eval "$(docker-machine env default)"

# Add python bin to PATH
PATH="/Users/nlandau/Library/Python/3.7/bin:${PATH}"

# Git-Friendly Auto Completions
# https://github.com/jamiew/git-friendly
if [[ $currentShell == "bash" ]]; then
  if type __git_complete &>/dev/null; then
    _branch() {
      delete="${words[1]}"
      if [ "$delete" == "-d" ] || [ "$delete" == "-D" ]; then
        _git_branch
      else
        _git_checkout
      fi
    }
    __git_complete branch _branch
    __git_complete merge _git_merge
  fi
elif [[ $currentShell == "zsh" ]] && [[ "$OSTYPE" == "darwin"* ]]; then
  fpath=($(brew --prefix)/share/zsh/functions "${fpath}")
  autoload -Uz _git && _git
  compdef __git_branch_names branch
fi
