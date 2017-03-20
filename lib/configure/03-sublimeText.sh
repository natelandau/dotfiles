_configureSublimeText3_() {
  # This script symlinks the 'subl' CLI tool to /usr/local/bin

  info "Sublime Text 3: symlink 'subl' to /usr/local/bin ..."

  if [ ! -e "/Applications/Sublime Text.app" ]; then
    warning "We don't have Sublime Text.app. Install it and try again."
  else
    if [ ! -e "/usr/local/bin/subl" ]; then
      _execute_ "ln -s /Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl /usr/local/bin/subl" "Symlink subl to /user/local/bin/subl"
    else
      notice "Symlink already exists. Nothing done."
    fi
  fi
}
_configureSublimeText3_