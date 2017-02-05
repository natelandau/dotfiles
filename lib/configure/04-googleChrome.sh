_configureChrome_() {
  info "Configuring Google-Chrome..."

  execute "defaults write com.google.Chrome DisablePrintPreview -bool true" "Use the system-native print preview dialog"
  execute "defaults write com.google.Chrome.canary DisablePrintPreview -bool true"
}
_executeFunction_ "_configureChrome_" "Configure Google Chrome"