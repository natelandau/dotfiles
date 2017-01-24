
info "Checking for RVM (Ruby Version Manager)..."

RUBYVERSION="2.1.2" # Version of Ruby to install via RVM

# Check for RVM
if ! command -v rvm &> /dev/null; then
  if seek_confirmation "Couldn't find RVM. Install it?"; then
    execute "curl -L https://get.rvm.io | bash -s stable --ruby"
    execute "source ${HOME}/.rvm/scripts/rvm"
    execute "source ${HOME}/.bash_profile"
    #rvm get stable --autolibs=enable
    execute "rvm install ${RUBYVERSION}"
    execute "rvm use ${RUBYVERSION} --default"
  fi
fi

success "RVM and Ruby are installed"
