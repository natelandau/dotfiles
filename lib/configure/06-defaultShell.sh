# This is where brew stores its binary symlinks
binroot="$(brew --config | awk '/HOMEBREW_PREFIX/ {print $2}')"/bin
if command -v ${binroot}/bash >/dev/null; then
  if [[ $SHELL != ${binroot}/bash ]]; then
    _configureDefaultShell_() {
      info "Configuring Homebrew's Bash..."

        if ! grep -q "$binroot/bash" < /etc/shells; then
          info "Making ${binroot}/bash your default shell"
          execute "echo "$binroot/bash" | sudo tee -a /etc/shells >/dev/null"
          execute "sudo chsh -s "${binroot}/bash" $USER >/dev/null 2>&1"
          notice "Restart your shells to use Homebrew's bash"
        else
          execute "sudo chsh -s "${binroot}/bash" $USER >/dev/null 2>&1"
          notice "Restart your shells to use Homebrew's bash"
        fi
    }
    _executeFunction_ "_configureDefaultShell_" "Set Homebrew Bash as your default shell"
  fi
fi