#!/usr/bin/env bash

_mainScript_() {

  [[ "$OSTYPE" != "darwin"* ]] \
    && fatal "We are not on macOS" "$LINENO"

  gitRoot="$(git rev-parse --show-toplevel)" \
    && verbose "gitRoot: ${gitRoot}"

  _commandLineTools_() {
    # DESC:   Install XCode command line tools if needed
    # ARGS:   None
    # OUTS:   None

    info "Checking for Command Line Tools..."

    if ! xcode-select --print-path &>/dev/null; then

      # Prompt install of XCode Command Line Tools
      xcode-select --install >/dev/null 2>&1

      # Wait till XCode Command Line Tools are installed
      until xcode-select --print-path &>/dev/null 2>&1; do
        sleep 5
      done

      local x=$(find '/Applications' -maxdepth 1 -regex '.*/Xcode[^ ]*.app' -print -quit)
      if [ -e "$x" ]; then
        sudo xcode-select -s "$x"
        sudo xcodebuild -license accept
      fi
      success 'Install XCode Command Line Tools'
    else
      success "Command Line Tools installed"
    fi
  }
  _commandLineTools_

  _symlinks_() {
    # DESC:   Creates symlinks to dotfiles and custom scripts
    # ARGS:   None
    # OUTS:   None

    _seekConfirmation_ "Create symlinks to dotfiles and custom scripts?" || return 0
    header "Creating Symlinks"

    # Dotfiles
    _makeSymlink_ "${gitRoot}/config/dotfiles/asdfrc"               "${HOME}/.asdfrc"
    _makeSymlink_ "${gitRoot}/config/dotfiles/bash_profile"         "${HOME}/.bash_profile"
    _makeSymlink_ "${gitRoot}/config/dotfiles/bashrc"               "${HOME}/.bashrc"
    _makeSymlink_ "${gitRoot}/config/dotfiles/curlrc"               "${HOME}/.curlrc"
    _makeSymlink_ "${gitRoot}/config/dotfiles/Gemfile"              "${HOME}/.Gemfile"
    _makeSymlink_ "${gitRoot}/config/dotfiles/gemrc"                "${HOME}/.gemrc"
    _makeSymlink_ "${gitRoot}/config/dotfiles/gitattributes"        "${HOME}/.gitattributes"
    _makeSymlink_ "${gitRoot}/config/dotfiles/gitconfig"            "${HOME}/.gitconfig"
    _makeSymlink_ "${gitRoot}/config/dotfiles/gitignore"            "${HOME}/.gitignore"
    _makeSymlink_ "${gitRoot}/config/dotfiles/hushlogin"            "${HOME}/.hushlogin"
    _makeSymlink_ "${gitRoot}/config/dotfiles/inputrc"              "${HOME}/.inputrc"
    _makeSymlink_ "${gitRoot}/config/dotfiles/micro/bindings.json"  "${HOME}/.config/micro/bindings.json"
    _makeSymlink_ "${gitRoot}/config/dotfiles/micro/settings.json"  "${HOME}/.config/micro/settings.json"
    _makeSymlink_ "${gitRoot}/config/dotfiles/profile"              "${HOME}/.profile"
    _makeSymlink_ "${gitRoot}/config/dotfiles/ruby-version"         "${HOME}/.ruby-version"
    _makeSymlink_ "${gitRoot}/config/dotfiles/sed"                  "${HOME}/.sed"
    _makeSymlink_ "${gitRoot}/config/dotfiles/zsh_plugins.txt"      "${HOME}/.zsh_plugins.txt"
    _makeSymlink_ "${gitRoot}/config/dotfiles/zshrc"                "${HOME}/.zshrc"

    # Custom Scripts
    _makeSymlink_ "${gitRoot}/bin/cleanFilenames"   "${HOME}/bin/cleanFilenames"
    _makeSymlink_ "${gitRoot}/bin/convertVideo"     "${HOME}/bin/convertVideo"
    _makeSymlink_ "${gitRoot}/bin/git-churn"        "${HOME}/bin/git-churn"
    _makeSymlink_ "${gitRoot}/bin/hashCheck.sh"     "${HOME}/bin/hashCheck"
    _makeSymlink_ "${gitRoot}/bin/lessfilter.sh"    "${HOME}/bin/lessfilter.sh"
    _makeSymlink_ "${gitRoot}/bin/mailReIndex"      "${HOME}/bin/mailReIndex"
    _makeSymlink_ "${gitRoot}/bin/newscript.sh"     "${HOME}/bin/newscript"
    _makeSymlink_ "${gitRoot}/bin/removeSymlink"    "${HOME}/bin/removeSymlink"
    _makeSymlink_ "${gitRoot}/bin/seconds"          "${HOME}/bin/seconds"
    _makeSymlink_ "${gitRoot}/bin/trash"            "${HOME}/bin/trash"
    _makeSymlink_ "${gitRoot}/bin/unlockFile"       "${HOME}/bin/unlockFile"
    _makeSymlink_ "${gitRoot}/bin/updateHomebrew"   "${HOME}/bin/updateHomebrew"
    _makeSymlink_ "${gitRoot}/bin/wolcmd"           "${HOME}/bin/wolcmd"
    _makeSymlink_ "${gitRoot}/bin/xld"              "${HOME}/bin/xld"
  }
  _symlinks_

  _homebrew_() {
    # DESC:   Installs Homebrew if necessary. Then installs packages, casks, and Mac apps via mas
    # ARGS:   None
    # OUTS:   None
    _seekConfirmation_ "Configure Homebrew and Install Packages?" || return 0

    info "Checking for Homebrew..."
    _checkForHomebrew_ || return 1

    # Uninstall old homebrew cask
    if brew list | grep -Fq brew-cask; then
      _execute_ -v "brew uninstall --force brew-cask" "Uninstalling old Homebrew-Cask ..."
    fi

    header "Updating Homebrew"
    _execute_ -v "caffeinate -ism brew update"
    _execute_ -vp "caffeinate -ism brew doctor"
    _execute_ -vp "caffeinate -ism brew upgrade"

    _execute_ -vp "brew analytics off" "Disable Homebrew analytics"

    #Base Install
      _execute_ -vp "brew tap getantibody/tap"
      _execute_ -vp "brew tap homebrew/cask"
      _execute_ -vp "brew tap homebrew/cask-drivers"
      _execute_ -vp "brew tap homebrew/cask-versions"
      _execute_ -vp "brew install autoconf"
      _execute_ -vp "brew install autojump"
      _execute_ -vp "brew install automake"
      _execute_ -vp "brew install bash-completion@2"
      _execute_ -vp "brew install bash"
      _execute_ -vp "brew install bashdb"
      _execute_ -vp "brew install bat"
      _execute_ -vp "brew install bats"
      _execute_ -vp "brew install colordiff"
      _execute_ -vp "brew install coreutils"
      _execute_ -vp "brew install curl"
      _execute_ -vp "brew install exa"
      _execute_ -vp "brew install fping"
      _execute_ -vp "brew install getantibody/tap/antibody"
      _execute_ -vp "brew install git-extras"
      _execute_ -vp "brew install git-flow"
      _execute_ -vp "brew install git"
      _execute_ -vp "brew install gnu-sed"
      _execute_ -vp "brew install gnupg"
      _execute_ -vp "brew install htop"
      _execute_ -vp "brew install httpie"
      _execute_ -vp "brew install jq"
      _execute_ -vp "brew install lesspipe"
      _execute_ -vp "brew install libtool"
      _execute_ -vp "brew install mas"
      _execute_ -vp "brew install micro"
      _execute_ -vp "brew install openssl"
      _execute_ -vp "brew install prettyping"
      _execute_ -vp "brew install readline"
      _execute_ -vp "brew install shellcheck"
      _execute_ -vp "brew install shfmt"
      _execute_ -vp "brew install source-highlight"
      _execute_ -vp "brew install ssh-copy-id"
      _execute_ -vp "brew install thefuck"
      _execute_ -vp "brew install tldr"
      _execute_ -vp "brew install tree"
      _execute_ -vp "brew install wget"
      _execute_ -vp "brew install zsh"
      _execute_ -vp "brew cask install alfred"
      _execute_ -vp "brew cask install istat-menus"
      _execute_ -vp "brew cask install iterm2"
      _execute_ -vp "brew cask install keybase"

    _brewMedia_() {
      _seekConfirmation_ "Homebrew installs for media editing?" || return 0
      _execute_ -vp "brew install exiftool"
      _execute_ -vp "brew install ffmpeg"
      _execute_ -vp "brew install gifsicle"
      _execute_ -vp "brew install id3tool"
      _execute_ -vp "brew cask install xld"
    }
    _brewMedia_

    _brewDevelopment_() {
      _seekConfirmation_ "Homebrew installs for development?" || return 0
      _execute_ -vp "brew tap cloudflare/cloudflare"
      _execute_ -vp "brew install cloudflare/cloudflare/cloudflared"
      _execute_ -vp "brew install diff-so-fancy"
      _execute_ -vp "brew install ghi"
      _execute_ -vp "brew install guetzli"
      _execute_ -vp "brew install imagemagick@6 && brew link -f imagemagick@6"
      _execute_ -vp "brew install jpegoptim"
      _execute_ -vp "brew install libyaml"
      _execute_ -vp "brew install optipng"
      _execute_ -vp "brew install pngcrush"
      _execute_ -vp "brew install yarn"
      _execute_ -vp "brew cask install codekit"
      _execute_ -vp "brew cask install fork"
      _execute_ -vp "brew cask install imagealpha"
      _execute_ -vp "brew cask install imageoptim"
      _execute_ -vp "brew cask install kaleidoscope"
      _execute_ -vp "brew cask install ngrok"
      _execute_ -vp "brew cask install paw"
      _execute_ -vp "brew cask install tower2"
      _execute_ -vp "brew cask install visual-studio-code"
      _execute_ -vp "mas install 498944723"   # JPEGmini
    }
    _brewDevelopment_

    _brewPrimaryComputers_() {
      _seekConfirmation_ "Homebrew installs for primary computers?" || return 0
      _execute_ -vp "brew install pam_yubico"
      _execute_ -vp "brew cask install discord"
      _execute_ -vp "brew cask install fantastical"
      _execute_ -vp "brew cask install firefox"
      _execute_ -vp "brew cask install hazel"
      _execute_ -vp "brew cask install iina"
      _execute_ -vp "brew cask install mailplane"
      _execute_ -vp "brew cask install marked"
      _execute_ -vp "brew cask install moom"
      _execute_ -vp "brew cask install nvalt"
      _execute_ -vp "brew cask install omnifocus"
      _execute_ -vp "brew cask install plex"
      _execute_ -vp "brew cask install roon"
      _execute_ -vp "brew cask install shimo"
      _execute_ -vp "brew cask install slack"
      _execute_ -vp "brew cask install sonos"
      _execute_ -vp "brew cask install steam"
      _execute_ -vp "brew cask install tripmode"
      _execute_ -vp "brew cask install vlc"
      _execute_ -vp "brew cask install yubico-authenticator"
      _execute_ -vp "brew cask install yubico-yubikey-manager"
      _execute_ -vp "mas install 1107421413"    # 1Blocker
      _execute_ -vp "mas install 1091189122"    # Bear
      _execute_ -vp "mas install 696977615"     # Capo
      _execute_ -vp "mas install 1094748271"    # Contacts+
      _execute_ -vp "mas install 1435957248"    # Drafts
      _execute_ -vp "mas install 409183694"     # Keynote
      _execute_ -vp "mas install 409203825"     # Numbers
      _execute_ -vp "mas install 1153157709"    # Speedtest

    }
    _brewPrimaryComputers_

    _execute_ -vp "brew cleanup"
    _execute_ -vp "brew cask cleanup"
    _execute_ -vp "brew prune"
  }
  _homebrew_

  _ruby_() {

    _seekConfirmation_ "Install Ruby and Gems?" || return 0

    _checkASDF_ \
      && success "have asdf" \
      || return 1

    local RUBYVERSION="2.6.3"
    local gemfile="${gitRoot}/config/dotfiles/Gemfile"

    header "Installing Ruby and Gems ..."
    _installASDFPlugin_ "ruby" "https://github.com/asdf-vm/asdf-ruby.git" \
      || {
        warning "Could not install ruby plugin"
        return 1
      }

    _installASDFLanguage_ "ruby" "${RUBYVERSION}" \
      || {
        warning "Could not install ruby language"
        return 1
      }

    info "Installing gems ..."
    pushd "${HOME}" &>/dev/null

    _execute_ -v "gem update --system"
    _execute_ -v "gem install bundler"  # Ensure we have bundler installed

    local numberOfCores=$(sysctl -n hw.ncpu)
    _execute_ -v "bundle config --global jobs $((numberOfCores - 1))"

    if [ -f "${gemfile}" ]; then
      info "Installing ruby gems (this may take a while) ..."
      _execute_ -vp "caffeinate -ism bundle install --gemfile \"${gemfile}\""
    else
      error "Could not find Gemfile. Unable to install ruby gems." "${LINENO}"
      verbose "Expected to find Gemfile at '${gemfile}'"
    fi

    # Ensure all these new items are in $PATH
    _execute_ -v "asdf reshim ruby"

    popd &>/dev/null
  }
  _ruby_ || warning "Failed to install ruby"

  _nodeJS_() {
    _seekConfirmation_ "Install node.js and packages??" || return 0

    _checkASDF_ \
      && success "have asdf" \
      || return 1

    header "Installing node.js ..."

    _installASDFPlugin_ "nodejs" "https://github.com/asdf-vm/asdf-nodejs.git" \
      || {
        warning "Could not install nodejs plugin"
        return 1
      }

    # Install the GPG Key
    _execute_ -v "bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring"

    _installASDFLanguage_ "nodejs"  \
      || {
        warning "Could not install nodejs language"
        return 1
      }

    pushd "${HOME}" &>/dev/null
    notice "Installing npm packages ..."

    popd &>/dev/null

    # Ensure all these new items are in $PATH
    _execute_ -v "asdf reshim nodejs"
  }
  _nodeJS_ || warning "Failed to install nodeJS"

  _configureITerm2_() {
    _seekConfirmation_ "Configure iTerm2?" || return 0

    if ! [ -e /Applications/iTerm.app ]; then
      if ! _execute_ -vp "brew cask install iterm2"; then
        warning "Could not find iTerm.app. Please install iTerm and run this again."
      fi
      return
    else
      # iTerm config files location
      local iTermConfig="${gitRoot}/config/iTerm"

      if [ -d "${iTermConfig}" ]; then

        # Copy fonts
        local fontLocation="${HOME}/Library/Fonts"
        local font
        for font in "${iTermConfig}"/fonts/**/*.otf; do
          local baseFontName="$(basename "$font")"
          local destFile="${fontLocation}/${baseFontName}"
          if [ ! -e "${destFile}" ]; then
            _execute_ "cp \"${font}\" \"${destFile}\""
          fi
        done

        # Symlink preferences
        local sourceFile="${iTermConfig}/com.googlecode.iterm2.plist"
        local destFile="${HOME}/Library/Preferences/com.googlecode.iterm2.plist"

        _makeSymlink_ "${sourceFile}" "${destFile}"


        # if [ ! -e "$destFile" ]; then
        #   _execute_ "cp \"${sourceFile}\" \"${destFile}\"" "cp $sourceFile → $destFile"
        # elif [ -h "$destFile" ]; then
        #   originalFile=$(_locateSourceFile_ "$destFile")
        #   _backupFile_ "$originalFile"
        #   if ! $dryrun; then rm -rf "$destFile"; fi
        #   _execute_ "cp \"$sourceFile\" \"$destFile\"" "cp $sourceFile → $destFile"
        # elif [ -e "$destFile" ]; then
        #   _backupFile_ "$destFile"
        #   if ! $dryrun; then rm -rf "$destFile"; fi
        #   _execute_ "cp \"$sourceFile\" \"$destFile\"" "cp $sourceFile → $destFile"
        # else
        #   warning "Error linking: $sourceFile → $destFile"
        # fi

        #3 Install preferred colorscheme
        _execute_ "open ${rootDIR}/config/iTerm/themes/dotfiles.itermcolors" "Installing preferred color scheme"
      else
        warning "Could not find iTerm configuration files"
      fi
    fi
  }
  _configureITerm2_

  _installGitHooks_() {
    _seekConfirmation_ "Install git hooks?" || return 0

    local hooksLocation="${gitRoot}/.hooks"

    [ -d "${hooksLocation}" ] \
      || {
        warning "Can't find hooks. Exiting."
        return
    }

    local h
    while read -r h; do
      h="$(basename ${h})"
      [[ -L "${gitRoot}/.git/hooks/${h%.sh}" ]] \
        || _makeSymlink_ -n "${hooksLocation}/${h}" "${gitRoot}/.git/hooks/${h%.sh}"
    done < <(find "${hooksLocation}" -name "*.sh" -type f -maxdepth 1 | sort)

  }
  _installGitHooks_

  _installGitFriendly_() {
    _seekConfirmation_ "Install git-friendly?" || return 0
    # github.com/jamiew/git-friendly
    # the `push` command which copies the github compare URL to my clipboard is heaven
    bash < <(sudo curl https://raw.github.com/jamiew/git-friendly/master/install.sh)
  }
  _installGitFriendly_

  _macSystemPrefs_() {
    _seekConfirmation_ "Set mac system preference defaults?" || return 0
    sudo -v # Ask for sudo privs up-front

    if _seekConfirmation_ "Would you like to set your computer name (as done via System Preferences >> Sharing)?"; then
      input "What would you like the name to be? "
      read -r COMPUTER_NAME
      sudo scutil --set ComputerName "${COMPUTER_NAME}"
      sudo scutil --set HostName "${COMPUTER_NAME}"
      sudo scutil --set LocalHostName "${COMPUTER_NAME}"
      sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "${COMPUTER_NAME}"
    fi

    # General UI Tweaks
    # ---------------------------
    info "Disable Sound Effects on Boot"
    sudo nvram SystemAudioVolume=' '

    info "Get snappier save sheets"
    defaults write NSGlobalDomain NSWindowResizeTime .001

    info "Set highlight color to yellow"
    defaults write NSGlobalDomain AppleHighlightColor -string '0.984300 0.929400 0.450900'

    info "Set sidebar icon size to small"
    defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 1
    # Possible values for int: 1=small, 2=medium

    info "Always show scrollbars"
    defaults write NSGlobalDomain AppleShowScrollBars -string 'Always'
    # Possible values: `WhenScrolling`, `Automatic` and `Always`

    #info "Disable transparency in the menu bar and elsewhere"
    #defaults write com.apple.universalaccess reduceTransparency -bool true

    info "Disable opening and closing window animations"
    defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

    info "Expand save panel by default"
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

    info "Expand print panel by default"
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

    info "Save to disk (not to iCloud) by default"
    defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

    info "Automatically quit printer app once the print jobs complete"
    defaults write com.apple.print.PrintingPrefs 'Quit When Finished' -bool true

    info "Disable the 'Are you sure you want to open this application?' dialog"
    defaults write com.apple.LaunchServices LSQuarantine -bool false

    # Try e.g. `cd /tmp; unidecode "\x{0000}" > cc.txt; open -e cc.txt`
    info "General:Display ASCII control characters using caret notation in standard text views"
    defaults write NSGlobalDomain NSTextShowsControlCharacters -bool true

    info "Disable automatic termination of inactive apps"
    defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

    info "Disable Resume system-wide"
    defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false

    defaults write com.apple.helpviewer DevMode -bool true

    info "Reveal info when clicking the clock in the login window"
    sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

    #info "Restart automatically if the computer freezes"
    #systemsetup -setrestartfreeze on

    #info "Never go into computer sleep mode"
    #systemsetup -setcomputersleep Off > /dev/null

    info "Check for software updates daily, not just once per week"
    defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

    #info "Disable Notification Center and remove the menu bar icon"
    #launchctl unload -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist 2> /dev/null

    info "Disable smart quotes as they are annoying when typing code"
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

    info "Disable smart dashes as they are annoying when typing code"
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

    # info "Removing duplicates in the 'Open With' menu"
    #/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user

    #info "Disable hibernation? (speeds up entering sleep mode)"
    #sudo pmset -a hibernatemode 0

    # Input Device Preferences
    # ---------------------------

    #info "Trackpad: enable tap to click for this user and for the login screen"
    # defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    # defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    # defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

    # info "Trackpad: map bottom right corner to right-click"
    # defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
    # defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
    # defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
    # defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

    # info "Disable “natural” (Lion-style) scrolling"
    # defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

    info "Setting trackpad & mouse speed to a reasonable number"
    defaults write -g com.apple.trackpad.scaling 2
    defaults write -g com.apple.mouse.scaling 2.5

    info "Increase sound quality for Bluetooth headphones/headsets"
    defaults write com.apple.BluetoothAudioAgent 'Apple Bitpool Min (editable)' -int 40

    info "Enable full keyboard access for all controls"
    defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

    # info "Use scroll gesture with the Ctrl (^) modifier key to zoom"
    # defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true

    # info "Use scroll gesture with the Ctrl (^) modifier key to zoom"
    # defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144

    # info "Follow the keyboard focus while zoomed in"
    # defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true

    info "Disable press-and-hold for keys in favor of key repeat"
    defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

    info "Set a blazingly fast keyboard repeat rate"
    defaults write NSGlobalDomain KeyRepeat -int 1

    info "Set a shorter Delay until key repeat"
    defaults write NSGlobalDomain InitialKeyRepeat -int 12

    info "Automatically illuminate built-in MacBook keyboard in low light"
    defaults write com.apple.BezelServices kDim -bool true

    info "Turn off keyboard illumination when computer is not used for 5 minutes"
    defaults write com.apple.BezelServices kDimTime -int 300

    info "Set language and text formats"
    # Note: if you’re in the US, replace `EUR` with `USD`, `Centimeters` with
    # `Inches`, `en_GB` with `en_US`, and `true` with `false`.
    defaults write NSGlobalDomain AppleLanguages "(en-US)"
    defaults write NSGlobalDomain AppleLocale -string "en_US@currency=USD"
    defaults write NSGlobalDomain AppleMeasurementUnits -string "Inches"
    defaults write NSGlobalDomain AppleMetricUnits -bool false

    info "Set the timezone to New York"
    systemsetup -settimezone "America/New_York" >/dev/null
    #see `systemsetup -listtimezones` for other values

    # info "Disable spelling auto-correct"
    # defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

    # info "Stop iTunes from responding to the keyboard media keys"
    #launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist 2> /dev/null

    # Screen Preferences
    # ---------------------------

    info "Require password immediately after sleep or screen saver begins"
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0

    info "Save screenshots to the desktop"
    defaults write com.apple.screencapture location -string ${HOME}/Desktop

    info "Save screenshots in PNG format"
    defaults write com.apple.screencapture type -string 'png'
    # other options: BMP, GIF, JPG, PDF, TIFF, PNG

    #info "Disable shadow in screenshots"
    #defaults write com.apple.screencapture disable-shadow -bool true

    info "Enable subpixel font rendering on non-Apple LCDs"
    defaults write NSGlobalDomain AppleFontSmoothing -int 2

    info "Enabling HiDPI display modes (requires restart)"
    sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true

    # Screen Preferences
    # ---------------------------
    info "Finder: allow quitting via ⌘ + Q"
    defaults write com.apple.finder QuitMenuItem -bool true

    info "Finder: disable window animations and Get Info animations"
    defaults write com.apple.finder DisableAllAnimations -bool true

    # For other paths, use `PfLo` and `file:///full/path/here/`
    info "Set Home Folder as the default location for new Finder windows 1"
    defaults write com.apple.finder NewWindowTarget -string "PfHm"

    info "Set Home Folder as the default location for new Finder windows 2"
    defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

    info "Show icons for hard drives, servers, and removable media on the desktop"
    defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
    defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
    defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
    defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

    #info "Finder: show hidden files by default"
    #defaults write com.apple.finder AppleShowAllFiles -bool true

    info "Finder: show all filename extensions"
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true

    info "Finder: show status bar"
    defaults write com.apple.finder ShowStatusBar -bool true

    info "Finder: show path bar"
    defaults write com.apple.finder ShowPathbar -bool true

    info "Finder: allow text selection in Quick Look"
    defaults write com.apple.finder QLEnableTextSelection -bool true

    #info "Display full POSIX path as Finder window title"
    #defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

    info "When performing a search, search the current folder by default"
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

    info "Disable the warning when changing a file extension"
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

    info "Enable spring loading for directories"
    defaults write NSGlobalDomain com.apple.springing.enabled -bool true

    info "Remove the spring loading delay for directories"
    defaults write NSGlobalDomain com.apple.springing.delay -float 0

    info "Avoid creating .DS_Store files on network volumes"
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

    info "Disable disk image verification"
    defaults write com.apple.frameworks.diskimages skip-verify -bool true
    defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
    defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

    # info "Automatically open a new Finder window when a volume is mounted"
    # defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
    # defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
    # defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

    info "Show item info to the right of the icons on the desktop"
    /usr/libexec/PlistBuddy -c "Set DesktopViewSettings:IconViewSettings:labelOnBottom false" ~/Library/Preferences/com.apple.finder.plist

    info "Enable snap-to-grid for icons on the desktop and in other icon views"
    /usr/libexec/PlistBuddy -c "Set DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
    /usr/libexec/PlistBuddy -c "Set StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist

    info "Increase grid spacing for icons on the desktop and in other icon views"
    /usr/libexec/PlistBuddy -c "Set DesktopViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist
    /usr/libexec/PlistBuddy -c "Set StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist

    info "Increase the size of icons on the desktop and in other icon views"
    /usr/libexec/PlistBuddy -c "Set DesktopViewSettings:IconViewSettings:iconSize 40" ~/Library/Preferences/com.apple.finder.plist
    /usr/libexec/PlistBuddy -c "Set StandardViewSettings:IconViewSettings:iconSize 40" ~/Library/Preferences/com.apple.finder.plist

    info "Use column view in all Finder windows by default"
    defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
    # Four-letter codes for the other view modes: `icnv`, `clmv`, `Flwv`, `Nlsv`

    info "Disable the warning before emptying the Trash"
    defaults write com.apple.finder WarnOnEmptyTrash -bool false

    # info "Empty Trash securely by default"
    # defaults write com.apple.finder EmptyTrashSecurely -bool true

    info "Show the ~/Library folder"
    chflags nohidden ${HOME}/Library

    info "Show the /Volumes folder"
    sudo chflags nohidden /Volumes

    #info "Remove Dropbox’s green checkmark icons in Finder"
    #file=/Applications/Dropbox.app/Contents/Resources/emblem-dropbox-uptodate.icns
    #[ -e "${file}" ] && mv -f "${file}" "${file}.bak"

    info "Expand File Info panes"
    # “General”, “Open with”, and “Sharing & Permissions”
    defaults write com.apple.finder FXInfoPanesExpanded -dict \
      General -bool true \
      OpenWith -bool true \
      Privileges -bool true

    # Enable AirDrop over Ethernet and on unsupported Macs running Lion
    # defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

    # Dock & Dashboard Preferences
    # ---------------------------
    info "Enable highlight hover effect for the grid view of a stack"
    defaults write com.apple.dock mouse-over-hilite-stack -bool true

    info "Change minimize/maximize window effect"
    defaults write com.apple.dock mineffect -string "genie"

    info "Set the icon size of Dock items to 36 pixels"
    defaults write com.apple.dock tilesize -int 36

    info "Show only open applications in the Dock"
    defaults write com.apple.dock static-only -bool true

    info "Minimize windows into their application’s icon"
    defaults write com.apple.dock minimize-to-application -bool true

    info "Enable spring loading for all Dock items"
    defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

    info "Show indicator lights for open applications in the Dock"
    defaults write com.apple.dock show-process-indicators -bool true

    info "Wipe all (default) app icons from the Dock"
    # This is only really useful when setting up a new Mac, or if you don’t use
    # the Dock to launch apps.
    defaults write com.apple.dock persistent-apps -array

    info "Disable App Persistence (re-opening apps on login)"
    defaults write -g ApplePersistence -bool no

    info "Don’t animate opening applications from the Dock"
    defaults write com.apple.dock launchanim -bool false

    info "Speed up Mission Control animations"
    defaults write com.apple.dock expose-animation-duration -float 0.1

    # info "Don’t group windows by application in Mission Control"
    # # (i.e. use the old Exposé behavior instead)
    # defaults write com.apple.dock expose-group-by-app -bool false

    info "Disable Dashboard"
    defaults write com.apple.dashboard mcx-disabled -bool true

    info "Don’t show Dashboard as a Space"
    defaults write com.apple.dock dashboard-in-overlay -bool true

    # info "Don’t automatically rearrange Spaces based on most recent use"
    # defaults write com.apple.dock mru-spaces -bool false

    info "Remove the auto-hiding Dock delay"
    defaults write com.apple.dock autohide-delay -float 0

    info "Remove the animation when hiding/showing the Dock"
    defaults write com.apple.dock autohide-time-modifier -float 0

    info "Automatically hide and show the Dock"
    defaults write com.apple.dock autohide -bool true

    info "Make Dock icons of hidden applications translucent"
    defaults write com.apple.dock showhidden -bool true

    # Add a spacer to the left side of the Dock (where the applications are)
    #defaults write com.apple.dock persistent-apps -array-add '{tile-data={}; tile-type="spacer-tile";}'
    # Add a spacer to the right side of the Dock (where the Trash is)
    #defaults write com.apple.dock persistent-others -array-add '{tile-data={}; tile-type="spacer-tile";}'

    info "Disabled hot corners"
    # Possible values:
    #  0: no-op
    #  2: Mission Control
    #  3: Show application windows
    #  4: Desktop
    #  5: Start screen saver
    #  6: Disable screen saver
    #  7: Dashboard
    # 10: Put display to sleep
    # 11: Launchpad
    # 12: Notification Center
    # Top left screen corner → Mission Control
    defaults write com.apple.dock wvous-tl-corner -int 0
    defaults write com.apple.dock wvous-tl-modifier -int 0
    # Top right screen corner → Desktop
    defaults write com.apple.dock wvous-tr-corner -int 0
    defaults write com.apple.dock wvous-tr-modifier -int 0
    # Bottom left screen corner → Start screen saver
    defaults write com.apple.dock wvous-bl-corner -int 0
    defaults write com.apple.dock wvous-bl-modifier -int 0

    # Safari
    # ---------------------------
    info "Privacy: don’t send search queries to Apple"
    defaults write com.apple.Safari UniversalSearchEnabled -bool false
    defaults write com.apple.Safari SuppressSearchSuggestions -bool true

    info "Show the full URL in the address bar (note: this still hides the scheme)"
    defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

    info "Set Safari’s home page to about:blank for faster loading"
    defaults write com.apple.Safari HomePage -string "about:blank"

    info "Prevent Safari from opening safe files automatically after downloading"
    defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

    # info "Allow hitting the Backspace key to go to the previous page in history"
    # defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled -bool true

    # # Hide Safari’s bookmarks bar by default
    # defaults write com.apple.Safari ShowFavoritesBar -bool false

    # # Hide Safari’s sidebar in Top Sites
    # defaults write com.apple.Safari ShowSidebarInTopSites -bool false

    # # Disable Safari’s thumbnail cache for History and Top Sites
    # defaults write com.apple.Safari DebugSnapshotsUpdatePolicy -int 2

    info "Enable Safari’s debug menu"
    defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

    info "Make Safari’s search banners default to Contains instead of Starts With"
    defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false

    info "Remove useless icons from Safari’s bookmarks bar"
    defaults write com.apple.Safari ProxiesInBookmarksBar "()"

    info "Enable the Develop menu and the Web Inspector in Safari"
    defaults write com.apple.Safari IncludeDevelopMenu -bool true
    defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
    defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

    info "Add a context menu item for showing the Web Inspector in web views"
    defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

    # Mail.app Preferences
    # ---------------------------

    info "Disable send and reply animations in Mail.app"
    defaults write com.apple.mail DisableReplyAnimations -bool true
    defaults write com.apple.mail DisableSendAnimations -bool true

    info "Copy sane email addresses to clipboard"
    # Copy email addresses as `foo@example.com` instead of `Foo Bar <foo@example.com>` in Mail.app
    defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

    #info "Add the keyboard shortcut ⌘ + Enter to send an email in Mail.app"
    #defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Send" -string "@\\U21a9"

    info "Display emails in threaded mode, sorted by date (newest at the top)"
    defaults write com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"
    defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortedDescending" -string "no"
    defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortOrder" -string "received-date"

    #info "Disable inline attachments (just show the icons)"
    #defaults write com.apple.mail DisableInlineAttachmentViewing -bool false

    # Spotlight Preferences
    # ---------------------------

    # Hide Spotlight tray-icon (and subsequent helper)
    #sudo chmod 600 /System/Library/CoreServices/Search.bundle/Contents/MacOS/Search

    info "Disabled Spotlight indexing for any new mounted volume"
    # Use `sudo mdutil -i off "/Volumes/foo"` to stop indexing any volume.
    sudo defaults write /.Spotlight-V100/VolumeConfiguration Exclusions -array "/Volumes"

    info "Change indexing order and disable some file types"
    # Newer-specific search results (remove them if your are using OS X 10.9 or older):
    #   MENU_DEFINITION
    #   MENU_CONVERSION
    #   MENU_EXPRESSION
    #   MENU_SPOTLIGHT_SUGGESTIONS (send search queries to Apple)
    #   MENU_WEBSEARCH             (send search queries to Apple)
    #   MENU_OTHER
    # defaults write com.apple.spotlight orderedItems -array \
    #   '{"enabled" = 1;"name" = "APPLICATIONS";}' \
    #   '{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
    #   '{"enabled" = 1;"name" = "DIRECTORIES";}' \
    #   '{"enabled" = 1;"name" = "PDF";}' \
    #   '{"enabled" = 1;"name" = "FONTS";}' \
    #   '{"enabled" = 0;"name" = "DOCUMENTS";}' \
    #   '{"enabled" = 0;"name" = "MESSAGES";}' \
    #   '{"enabled" = 0;"name" = "CONTACT";}' \
    #  '{"enabled" = 0;"name" = "EVENT_TODO";}' \
    #   '{"enabled" = 0;"name" = "IMAGES";}' \
    #   '{"enabled" = 0;"name" = "BOOKMARKS";}' \
    #   '{"enabled" = 0;"name" = "MUSIC";}' \
    #   '{"enabled" = 0;"name" = "MOVIES";}' \
    #   '{"enabled" = 0;"name" = "PRESENTATIONS";}' \
    #   '{"enabled" = 0;"name" = "SPREADSHEETS";}' \
    #   '{"enabled" = 0;"name" = "SOURCE";}' \
    #   '{"enabled" = 0;"name" = "MENU_DEFINITION";}' \
    #   '{"enabled" = 0;"name" = "MENU_OTHER";}' \
    #   '{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
    #   '{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
    #   '{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
    #   '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'
    # Load new settings before rebuilding the index
    # killall mds > /dev/null 2>&1
    # Make sure indexing is enabled for the main volume
    #sudo mdutil -i on / > /dev/null
    # Rebuild the index from scratch
    #sudo mdutil -E / > /dev/null

    # Time Machine Preferences
    # ---------------------------
    info "Prevent Time Machine from prompting to use new hard drives as backup volume"
    defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

    info "Disable local Time Machine backups"
    hash tmutil &>/dev/null && sudo tmutil disablelocal

    # Random Application Preferences
    # ---------------------------

    info "Show the main window when launching Activity Monitor"
    defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

    info "Visualize CPU usage in the Activity Monitor Dock icon"
    defaults write com.apple.ActivityMonitor IconType -int 5

    info "Show all processes in Activity Monitor"
    defaults write com.apple.ActivityMonitor ShowCategory -int 0

    info "Sort Activity Monitor results by CPU usage"
    defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
    defaults write com.apple.ActivityMonitor SortDirection -int 0

    info "Stop Photos from opening whenever a camera is connected"
    defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool YES

    info "Configure Google Chrome"
    defaults write com.google.Chrome DisablePrintPreview -bool true
    defaults write com.google.Chrome.canary DisablePrintPreview -bool true

    info "Enable the debug menu in Address Book"
    defaults write com.apple.addressbook ABShowDebugMenu -bool true

    # Enable Dashboard dev mode (allows keeping widgets on the desktop)
    # defaults write com.apple.dashboard devmode -bool true

    # Enable the debug menu in iCal (pre-10.8)
    # defaults write com.apple.iCal IncludeDebugMenu -bool true

    info "Use plain text mode for new TextEdit documents"
    defaults write com.apple.TextEdit RichText -int 0

    info "Open and save files as UTF-8 in TextEdit"
    defaults write com.apple.TextEdit PlainTextEncoding -int 4
    defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

    info "Enable the debug menu in Disk Utility"
    defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
    defaults write com.apple.DiskUtility advanced-image-options -bool true

    info "Disable automatic emoji substitution in Messages.app (i.e. use plain text smileys)"
    defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticEmojiSubstitutionEnablediMessage" -bool false

    info "Disable smart quotes in Messages.app (it's annoying for messages that contain code)"
    defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false

    info "Disabled continuous spell checking in Messages.app"
    defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "continuousSpellCheckingEnabled" -bool false

  }
  _macSystemPrefs_

  _setDefaultShell_() {
    _seekConfirmation_ "Set the default shell?" || return 0

    local shell
    shellOptions=(bash zsh quit)

    input "Which shell do you want to use?\n\n"
    select opt in "${shellOptions[@]}"; do
      case $opt in
        "bash")
          shell="bash"
          break
          ;;
        "zsh")
          shell="zsh"
          break
          ;;
        "quit")
          return 0
        ;;
        *) echo "invalid option '$option'" ;;
      esac
    done

    if brew --prefix &>/dev/null; then
      declare binroot="$(brew --prefix)/bin"
    else
      binroot="/bin"
    fi
    shell="${binroot}/${shell}"

    echo -n "
    Follow these steps:
      1) Run ${tan}'sudo ${EDITOR} /etc/shells'${reset}
      2) Paste '${tan}${shell}${reset}' if not already there
      3) Run '${tan}sudo chsh -s ${shell}${reset}'
      4) Restart your terminal"
  }
  _setDefaultShell_

} # end _mainScript_

_checkForHomebrew_() {

  homebrewPrefix="/usr/local"

  if [ -d "${homebrewPrefix}" ]; then
    if ! [ -r "${homebrewPrefix}" ]; then
      sudo chown -R "${LOGNAME}:admin" /usr/local
    fi
  else
    sudo mkdir "${homebrewPrefix}"
    sudo chflags norestricted "${homebrewPrefix}"
    sudo chown -R "${LOGNAME}:admin" "${homebrewPrefix}"
  fi

  if ! command -v brew &>/dev/null; then
    notice "Installing Homebrew..."
    #   Ensure that we can actually, like, compile anything.
    if [[ ! $(command -v gcc) || ! "$(command -v git)" ]]; then
      _commandLineTools_
    fi

    # Install Homebrew
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

    brew analytics off
  else
    return 0
  fi
}

_checkASDF_() {
  # DESC:   Checks if asdf is intalled.  If not, we install it.
  # ARGS:   None
  # OUTS:   None
  # NOTE:   All documentation available at: https://github.com/asdf-vm/asdf
  info "Confirming we have asdf package manager installed ..."

  if [ ! -d "${HOME}/.asdf" ]; then
    _checkForHomebrew_

    _execute_ -v "brew install asdf" || return

    # shellcheck disable=SC2015
    [[ -s "${HOME}/.asdf/asdf.sh" ]] \
      && source "${HOME}/.asdf/asdf.sh" \
      || {
        error "Could not source 'asdf.sh'" "${LINENO}"
        return 1
      }

    # shellcheck disable=SC2015
    [[ -s "${HOME}/.asdf/completions/asdf.bash" ]] \
      && source "${HOME}/.asdf/completions/asdf.bash" \
      || {
        error "Could not source '.asdf/completions/asdf.bash'" "${LINENO}"
        return 1
      }
  fi
}

_installASDFPlugin_() {
  # DESC:   Installs an asdf plugin
  # ARGS:   $1 (required) - Name of plugin to be installed
  # OUTS:   $2 (optional) - URL of plugin to be installed
  # USAGE:  _installASDFPlugin_ "ruby" "https://github.com/asdf-vm/asdf-ruby.git"
  # NOTE:   All documentation available at: https://github.com/asdf-vm/asdf
  local name="$1"
  local url="$2"

  if ! asdf plugin-list | grep -Fq "${name}"; then
    _execute_ -vp "asdf plugin-add \"$name\" \"$url\""
  fi
}

_installASDFLanguage_() {
  # DESC:   Installs a language via asdf
  # ARGS:   $1 (required) - Langauge name
  # OUTS:   $2 (optional) - Version number
  # USAGE:  _installASDFLanguage_ ruby 2.6.3
  # NOTE:   All documentation available at: https://github.com/asdf-vm/asdf
  local language="$1"
  local version="${2-}"

  if [ -z "$version" ]; then
    version="$(asdf list-all "$language" | tail -1)"
  fi

  if ! asdf list "${language}" | grep -Fq "${version-}"; then
    _execute_ -vp "asdf install \"${language}\" \"${version-}\""
    _execute_ -vp "asdf global \"${language}\" \"${version-}\""
  fi
}

_sourceHelperFiles_() {
  # DESC: Sources script helper files
  local filesToSource
  local sourceFile
  filesToSource=(
    "${HOME}/dotfiles/scripting/helpers/baseHelpers.bash"
    "${HOME}/dotfiles/scripting/helpers/files.bash"
    "${HOME}/dotfiles/scripting/helpers/textProcessing.bash"
  )
  for sourceFile in "${filesToSource[@]}"; do
    [ ! -f "$sourceFile" ] \
      && {
        echo "error: Can not find sourcefile '$sourceFile'."
        echo "exiting..."
        exit 1
      }
    source "$sourceFile"
  done
}
_sourceHelperFiles_

# Set initial flags
quiet=false
printLog=false
logErrors=true
verbose=false
force=false
dryrun=false
declare -a args=()

_usage_() {
  cat <<EOF

  ${bold}$(basename "$0") [OPTION]...${reset}

  Configures a new computer running MacOSX.  Performs the following
  optional actions:

    * Install Mac Command Line Tools
    * Symlink dotfiles
    * Install Homebrew, Homebrew Cask, and Mas
    * Install packages and applications via the above
    * Install asdf
    * Install NodeJS
    * Install Ruby
    * Configure iTerm2
    * Install BATs test framework
    * Install Git Friendly
    * Configure Mac system preference defaults
    * Sets default shell to ZSH


  ${bold}Options:${reset}

    -h, --help        Display this help and exit
    -l, --log         Print log to file with all log levels
    -L, --noErrorLog  Default behavior is to print log level error and fatal to a log. Use
                      this flag to generate no log files at all.
    -n, --dryrun      Non-destructive. Makes no permanent changes.
    -q, --quiet       Quiet (no output)
    -v, --verbose     Output more information. (Items echoed to 'verbose')
    --force           Skip all user interaction.  Implied 'Yes' to all actions.
EOF
}

_parseOptions_() {
  # Iterate over options
  # breaking -ab into -a -b when needed and --foo=bar into --foo bar
  optstring=h
  unset options
  while (($#)); do
    case $1 in
      # If option is of type -ab
      -[!-]?*)
        # Loop over each character starting with the second
        for ((i = 1; i < ${#1}; i++)); do
          c=${1:i:1}
          options+=("-$c") # Add current char to options
          # If option takes a required argument, and it's not the last char make
          # the rest of the string its argument
          if [[ $optstring == *"$c:"* && ${1:i+1} ]]; then
            options+=("${1:i+1}")
            break
          fi
        done
        ;;
      # If option is of type --foo=bar
      --?*=*) options+=("${1%%=*}" "${1#*=}") ;;
      # add --endopts for --
      --) options+=(--endopts) ;;
      # Otherwise, nothing special
      *) options+=("$1") ;;
    esac
    shift
  done
  set -- "${options[@]}"
  unset options

  # Read the options and set stuff
  while [[ ${1-} == -?* ]]; do
    case $1 in
      -h | --help)
        _usage_ >&2
        _safeExit_
        ;;
      -L | --noErrorLog) logErrors=false ;;
      -n | --dryrun) dryrun=true ;;
      -v | --verbose) verbose=true ;;
      -l | --log) printLog=true ;;
      -q | --quiet) quiet=true ;;
      --force) force=true ;;
      --endopts)
        shift
        break
        ;;
      *) die "invalid option: '$1'." ;;
    esac
    shift
  done
  args+=("$@") # Store the remaining user input as arguments.
}

# Initialize and run the script
trap '_trapCleanup_ $LINENO $BASH_LINENO "$BASH_COMMAND" "${FUNCNAME[*]}" "$0" "${BASH_SOURCE[0]}"' \
  EXIT INT TERM SIGINT SIGQUIT
set -o errtrace                           # Trap errors in subshells and functions
set -o errexit                            # Exit on error. Append '||true' if you expect an error
set -o pipefail                           # Use last non-zero exit code in a pipeline
#shopt -s nullglob globstar                # Make `for f in *.txt` work when `*.txt` matches zero files
IFS=$' \n\t'                              # Set IFS to preferred implementation
# set -o xtrace                           # Run in debug mode
set -o nounset                            # Disallow expansion of unset variables
# [[ $# -eq 0 ]] && _parseOptions_ "-h"   # Force arguments when invoking the script
_parseOptions_ "$@"                       # Parse arguments passed to script
# _makeTempDir_ "$(basename "$0")"        # Create a temp directory '$tmpDir'
_acquireScriptLock_                       # Acquire script lock
_mainScript_                              # Run script unless in 'source-only' mode
_safeExit_                                # Exit cleanly
