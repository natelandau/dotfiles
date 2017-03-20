
info "Checking for RVM (Ruby Version Manager)..."

RUBYVERSION="2.1.2" # Version of Ruby to install via RVM

# Check for RVM
if ! command -v rvm &> /dev/null; then
  if _seekConfirmation_ "Couldn't find RVM. Install it?"; then
    _execute_ "curl -L https://get.rvm.io | bash -s stable --ruby"
    _execute_ "source ${HOME}/.rvm/scripts/rvm"
    _execute_ "source ${HOME}/.bash_profile"
    #rvm get stable --autolibs=enable
    _execute_ "rvm install ${RUBYVERSION}"
    _execute_ "rvm use ${RUBYVERSION} --default"
  fi
fi

success "RVM and Ruby are installed"
