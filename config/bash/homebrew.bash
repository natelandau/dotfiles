if command -v brew &>/dev/null ; then
  alias cask='brew cask'
  alias brwe='brew'  #typos

bup() {
  brew update
  brew upgrade
  [ -e "${HOME}/bin/upgradeCasks" ] && ${HOME}/bin/upgradeCasks
  brew cleanup
  brew cask cleanup
  brew prune
}

fi
