
# Enable GO
if command -v go &>/dev/null ; then
  GOPATH=${HOME}/go; export GOPATH;
  GOBIN=${GOPATH}/bin; export GOBIN;
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

# Path for Ruby (installed by Homebrew)
#export PATH="$PATH:/usr/local/opt/ruby/bin"

if command -v thefuck &>/dev/null; then
  eval "$(thefuck --alias)"
fi

# Run Archey on load
# if type -P archey &>/dev/null; then
#   archey
# fi

# Docker
# if type -P docker-machine &>/dev/null; then
#   eval "$(docker-machine env default)"
# fi