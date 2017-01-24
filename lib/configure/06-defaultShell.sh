
info "Configuring Homebrew's Bash..."

# This is where brew stores its binary symlinks
binroot="$(brew --config | awk '/HOMEBREW_PREFIX/ {print $2}')"/bin

if command -v ${binroot}/bash >/dev/null; then

  if ! grep -q "$binroot/bash" < /etc/shells; then
    info "Making ${binroot}/bash your default shell"
    execute "echo "$binroot/bash" | sudo tee -a /etc/shells >/dev/null"
    execute "sudo chsh -s "${binroot}/bash" $USER >/dev/null 2>&1"
    notice "Restart your shells to use Homebrew's bash"
  else
    execute "sudo chsh -s "${binroot}/bash" $USER >/dev/null 2>&1"
    notice "Restart your shells to use Homebrew's bash"
  fi
else
  warning "Must have Homebrew Bash installed. skipping..."
fi