# Enable GO
if command -v go &>/dev/null; then
  GOPATH=${HOME}/go
  export GOPATH
  GOBIN=${GOPATH}/bin
  export GOBIN
  export PATH="$PATH:${GOBIN}"
fi

# Make 'less' more with lesspipe
[[ "$(command -v lesspipe.sh)" ]] && eval "$(lesspipe.sh)"

# RVM complains if it's not here
[[ -s "${HOME}/.rvm/scripts/rvm" ]] && source "${HOME}/.rvm/scripts/rvm"

#nvm (node version manager)
if [ -e "${HOME}/.nvm" ]; then
  export NVM_DIR="${HOME}/.nvm"
  [ -s "${NVM_DIR}/nvm.sh" ] && source "${NVM_DIR}/nvm.sh"
  [ -s "${NVM_DIR}/bash_completion" ] && source "${NVM_DIR}/bash_completion"
  nvm use 8.6.0
fi

# Use Java JDK 1.8
[[ "$(command -v java)" ]] && export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)

# Path for Ruby (installed by Homebrew)
#export PATH="$PATH:/usr/local/opt/ruby/bin"

[[ "$(command -v thefuck)" ]] && eval "$(thefuck --alias)"

# [[ "$(command -v archey)" ]] && archey

[[ "$(command -v docker-machine)" ]] && eval "$(docker-machine env default)"