
info "Configuring iTerm..."

 if ! [ -e /Applications/iTerm.app ]; then
  warning "Could not find iTerm.app. Please install iTerm and run this again."
else

  execute "defaults write com.apple.terminal StringEncodings -array 4" "Only use UTF-8 in Terminal.app"

  execute "defaults write com.googlecode.iterm2 PromptOnQuit -bool false" "Don’t display the annoying prompt when quitting iTerm"

  execute "open ${baseDir}/config/iTerm/themes/nate.itermcolors" "Installing preferred color scheme"
fi