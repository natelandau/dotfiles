#!/usr/bin/env bash

version="1.0.0"

_mainScript_() {

  [[ "$OSTYPE" != "darwin"* ]] && die "We are not on macOS"

  # Set Variables
  baseDir="$(_findBaseDir_)"
  rootDIR="$(dirname "$baseDir")"
  utilsFile="${baseDir}/lib/utils.sh"
  configFile="${baseDir}/config-macOS.yaml"
  privateInstallScript="${HOME}/dotfiles-private/privateInstall.sh"
  pluginScripts="${baseDir}/lib/mac-plugins"

  scriptFlags=()
    ( $dryrun ) && scriptFlags+=(--dryrun)
    ( $quiet ) && scriptFlags+=(--quiet)
    ( $printLog ) && scriptFlags+=(--log)
    ( $verbose ) && scriptFlags+=(--verbose)
    ( $debug ) && scriptFlags+=(--debug)
    ( $strict ) && scriptFlags+=(--strict)

  _sourceFiles_() {
    if [ -f "$configFile" ]; then
      yamlConfigVariables="${tmpDir}/yamlConfigVariables.txt"
      _parseYAML_ "$configFile" > "$yamlConfigVariables"
      source "$yamlConfigVariables"
      # In verbose mode, echo the variables for debugging purposes
      if $verbose; then verbose "-- Config Variables --"; _readFile_ "$yamlConfigVariables"; fi
    else
      die "Can't find $configFile"
    fi
  }
  _sourceFiles_

  _commandLineTools_(){
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
    # Alternative method. Depreciated but left here for posterity
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
  }
  _commandLineTools_

  _doSymlinks_() {

    if ! _seekConfirmation_ "Create symlinks to dotfiles?"; then return; fi

    [ ! -d "${HOME}/bin" ] && _execute_ "mkdir \"${HOME}/bin\""

    filesToLink=("${symlinks[@]}") # array is populated from YAML
    _createSymlinks_ "Symlinks"
    unset filesToLink
  }
  _doSymlinks_

  _privateRepo_() {

    if _seekConfirmation_ "Run Private install script"; then
       [ ! -f "${privateInstallScript}" ] && { warning "Could not find private install script" ; return ; }
      "${privateInstallScript}" "${scriptFlags[*]}"
    fi
  }
  _privateRepo_

  _homebrew_() {
    info "Checking for Homebrew..."

    if ! command -v brew &> /dev/null; then
      notice "Installing Homebrew..."
      #   Ensure that we can actually, like, compile anything.
      if [[ ! $(command -v gcc) && "$OSTYPE" =~ ^darwin ]]; then
        _commandLineTools_
      fi
      # Check for Git
      if [ ! "$(command -v git)" ]; then
        _commandLineTools_
      fi
      if [[ ! $(command -v gcc) && "$OSTYPE" =~ ^darwin ]]; then
        _commandLineTools_
      fi
      # Check for Git
      if [ ! "$(command -v git)" ]; then
        _commandLineTools_
      fi
      # Install Homebrew
      _execute_ "ruby -e $(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" "Install Homebrew"
    else
      success "Homebrew is installed"
    fi

    local tap
    local package
    local cask
    local testInstalled

    if ! _seekConfirmation_ "Install Homebrew Packages?"; then return; fi

    header "Installing Homebrew Packages"

    # Confirm Homebrew is installed
    if test ! "$(which brew)"; then
      die "Can not continue without homebrew."
      #notice "Installing Homebrew..."
      # ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi

    # Show Brew Update can take forever if we're not bootstrapping. Show the output
    saveVerbose=$verbose
    verbose=true

    # Make sure we’re using the latest Homebrew
    _execute_ "brew update"

    # Upgrade any already-installed formulae
    _execute_ "caffeinate -ism brew upgrade" "Upgrade existing formulae"

    # Install taps
    # shellcheck disable=2154
    for tap in "${homebrewTaps[@]}"; do
      tap=$(echo "${tap}" | cut -d'#' -f1 | _trim_) # remove comments if exist
      _execute_ "brew tap ${tap}"
    done

    # Install packages
    # shellcheck disable=2154
    for package in "${homebrewPackages[@]}"; do

      package=$(echo "${package}" | cut -d'#' -f1 | _trim_) # remove comments if exist

      # strip flags from package names
      testInstalled=$(echo "${package}" | cut -d' ' -f1 | _trim_)

      if brew ls --versions "$testInstalled" > /dev/null; then
        info "$testInstalled already installed"
      else
        _execute_ "brew install ${package}" "Install ${testInstalled}"
      fi
    done

    # Install mac apps via homebrew cask
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

    # cleanup after ourselves
    _execute_ "brew cleanup"
    #_execute_ "brew doctor"

    # Reset verbose settings
    verbose=$saveVerbose
  }
  _homebrew_

  _node_() {
    local package
    local npmPackages
    local modules

    if ! _seekConfirmation_ "Install Node Packages?"; then return; fi

    header "Installing global node packages"

    #confirm node is installed
    if test ! "$(which node)"; then
      notice "Can not install npm packages without node. Installing now"
      if command -v brew &> /dev/null; then
        brew install node
      else
        warning "Can not install node. Please rerun script."
        return
      fi
    fi

    # Grab packages already installed
    { pushd "$(npm config get prefix)/lib/node_modules"; installed=(*); popd; } >/dev/null

    #Show nodes's detailed install information
    saveVerbose=$verbose
    verbose=true

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
  _node_

  _ruby_() {
    local RUBYVERSION="2.3.4 " # Version of Ruby to install via RVM
    info "Checking for RVM (Ruby Version Manager)..."

    pushd ${HOME} &> /dev/null
    # Check for RVM
    if ! command -v rvm &> /dev/null; then
      if _seekConfirmation_ "Couldn't find RVM. Install it?"; then
        _execute_ "curl -L https://get.rvm.io | bash -s stable --ruby"
        _execute_ "source ${HOME}/.rvm/scripts/rvm"
        _execute_ "source ${HOME}/.bash_profile"
        #rvm get stable --autolibs=enable
        _execute_ "rvm install ${RUBYVERSION}"
        _execute_ "rvm use ${RUBYVERSION} --default"
      fi
    fi
    success "RVM and Ruby are installed"

    if ! _seekConfirmation_ "Install Ruby Packages?"; then return; fi

    header "Installing global ruby gems"

    # shellcheck disable=2154
    for gem in "${rubyGems[@]}"; do

      # Strip comments
      gem=$(echo "$gem" | cut -d'#' -f1 | _trim_)

      # strip flags from package names
      testInstalled=$(echo "$gem" | cut -d' ' -f1 | _trim_)

      if ! gem list $testInstalled -i >/dev/null; then
        _execute_ "gem install ${gem}" "install ${gem}"p
      else
        info "${testInstalled} already installed"
      fi
    done

    popd &> /dev/null
  }
  _ruby_

  _runPlugins_() {
    local plugin

    header "Running plugin scripts"

    if [ ! -d "$pluginScripts" ]; then die "Can't find plugins."; fi

    # Run the bootstrap scripts in numerical order

    set +e # Don't quit install.sh when a sub-script fails
    for plugin in ${pluginScripts}/*.sh; do
      pluginName="$(basename ${plugin})"
      pluginName="$(echo $pluginName | sed -e 's/[0-9][0-9]-//g' | sed -e 's/-/ /g' | sed -e 's/\.sh//g')"
      if _seekConfirmation_ "Run '${pluginName}' plugin?"; then
        "${plugin}" "${scriptFlags[*]}" --verbose --rootDIR "$rootDIR"
      fi
    done
    set -e
  }
  _runPlugins_



}  # end _mainScript_

_trapCleanup_() {
  echo ""
  # Delete temp files, if any
  [ -d "${tmpDir}" ] && rm -r "${tmpDir}"
  die "Exit trapped. In function: '${FUNCNAME[*]:1}'"
}

_safeExit_() {
  # Delete temp files, if any
  [ -d "${tmpDir}" ] && rm -r "${tmpDir}"
  trap - INT TERM EXIT
  exit ${1:-0}
}

_seekConfirmation_() {
  # v1.0.0

  ( $force ) && return 0

  input "$@"
  while true; do
    read -r -p " (y/n) " yn
    case $yn in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) input "Please answer yes or no.";;
    esac
  done
}

_execute_() {
  # v1.0.1
  local cmd="${1:?_execute_ needs a command}"
  local message="${2:-$1}"
  if ${dryrun}; then
    dryrun "${message}"
  else
    if $verbose; then
      eval "$cmd"
    else
      eval "$cmd" &> /dev/null
    fi
    if [ $? -eq 0 ]; then
      success "${message}"
    else
      error "${message}"
      #die "${message}"
    fi
  fi
}

_findBaseDir_() {
  #v1.0.0
  # fincBaseDir locates the real directory of the script being run. similar to GNU readlink -n
  local SOURCE
  local DIR
  SOURCE="${BASH_SOURCE[0]}"
  while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  done
  echo "$( cd -P "$( dirname "$SOURCE" )" && pwd )"
}

_backupOriginalFile_() {
  local newFile
  local backupDir

  # Set backup directory location
  backupDir="${baseDir}/dotfiles_backup"

  if [[ ! -d "$backupDir" && "$dryrun" == false ]]; then
    _execute_ "mkdir \"$backupDir\"" "Creating backup directory"
  fi

  if [ -e "$1" ]; then
    newFile="$(basename "$1")"
    _execute_ "cp -R \"${1}\" \"${backupDir}/${newFile#.}\"" "Backing up: ${newFile}"
  fi
}

_locateSourceFile_() {
  # v1.0.1
  # locateSourceFile is fed a symlink and returns the originating file
  # usage: _locateSourceFile_ 'some/symlink'

  local TARGET_FILE
  local PHYS_DIR
  local RESULT

  TARGET_FILE="${1:?_locateSourceFile_ needs a file}"

  cd "$(dirname "$TARGET_FILE")" || return 1
  TARGET_FILE="$(basename "$TARGET_FILE")"

  # Iterate down a (possible) chain of symlinks
  while [ -L "$TARGET_FILE" ]; do
    TARGET_FILE=$(readlink "$TARGET_FILE")
    cd "$(dirname "$TARGET_FILE")" || return 1
    TARGET_FILE="$(basename "$TARGET_FILE")"
  done

  # Compute the canonicalized name by finding the physical path
  # for the directory we're in and appending the target file.
  PHYS_DIR=$(pwd -P)
  RESULT="${PHYS_DIR}/${TARGET_FILE}"
  echo "$RESULT"
}

_createSymlinks_() {
  # This function takes an input of the YAML variable containing the symlinks to be linked
  # and then creates the appropriate symlinks in the home directory. it will also backup existing files if there.

  local link=""
  local destFile=""
  local sourceFile=""
  local originalFile=""

  header "Creating ${1:-symlinks}"

  # For each link do the following
  for link in "${filesToLink[@]}"; do
    verbose "Working on: $link"
    # Parse destination and source
    destFile=$(echo "$link" | cut -d':' -f1 | _trim_)
    sourceFile=$(echo "$link" | cut -d':' -f2 | _trim_)
    sourceFile=$(echo "$sourceFile" | cut -d'#' -f1 | _trim_) # remove comments if exist

    # Fix files where $HOME is written as '~'
    destFile="${destFile/\~/$HOME}"

    # Grab the absolute path for the source
    sourceFile="${rootDIR}/${sourceFile}"

    # If we can't find a source file, skip it
    if ! test -e "${sourceFile}"; then
      warning "Can't find '${sourceFile}'"
      continue
    fi

    # Now we symlink the files
    if [ ! -e "${destFile}" ]; then
      _execute_ "ln -fs \"${sourceFile}\" \"${destFile}\"" "symlink ${sourceFile} → ${destFile}"
    elif [ -h "${destFile}" ]; then
      originalFile="$(_locateSourceFile_ "$destFile")"
      _backupOriginalFile_ "${originalFile}"
      if ! ${dryrun}; then rm -rf "$destFile"; fi
      _execute_ "ln -fs \"${sourceFile}\" \"${destFile}\"" "symlink ${sourceFile} → ${destFile}"
    elif [ -e "${destFile}" ]; then
      _backupOriginalFile_ "${destFile}"
      if ! ${dryrun}; then rm -rf "$destFile"; fi
      _execute_ "ln -fs \"${sourceFile}\" \"${destFile}\"" "symlink ${sourceFile} → ${destFile}"
    else
      warning "Error linking: ${sourceFile} → ${destFile}"
    fi
  done
}

_parseYAML_() {
  # v1.0.0
  local prefix=$2
  local s
  local w
  local fs
  s='[[:space:]]*'
  w='[a-zA-Z0-9_]*'
  fs="$(echo @|tr @ '\034')"
  sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
      -e "s|^\($s\)\($w\)$s[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$1" |
  awk -F"$fs" '{
    indent = length($1)/2;
    if (length($2) == 0) { conj[indent]="+";} else {conj[indent]="";}
    vname[indent] = $2;
    for (i in vname) {if (i > indent) {delete vname[i]}}
    if (length($3) > 0) {
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            printf("%s%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, conj[indent-1],$3);
    }
  }' | sed 's/_=/+=/g' | sed 's/[[:space:]]*#.*"/"/g'
}

_readFile_() {
  # v1.0.0
  local result

  while read -r result
  do
    echo "${result}"
  done < "${1:?Must specify a file for _readFile_}"
  unset result
}

_setdiff_() {
  # v1.0.0
  local debug skip a b
  if [[ "$1" == 1 ]]; then debug=1; shift; fi
  if [[ "$1" ]]; then
    local setdiffA setdiffB setdiffC
    setdiffA=($1); setdiffB=($2)
  fi
  setdiffC=()
  for a in "${setdiffA[@]}"; do
    skip=
    for b in "${setdiffB[@]}"; do
      [[ "$a" == "$b" ]] && skip=1 && break
    done
    [[ "$skip" ]] || setdiffC=("${setdiffC[@]}" "$a")
  done
  [[ "$debug" ]] && for a in setdiffA setdiffB setdiffC; do
    echo "$a ($(eval echo "\${#$a[*]}")) $(eval echo "\${$a[*]}")" 1>&2
  done
  [[ "$1" ]] && echo "${setdiffC[@]}"
}

_ltrim_() {
  # Removes all leading whitespace (from the left).
  local char=${1:-[:space:]}
    sed "s%^[${char//%/\\%}]*%%"
}

_rtrim_() {
  # Removes all trailing whitespace (from the right).
  local char=${1:-[:space:]}
  sed "s%[${char//%/\\%}]*$%%"
}

_trim_() {
  # Removes all leading/trailing whitespace
  # Usage examples:
  #     echo "  foo  bar baz " | _trim_  #==> "foo  bar baz"
  _ltrim_ "$1" | _rtrim_ "$1"
}

# Set Base Variables
# ----------------------
readonly scriptName=$(basename "$0")

# Set Flags
quiet=false;              printLog=false;             verbose=false;
force=false;              strict=false;               dryrun=false;
debug=false;              sourceOnly=false;             args=();

# Set Colors
bold=$(tput bold);        reset=$(tput sgr0);         purple=$(tput setaf 171);
red=$(tput setaf 1);      green=$(tput setaf 76);     tan=$(tput setaf 3);
blue=$(tput setaf 38);    underline=$(tput sgr 0 1);

# Set Temp Directory
tmpDir="/tmp/${scriptName}.$RANDOM.$RANDOM.$RANDOM.$$"
(umask 077 && mkdir "${tmpDir}") || {
  die "Could not create temporary directory! Exiting."
}

# Logging & Feedback
logFile="${HOME}/Library/Logs/${scriptName%.sh}.log"

_alert_() {
  if [ "${1}" = "error" ]; then local color="${bold}${red}"; fi
  if [ "${1}" = "warning" ]; then local color="${red}"; fi
  if [ "${1}" = "success" ]; then local color="${green}"; fi
  if [ "${1}" = "debug" ]; then local color="${purple}"; fi
  if [ "${1}" = "header" ]; then local color="${bold}${tan}"; fi
  if [ "${1}" = "input" ]; then local color="${bold}"; fi
  if [ "${1}" = "dryrun" ]; then local color="${blue}"; fi
  if [ "${1}" = "info" ] || [ "${1}" = "notice" ]; then local color=""; fi
  # Don't use colors on pipes or non-recognized terminals
  if [[ "${TERM}" != "xterm"* ]] || [ -t 1 ]; then color=""; reset=""; fi

  # Print to console when script is not 'quiet'
  if ${quiet}; then tput cuu1 ; return; else # tput cuu1 moves cursor up one line
   echo -e "$(date +"%r") ${color}$(printf "[%7s]" "${1}") ${_message}${reset}";
  fi

  # Print to Logfile
  if ${printLog} && [ "${1}" != "input" ]; then
    color=""; reset="" # Don't use colors in logs
    echo -e "$(date +"%m-%d-%Y %r") $(printf "[%7s]" "${1}") ${_message}" >> "${logFile}";
  fi
}

function die ()       { local _message="${*} Exiting."; echo -e "$(_alert_ error)"; _safeExit_ "1";}
function error ()     { local _message="${*}"; echo -e "$(_alert_ error)"; }
function warning ()   { local _message="${*}"; echo -e "$(_alert_ warning)"; }
function notice ()    { local _message="${*}"; echo -e "$(_alert_ notice)"; }
function info ()      { local _message="${*}"; echo -e "$(_alert_ info)"; }
function debug ()     { local _message="${*}"; echo -e "$(_alert_ debug)"; }
function success ()   { local _message="${*}"; echo -e "$(_alert_ success)"; }
function dryrun()     { local _message="${*}"; echo -e "$(_alert_ dryrun)"; }
function input()      { local _message="${*}"; echo -n "$(_alert_ input)"; }
function header()     { local _message="== ${*} ==  "; echo -e "$(_alert_ header)"; }
function verbose()    { if ${verbose}; then debug "$@"; fi }


# Options and Usage
# -----------------------------------
_usage_() {
  echo -n "${scriptName} [OPTION]... [FILE]...

This script runs a series of installation scripts to configure a new computer running  Mac OSX.
It relies on a YAML config file 'config-macOS.yaml'. This YAML file will contain

  - symlinks
  - homebrew packages
  - homebrew casks
  - ruby gems
  - node packages

This script also looks for plugin scripts in a user configurable directory for added customization.

 ${bold}Options:${reset}

  -n, --dryrun      Non-destructive. Makes no permanent changes.
  -q, --quiet       Quiet (no output)
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
    -n|--dryrun) dryrun=true ;;
    -h|--help) _usage_ >&2; _safeExit_ ;;
    -v|--verbose) verbose=true ;;
    -l|--log) printLog=true ;;
    -q|--quiet) quiet=true ;;
    -s|--strict) strict=true;;
    -d|--debug) debug=true;;
    --source-only) sourceOnly=true ;;
    --version) echo "$(basename $0) ${version}"; _safeExit_ ;;
    --force) force=true ;;
    --endopts) shift; break ;;
    *) die "invalid option: '$1'." ;;
  esac
  shift
done

# Store the remaining part as arguments.
args+=("$@")

# Trap bad exits with your cleanup function
trap _trapCleanup_ EXIT INT TERM

# Set IFS to preferred implementation
IFS=$' \n\t'

# Exit on error. Append '||true' when you run the script if you expect an error.
# if using the 'execute' function this must be disabled for warnings to be shown if tasks fail
#set -o errexit

# Run in debug mode, if set
if ${debug}; then set -x ; fi

# Exit on empty variable
if ${strict}; then set -o nounset ; fi

# Exit the script if a command fails
# set -e

# Run your script unless in source only mode
if ! ${sourceOnly}; then _mainScript_ ; fi

# Exit cleanly
if ! ${sourceOnly}; then _safeExit_ ; fi