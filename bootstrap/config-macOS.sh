#!/usr/bin/env bash

version="1.0.0"

_mainScript_() {

  [[ "$OSTYPE" != "darwin"* ]] \
    && die "We are not on macOS" "$LINENO"

  # Set Variables
    baseDir="$(_findBaseDir_)" &&  verbose "baseDir: $baseDir"
    rootDIR="$(dirname "$baseDir")" && verbose "rootDIR: $rootDIR"
    privateInstallScript="${HOME}/dotfiles-private/privateInstall.sh"
    pluginScripts="${baseDir}/plugins"

  # Config files
    configSymlinks="${baseDir}/config/symlinks.yaml"
    configHomebrew="${baseDir}/config/homebrew.yaml"
    configCasks="${baseDir}/config/homebrewCasks.yaml"
    configNode="${baseDir}/config/node.yaml"
    configRuby="${baseDir}/config/ruby.yaml"

  scriptFlags=()
    ( $dryrun ) && scriptFlags+=(--dryrun)
    ( $quiet ) && scriptFlags+=(--quiet)
    ( $printLog ) && scriptFlags+=(--log)
    ( $verbose ) && scriptFlags+=(--verbose)
    ( $debug ) && scriptFlags+=(--debug)
    ( $strict ) && scriptFlags+=(--strict)

  _commandLineTools_() {
    local x

    info "Checking for Command Line Tools..."

    if ! xcode-select --print-path &> /dev/null; then

      # Prompt user to install the XCode Command Line Tools
      xcode-select --install > /dev/null 2>&1

      # Wait until the XCode Command Line Tools are installed
      until xcode-select --print-path &> /dev/null 2>&1; do
        sleep 5
      done

      x=$(find '/Applications' -maxdepth 1 -regex '.*/Xcode[^ ]*.app' -print -quit)
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

  # Create symlinks
  if _seekConfirmation_ "Create symlinks to configuration files?"; then
    header "Creating Symlinks"
    _doSymlinks_ "${configSymlinks}"
  fi

  _homebrew_() {
    local tap
    local package
    local testInstalled
    local t="${tmpDir}/${RANDOM}.${RANDOM}.${RANDOM}.txt"
    local c="$1"  # Config YAML file

    if ! _seekConfirmation_ "Install Homebrew Packages?"; then return; fi

    info "Checking for Homebrew..."
    ( _checkForHomebrew_ )

    [ ! -f "$c" ] \
      && { error "Can not find config file '$c'"; return 1; }

    # Parse & source Config File
    # shellcheck disable=2015
    ( _parseYAML_ "${c}" > "${t}" ) \
      && { if $verbose; then verbose "-- Config Variables"; _readFile_ "$t"; fi; } \
      || die "Could not parse YAML config file" "$LINENO"

    _sourceFile_ "$t"

    # Brew updates can take forever if we're not bootstrapping. Show the output
    local v=$verbose; verbose=true;

    header "Updating Homebrew"
    _execute_ "caffeinate -ism brew update"
    _execute_ "caffeinate -ism brew doctor"
    _execute_ "caffeinate -ism brew upgrade"

    header "Installing Homebrew Taps"
    # shellcheck disable=2154
    for tap in "${homebrewTaps[@]}"; do
      tap=$(echo "${tap}" | cut -d'#' -f1 | _trim_) # remove comments if exist
      _execute_ "brew tap ${tap}"
    done

    header "Installing Homebrew Packages"
    # shellcheck disable=2154
    for package in "${homebrewPackages[@]}"; do

      package=$(echo "${package}" | cut -d'#' -f1 | _trim_) # remove comments if exist
      testInstalled=$(echo "${package}" | cut -d' ' -f1 | _trim_)  # strip flags from package names

      if brew ls --versions "$testInstalled" > /dev/null; then
        info "$testInstalled already installed"
      else
        _execute_ "caffeinate -ism brew install ${package}" "Install ${testInstalled}"
      fi
    done

    _execute_ "brew cleanup"  # cleanup after ourselves
    verbose=$v                # Reset verbose settings
  }
  _homebrew_ "$configHomebrew"

  _homebrewCasks_() {
    local cask
    local testInstalled
    local t="${tmpDir}/${RANDOM}.${RANDOM}.${RANDOM}.txt"
    local c="$1"  # Config YAML file

    if ! _seekConfirmation_ "Install Homebrew Casks?"; then return; fi

    info "Checking for Homebrew..."
    _checkForHomebrew_

    [ ! -f "$c" ] \
      && { error "Can not find config file '$c'"; return 1; }

    # Parse & source Config File
    # shellcheck disable=2015
    ( _parseYAML_ "${c}" > "${t}" ) \
      && { if $verbose; then verbose "-- Config Variables"; _readFile_ "$t"; fi; } \
      || die "Could not parse YAML config file" "$LINENO"

    _sourceFile_ "$t"

    # Brew updates can take forever if we're not bootstrapping. Show the output
    saveVerbose=$verbose; verbose=true;

    header "Updating Homebrew"
    _execute_ "caffeinate -ism brew update"
    _execute_ "caffeinate -ism brew doctor"

    header "Installing Casks"
    # shellcheck disable=2154
    for cask in "${homebrewCasks[@]}"; do

      cask=$(echo "${cask}" | cut -d'#' -f1 | _trim_) # remove comments if exist

      # strip flags from package names
      testInstalled=$(echo "${cask}" | cut -d' ' -f1 | _trim_)

      if brew cask ls "${testInstalled}" &> /dev/null; then
        info "${testInstalled} already installed"
      else
        _execute_ "brew cask install $cask" "Install ${testInstalled}"
      fi
    done

    _execute_ "brew cleanup"  # cleanup after ourselves
    verbose=$saveVerbose      # Reset verbose settings
  }
  _homebrewCasks_ "$configCasks"

  _node_() {
    local package
    local npmPackages
    local modules
    local t="${tmpDir}/${RANDOM}.${RANDOM}.${RANDOM}.txt"
    local c="$1"  # Config YAML file

    if ! _seekConfirmation_ "Install Node Packages?"; then return; fi

    [ ! -f "$c" ] \
      && { error "Can not find config file '$c'"; return 1; }

    # Parse & source Config File
    # shellcheck disable=2015
    ( _parseYAML_ "${c}" > "${t}" ) \
      && { if $verbose; then verbose "-- Config Variables"; _readFile_ "$t"; fi; } \
      || die "Could not parse YAML config file" "$LINENO"

    _sourceFile_ "$t"

    header "Installing global node packages"

    #confirm node is installed
    if test ! "$(which node)"; then
      notice "Can not install npm packages without node. Installing now"
      info "Checking for Homebrew..."
      _checkForHomebrew_
      if ! brew install node; then
        warning "Can not install node. Please rerun script."
        return 1
      fi
    fi

    # Grab packages already installed
    { pushd "$(npm config get prefix)/lib/node_modules"; installed=(*); popd; } >/dev/null

    #Show nodes's detailed install information
    saveVerbose=$verbose; verbose=true;

    # If comments exist in the list of npm packaged to be installed remove them
    # shellcheck disable=2154
    for package in "${nodePackages[@]}"; do
      npmPackages+=($(echo "${package}" | cut -d'#' -f1 | _trim_) )
    done

    # Install packages that do not already exist
    modules=($(_setdiff_ "${npmPackages[*]}" "${installed[*]}"))
    if (( ${#modules[@]} > 0 )); then
      pushd ${HOME} > /dev/null; _execute_ "npm install -g ${modules[*]}"; popd > /dev/null;
    else
      info "All node packages already installed"
    fi

    # Reset verbose settings
    verbose=$saveVerbose
  }
  _node_ "$configNode"

  _ruby_() {
    local RUBYVERSION="2.3.4 " # Version of Ruby to install via RVM
    local t="${tmpDir}/${RANDOM}.${RANDOM}.${RANDOM}.txt"
    local c="$1"  # Config YAML file
    local gem
    local testInstalled

    if ! _seekConfirmation_ "Install Ruby Packages?"; then return; fi
    header "Installing RVM and Ruby packages"

    [ ! -f "$c" ] \
      && { error "Can not find config file '$c'"; return 1; }

    # Parse & source Config File
    # shellcheck disable=2015
    ( _parseYAML_ "${c}" > "${t}" ) \
      && { if $verbose; then verbose "-- Config Variables"; _readFile_ "$t"; fi; } \
      || die "Could not parse YAML config file" "$LINENO"

    _sourceFile_ "$t"

    info "Checking for RVM (Ruby Version Manager)..."
    pushd ${HOME} &> /dev/null
    # Check for RVM
    if ! command -v rvm &> /dev/null; then
      _execute_ "curl -L https://get.rvm.io | bash -s stable --ruby"
      _execute_ "source ${HOME}/.rvm/scripts/rvm"
      _execute_ "source ${HOME}/.bash_profile"
      #rvm get stable --autolibs=enable
      _execute_ "rvm install ${RUBYVERSION}"
      _execute_ "rvm use ${RUBYVERSION} --default"
    fi
    success "RVM and Ruby are installed"


    header "Installing global ruby gems"
    local v=$verbose; verbose=true;

    # shellcheck disable=2154
    for gem in "${rubyGems[@]}"; do

      # Strip comments
      gem=$(echo "$gem" | cut -d'#' -f1 | _trim_)

      # strip flags from package names
      testInstalled=$(echo "$gem" | cut -d' ' -f1 | _trim_)

      if ! gem list "$testInstalled" -i >/dev/null; then
        _execute_ "gem install ${gem}"
      else
        info "${testInstalled} already installed"
      fi
    done

    popd &> /dev/null

    verbose=$v
  }
  _ruby_ "$configRuby"

  _runPlugins_() {
    local plugin pluginName flags v d

    header "Running plugin scripts"

    if [ ! -d "$pluginScripts" ]; then
      error "Can't find plugins." "$LINENO"
      return 1
    fi

    # Run the bootstrap scripts in numerical order
    for plugin in ${pluginScripts}/*.sh; do
      pluginName="$(basename ${plugin})"
      pluginName="$(echo $pluginName | sed -e 's/[0-9][0-9]-//g' | sed -e 's/-/ /g' | sed -e 's/\.sh//g')"
      if _seekConfirmation_ "Run '${pluginName}' plugin?"; then

        #Build flags
        [ -n "${scriptFlags[*]}" ] \
          && flags="${scriptFlags[*]}"
        [[ "$flags" =~ (--verbose|v) ]] \
          || flags="${flags} --verbose"
        ( $dryrun ) && { d=true; dryrun=false; }
        flags="${flags} --rootDIR $rootDIR"

        v=$verbose; verbose=true;

        _execute_ "${plugin} ${flags}" "'${pluginName}' plugin"

        verbose=$v
        ( $d ) && dryrun=true;
      fi
    done
  }
  _runPlugins_

  _privateRepo_() {
    if _seekConfirmation_ "Run Private install script"; then
      [ ! -f "${privateInstallScript}" ] \
        && { warning "Could not find private install script" ; return 1; }
      "${privateInstallScript}" "${scriptFlags[*]}"
    fi
  }
  _privateRepo_

}  # end _mainScript_


# ### CUSTOM FUNCTIONS ###########################

_doSymlinks_() {
  # Takes an input of a configuration YAML file and creates symlinks from it.
  # Note that the YAML file must group symlinks in a section named 'symlinks'
  local l                                     # link
  local d                                     # destination
  local s                                     # source
  local c="${1:?Must have a config file}"     # config file
  local t                                     # temp file
  local line

  t="${tmpDir}/${RANDOM}.${RANDOM}.${RANDOM}.txt"

  [ ! -f "$c" ] \
    && { error "Can not find config file '$c'"; return 1; }

  # Parse & source Config File
  # shellcheck disable=2015
  ( _parseYAML_ "${c}" > "${t}" ) \
    && { if $verbose; then verbose "-- Config Variables"; _readFile_ "$t"; fi; } \
    || die "Could not parse YAML config file" "$LINENO"

  _sourceFile_ "$t"

  [ "${#symlinks[@]}" -eq 0 ] \
    && { warning "No symlinks found in '$c'"; return 1; }

  # For each link do the following
  for l in "${symlinks[@]}"; do
    verbose "Working on: $l"

    # Parse destination and source
    d=$(echo "$l" | cut -d':' -f1 | _trim_)
    s=$(echo "$l" | cut -d':' -f2 | _trim_)
    s=$(echo "$s" | cut -d'#' -f1 | _trim_) # remove comments if exist

    # Add the rootDIR to source if it exists
    [ -n "$rootDIR" ] \
      && s="${rootDIR}/${s}"

    # Grab the absolute path for the source
    s="$(_realpath_ "${s}")"

    # If we can't find a source file, skip it
    [ ! -e "${s}" ] \
      && { warning "Can't find source '${s}'"; continue; }

    ( _makeSymlink_ "${s}" "${d}" ) \
      || { warning "_makeSymlink_ failed for source: '$s'"; return 1; }

  done
}

_checkForHomebrew_() {

  if ! command -v brew &> /dev/null; then
    notice "Installing Homebrew..."
    #   Ensure that we can actually, like, compile anything.
    if [[ ! $(command -v gcc) || ! "$(command -v git)" ]]; then
      _commandLineTools_
    fi

    # Install Homebrew
    ( _execute_ "ruby -e $(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" "Install Homebrew" ) \
        || { return 1; }
    brew analytics off
  else
    return 0
  fi
}

# Set Base Variables
# ----------------------
scriptName=$(basename "$0")

# Set Flags
quiet=false;              printLog=false;             logErrors=true;   verbose=false;
force=false;              strict=false;               dryrun=false;
debug=false;              sourceOnly=false;           args=();

# Set Temp Directory
tmpDir="/tmp/${scriptName}.$RANDOM.$RANDOM.$RANDOM.$$"
(umask 077 && mkdir "${tmpDir}") || {
  die "Could not create temporary directory! Exiting." "$LINENO"
}

_sourceHelperFiles_() {
  local filesToSource
  local sourceFile

  filesToSource=(
    ${HOME}/dotfiles/scripting/helpers/baseHelpers.bash
    ${HOME}/dotfiles/scripting/helpers/files.bash
    ${HOME}/dotfiles/scripting/helpers/arrays.bash
    ${HOME}/dotfiles/scripting/helpers/textProcessing.bash
  )

  for sourceFile in "${filesToSource[@]}"; do
    [ ! -f "$sourceFile" ] \
      &&  { echo "error: Can not find sourcefile '$sourceFile'. Exiting."; exit 1; }

    source "$sourceFile"
  done
}
_sourceHelperFiles_

# Options and Usage
# -----------------------------------
_usage_() {
  echo -n "${scriptName} [OPTION]... [FILE]...

This script runs a series of installation scripts to configure a new computer running Mac OSX.
It relies on a number of YAML config files which contain the lists of packages to be installed.

This script also looks for plugin scripts in a user configurable directory for added customization.

 ${bold}Options:${reset}

  -n, --dryrun      Non-destructive. Makes no permanent changes.
  -q, --quiet       Quiet (no output)
  -L, --noErrorLog  Print log level error and fatal to a log (default 'true')
  -l, --log         Print log to file
  -s, --strict      Exit script with null variables.  i.e 'set -o nounset'
  -v, --verbose     Output more information. (Items echoed to 'verbose')
  -d, --debug       Runs script in BASH debug mode (set -x)
  -h, --help        Display this help and exit
      --source-only Bypasses main script functionality to allow unit tests of functions
      --version     Output version information and exit
      --force       Skip all user interaction.  Implied 'Yes' to all actions.
"
}

# Iterate over options breaking -ab into -a -b when needed and --foo=bar into
# --foo bar
optstring=h
unset options
while (($#)); do
  case $1 in
    # If option is of type -ab
    -[!-]?*)
      # Loop over each character starting with the second
      for ((i=1; i < ${#1}; i++)); do
        c=${1:i:1}

        # Add current char to options
        options+=("-$c")

        # If option takes a required argument, and it's not the last char make
        # the rest of the string its argument
        if [[ $optstring = *"$c:"* && ${1:i+1} ]]; then
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

# Print help if no arguments were passed.
# Uncomment to force arguments when invoking the script
# -------------------------------------
# [[ $# -eq 0 ]] && set -- "--help"

# Read the options and set stuff
while [[ $1 = -?* ]]; do
  case $1 in
    -h|--help) _usage_ >&2; _safeExit_ ;;
    -n|--dryrun) dryrun=true ;;
    -v|--verbose) verbose=true ;;
    -L|--noErrorLog) logErrors=false ;;
    -l|--log) printLog=true ;;
    -q|--quiet) quiet=true ;;
    -s|--strict) strict=true;;
    -d|--debug) debug=true;;
    --version) echo "$(basename $0) ${version}"; _safeExit_ ;;
    --source-only) sourceOnly=true;;
    --force) force=true ;;
    --endopts) shift; break ;;
    *) die "invalid option: '$1'." ;;
  esac
  shift
done

# Store the remaining part as arguments.
args+=("$@")

# Trap bad exits with your cleanup function
trap '_trapCleanup_ $LINENO $BASH_LINENO "$BASH_COMMAND" "${FUNCNAME[*]}" "$0" "${BASH_SOURCE[0]}"' \
  EXIT INT TERM SIGINT SIGQUIT ERR

# Set IFS to preferred implementation
IFS=$' \n\t'

# Exit on error. Append '||true' when you run the script if you expect an error.
# set -o errtrace
# set -o errexit

# Force pipelines to fail on the first non-zero status code.
set -o pipefail

# Run in debug mode, if set
if ${debug}; then set -x ; fi

# Exit on empty variable
if ${strict}; then set -o nounset ; fi

# Run your script unless in 'source-only' mode
if ! ${sourceOnly}; then _mainScript_; fi

# Exit cleanly
if ! ${sourceOnly}; then _safeExit_; fi