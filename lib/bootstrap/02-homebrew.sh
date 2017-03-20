
info "Checking for Homebrew..."

if ! command -v brew &> /dev/null; then
  notice "Installing Homebrew..."
  #   Ensure that we can actually, like, compile anything.
  if [[ ! $(command -v gcc) && "$OSTYPE" =~ ^darwin ]]; then
    die "XCode or the Command Line Tools for XCode must be installed first."
  fi
  # Check for Git
  if [ ! "$(command -v git)" ]; then
    die "XCode or the Command Line Tools for XCode must be installed first."
  fi

  # Install Homebrew
  _execute_ "ruby -e $(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" "Install Homebrew"
else
  success "Homebrew installed"
fi
