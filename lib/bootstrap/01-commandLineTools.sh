
info "Checking for Command Line Tools..."

if ! xcode-select --print-path &> /dev/null; then

  # Prompt user to install the XCode Command Line Tools
  xcode-select --install &> /dev/null

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # Wait until the XCode Command Line Tools are installed
  until xcode-select --print-path &> /dev/null; do
    sleep 5
  done

  success 'Install XCode Command Line Tools'

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # Point the `xcode-select` developer directory to
  # the appropriate directory from within `Xcode.app`
  # https://github.com/alrra/dotfiles/issues/13

  sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer
  notice 'Making "xcode-select" developer directory point to Xcode'

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # Prompt user to agree to the terms of the Xcode license
  # https://github.com/alrra/dotfiles/issues/10

  sudo xcodebuild -license
  notice 'Agree with the XCode Command Line Tools licence'

else
  success "Command Line Tools installed"
fi

# #######
# Alternative method. Depreciated but left her for posterity
# #######

# if [[ ! "$(type -P gcc)" || ! "$(type -P make)" ]]; then
#   local osx_vers=$(sw_vers -productVersion | awk -F "." '{print $2}')
#   local cmdLineToolsTmp="${tmpDir}/.com.apple.dt.CommandLineTools.installondemand.in-progress"

#   # Create the placeholder file which is checked by the software update tool
#   # before allowing the installation of the Xcode command line tools.
#   touch "${cmdLineToolsTmp}"

#   # Find the last listed update in the Software Update feed with "Command Line Tools" in the name
#   cmd_line_tools=$(softwareupdate -l | awk '/\*\ Command Line Tools/ { $1=$1;print }' | tail -1 | sed 's/^[[ \t]]*//;s/[[ \t]]*$//;s/*//' | cut -c 2-)

#   _execute_ "softwareupdate -i ${cmd_line_tools} -v"

#   # Remove the temp file
#   if [ -f "${cmdLineToolsTmp}" ]; then
#     rm ${v} "${cmdLineToolsTmp}"
#   fi
# fi

# success "Command Line Tools installed"
