if [[ "$OSTYPE" == "darwin"* ]]; then
  _configureChrome_() {
    info "Configuring Google-Chrome..."

    _execute_ "defaults write com.google.Chrome DisablePrintPreview -bool true" "Use the system-native print preview dialog"
    _execute_ "defaults write com.google.Chrome.canary DisablePrintPreview -bool true"
  }
  _configureChrome_
fi