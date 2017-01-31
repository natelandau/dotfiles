#!/usr/bin/env bash

function mainScript() {

  function findBaseDir() {
    # fincBaseDir locates the real directory of the script. similar to GNU readlink -n

    local SOURCE
    local DIR
    SOURCE="${BASH_SOURCE[0]}"
    while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
      DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
      SOURCE="$(readlink "$SOURCE")"
      [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    baseDir="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  }
  findBaseDir

  # Set Variables
  utilsFile="${baseDir}/lib/utils.sh"
  configFile="${baseDir}/lib/config-install.yaml"
  privateDir="${baseDir}/private"
  privateConfig="private-install.yaml"

  function sourceFiles() {
    if [ -f "$utilsFile" ]; then
      source "$utilsFile"
    else
      die "Can't find $utilsFile"
    fi
    if [ -f "$configFile" ]; then
      yamlConfigVariables="$tmpDir/yamlConfigVariables.txt"
      parse_yaml "$configFile" > "$yamlConfigVariables"
      source "$yamlConfigVariables"
      # In verbose mode, echo the variables for debugging purposes
      if $verbose; then verbose "-- Config Variables --"; readFile "$yamlConfigVariables"; fi
    else
      die "Can't find $configFile"
    fi
  }
  sourceFiles

  function backupOriginalFile() {
    local newFile
    local backupDir

    # Set backup directory location
    backupDir="${baseDir}/dotfiles_backup"

    if [[ ! -d "$backupDir" && "$dryrun" == false ]]; then
      execute "mkdir $backupDir" "Creating backup directory"
    fi

    if [ -e "$1" ]; then
      newFile="$(basename $1)"
      execute "cp -R ${1} ${backupDir}/${newFile#.}" "Backing up: ${newFile}"
    fi
  }

  function createSymLinks() {
    # This function takes an input of the YAML variable containing the symlinks to be linked
    # and then creates the appropriate symlinks in the home directory. it will also backup existing files if there.

    local link=""
    local destFile=""
    local sourceFile=""

    header "Creating ${1:-symlinks}"

    # Confirm a user wants to proceed
    if ! $dryrun && ! $symlinksOK && ! seek_confirmation "Warning: This script will overwrite your current dotfiles. Continue?"; then
      notice "Continuing without symlinks..."
      return
    else
      symlinksOK=true
    fi

    # For each link do the following
    for link in "${filesToLink[@]}"; do
      verbose "Working on: $link"
      # Parse destination and source
      destFile=$(echo "$link" | cut -d':' -f1 | trim)
      sourceFile=$(echo "$link" | cut -d':' -f2 | trim)
      sourceFile=$(echo "$sourceFile" | cut -d'#' -f1 | trim) # remove comments if exist

      # Fix files where $HOME is written as '~'
      destFile="${destFile/\~/$HOME}"

      # Grab the absolute path for the source
      sourceFile="${baseDir}/$sourceFile"

      # If we can't find a source file, skip it
      if ! test -e "$sourceFile"; then
        warning "Can't find '$sourceFile'."
        continue
      fi

      # Now we symlink the files
      if [ ! -e "$destFile" ]; then
        execute "ln -fs $sourceFile $destFile" "symlink $sourceFile → $destFile"
      elif [ -h "$destFile" ]; then
        originalFile=$(locateSourceFile "$destFile")
        backupOriginalFile "$originalFile"
        if ! $dryrun; then rm -rf "$destFile"; fi
        execute "ln -fs $sourceFile $destFile" "symlink $sourceFile → $destFile"
      elif [ -e "$destFile" ]; then
        backupOriginalFile "$destFile"
        if ! $dryrun; then rm -rf "$destFile"; fi
        execute "ln -fs $sourceFile $destFile" "symlink $sourceFile → $destFile"
      else
        warning "Error linking: $sourceFile → $destFile"
      fi
    done
  }

  function runBootstrapScripts() {
    local script
    local bootstrapScripts

    header "Running bootstrap scripts"

    bootstrapScripts="${baseDir}/lib/bootstrap"
    if [ ! -d "$bootstrapScripts" ]; then die "Can't find install scripts."; fi

    # Run the bootstrap scripts in numerical order

    #Show detailed command information
    saveVerbose=$verbose
    verbose=true

    set +e # Don't quit install.sh when a sub-script fails
    for script in ${bootstrapScripts}/[0-9]*.sh; do
      . $script
    done
    set -e
    verbose=$saveVerbose
  }
  if $config_doBootstrap; then runBootstrapScripts; fi

  if $config_doSymlinks; then
    filesToLink=("${symlinks[@]}")
    createSymLinks "Symlinks"
    unset filesToLink
  fi

  function privateRepo() {

    if ! [ -d "$privateDir" ]; then
      warning "Can't find private directory. Skipping..."
      havePrivateRepo=false
      return
    fi
    if ! [ -f "$privateDir/$privateConfig" ]; then
      warning "Can't find private YAML. Skipping..."
      havePrivateRepo=false
      return
    fi

    # Source YAML Variables
    prvtYamlConfigVariables="$tmpDir/prvtYamlConfigVariables.txt"
    parse_yaml "$privateDir/$privateConfig" > "$prvtYamlConfigVariables"
    source "$prvtYamlConfigVariables"
    # In verbose mode, echo the variables for debugging purposes
    if $verbose; then verbose "-- Private Config Variables --"; readFile "$prvtYamlConfigVariables"; fi

    filesToLink=("${privateSymlinks[@]}")

    createSymLinks "Private Symlinks"

    unset filesToLink
  }
  if $config_privateRepo; then privateRepo; fi

  function installHomebrewPackages() {
    local tap
    local package
    local cask
    local testInstalled

    header "Installing Homebrew Packages"

    #confirm homebrew is installed
    if test ! "$(which brew)"; then
      die "Can not continue without homebrew."
      #notice "Installing Homebrew..."
      # ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi

    #Show Brew Update can take forever if we're not bootstrapping. show the output
    saveVerbose=$verbose
    verbose=true

    # Make sure we’re using the latest Homebrew
    execute "brew update"

    # Reset verbose settings
    verbose=$saveVerbose

    # Upgrade any already-installed formulae
    execute "caffeinate -ism brew upgrade" "Upgrade existing formulae"

    # Install taps
    for tap in "${homebrewTaps[@]}"; do
      tap=$(echo "$tap" | cut -d'#' -f1 | trim) # remove comments if exist
      execute "brew tap $tap"
    done

    # Install packages
    for package in "${homebrewPackages[@]}"; do

      package=$(echo "$package" | cut -d'#' -f1 | trim) # remove comments if exist

      # strip flags from package names
      testInstalled=$(echo "$package" | cut -d' ' -f1 | trim)

      if brew ls --versions "$testInstalled" > /dev/null; then
        info "$testInstalled already installed"
      else
        execute "brew install $package" "Install $testInstalled"
      fi
    done

    # Install mac apps via homebrew cask
    for cask in "${homebrewCasks[@]}"; do

      cask=$(echo "$cask" | cut -d'#' -f1 | trim) # remove comments if exist

      # strip flags from package names
      testInstalled=$(echo "$cask" | cut -d' ' -f1 | trim)

      if brew cask ls "$testInstalled" &> /dev/null; then
        info "$testInstalled already installed"
      else
        execute "brew cask install $cask" "Install $testInstalled"
      fi

    done

    # cleanup after ourselves
    execute "brew cleanup"
    execute "brew doctor"

  }
  if $config_doHomebrew; then installHomebrewPackages; fi

  function installNodePackages() {
    local package
    local npmPackages
    local modules

    header "Installing global node packages"

    #confirm node is installed
    if test ! "$(which node)"; then
      warning "Can not install npm packages without node"
      info "Run 'brew install node'"
      return
    fi

    # Grab packages already installed
    { pushd "$(npm config get prefix)/lib/node_modules"; installed=(*); popd; } >/dev/null

    #Show nodes's detailed install information
    saveVerbose=$verbose
    verbose=true

    # If comments exist in the list of npm packaged to be installed remove them
    for package in "${nodePackages[@]}"; do
      npmPackages+=($(echo "$package" | cut -d'#' -f1 | trim) )
    done

    # Install packages that do not already exist
    modules=($(setdiff "${npmPackages[*]}" "${installed[*]}"))
    if (( ${#modules[@]} > 0 )); then
      pushd $HOME > /dev/null; execute "npm install -g ${modules[*]}"; popd > /dev/null;
    else
      info "All node packages already installed"
    fi

    # Reset verbose settings
    verbose=$saveVerbose
  }
  if $config_doNode; then installNodePackages; fi

  function installRubyPackages() {

    header "Installing global ruby gems"

    for gem in "${rubyGems[@]}"; do

      # Strip comments
      gem=$(echo "$gem" | cut -d'#' -f1 | trim)

      # strip flags from package names
      testInstalled=$(echo "$gem" | cut -d' ' -f1 | trim)

      if ! gem list $testInstalled -i >/dev/null; then
        pushd $HOME > /dev/null; execute "gem install $gem" "install $gem"; popd > /dev/null;
      else
        info "$testInstalled already installed"
      fi

    done
  }
  if $config_doRuby; then installRubyPackages; fi

  function runConfigureScripts() {
    local script
    local configureScripts

    header "Running configure scripts"

    configureScripts="${baseDir}/lib/configure"
    if [ ! -d "$configureScripts" ]; then die "Can't find install scripts."; fi

    # Run the bootstrap scripts in numerical order

    set +e # Don't quit install.sh when a sub-script fails
    # Always show command responses
    for script in ${configureScripts}/[0-9]*.sh; do
      . $script
    done
    set -e
  }
  if $config_doConfigure; then runConfigureScripts; fi

} ## End mainscript

function trapCleanup() {
  echo ""
  # Delete temp files, if any
  if [ -d "${tmpDir}" ] ; then
    rm -r "${tmpDir}"
  fi
  die "Exit trapped. In function: '${FUNCNAME[*]}'"
}

function safeExit() {
  # Delete temp files, if any
  if [ -d "${tmpDir}" ] ; then
    rm -r "${tmpDir}"
  fi
  trap - INT TERM EXIT
  exit
}

# Set Base Variables
# ----------------------
scriptName=$(basename "$0")

# Set Flags
quiet=false
printLog=false
verbose=false
force=false
strict=false
debug=false
dryrun=false
symlinksOK=false
args=()

# Set Colors
bold=$(tput bold)
reset=$(tput sgr0)
purple=$(tput setaf 171)
red=$(tput setaf 1)
green=$(tput setaf 76)
tan=$(tput setaf 3)
blue=$(tput setaf 38)
underline=$(tput sgr 0 1)

# Set Temp Directory
tmpDir="/tmp/${scriptName}.$RANDOM.$RANDOM.$RANDOM.$$"
(umask 077 && mkdir "${tmpDir}") || {
  die "Could not create temporary directory! Exiting."
}

# Logging
logFile="${HOME}/Library/Logs/${scriptBasename}.log"

# Logging & Feedback
# -----------------------------------------------------
function _alert() {
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
  if ${quiet}; then return; else
   echo -e "$(date +"%r") ${color}$(printf "[%7s]" "${1}") ${_message}${reset}";
  fi

  # Print to Logfile
  if ${printLog} && [ "${1}" != "input" ]; then
    color=""; reset="" # Don't use colors in logs
    echo -e "$(date +"%m-%d-%Y %r") $(printf "[%7s]" "${1}") ${_message}" >> "${logFile}";
  fi
}

function die ()       { local _message="${*} Exiting."; echo -e "$(_alert error)"; safeExit;}
function error ()     { local _message="${*}"; echo -e "$(_alert error)"; }
function warning ()   { local _message="${*}"; echo -e "$(_alert warning)"; }
function notice ()    { local _message="${*}"; echo -e "$(_alert notice)"; }
function info ()      { local _message="${*}"; echo -e "$(_alert info)"; }
function debug ()     { local _message="${*}"; echo -e "$(_alert debug)"; }
function success ()   { local _message="${*}"; echo -e "$(_alert success)"; }
function input()      { local _message="${*}"; echo -n "$(_alert input)"; }
function dryrun()      { local _message="${*}"; echo -e "$(_alert dryrun)"; }
function header()     { local _message="== ${*} ==  "; echo -e "$(_alert header)"; }
function verbose()    { if ${verbose}; then debug "$@"; fi }

# Options and Usage
# -----------------------------------
usage() {
  echo -n "${scriptName} [OPTION]... [FILE]...

This is a script template.  Edit this description to print help to users.

 ${bold}Options:${reset}
  --force           Skip all user interaction.  Implied 'Yes' to all actions.

  -n, --dryrun      Non-destructive. Makes no permanent changes.
  -q, --quiet       Quiet (no output)
  -l, --log         Print log to file
  -s, --strict      Exit script with null variables.  i.e 'set -o nounset'
  -v, --verbose     Output more information. (Items echoed to 'verbose')
  -d, --debug       Runs script in BASH debug mode (set -x)
  -h, --help        Display this help and exit
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
#[[ $# -eq 0 ]] && set -- "--help"

# Read the options and set stuff
while [[ $1 = -?* ]]; do
  case $1 in
    -n|--dryrun) dryrun=true ;;
    -h|--help) usage >&2; safeExit ;;
    -v|--verbose) verbose=true ;;
    -l|--log) printLog=true ;;
    -q|--quiet) quiet=true ;;
    -s|--strict) strict=true;;
    -d|--debug) debug=true;;
    --force) force=true ;;
    --endopts) shift; break ;;
    *) die "invalid option: '$1'." ;;
  esac
  shift
done

# Store the remaining part as arguments.
args+=("$@")

function seek_confirmation() {
  # Seeks a Yes or No answer to a question.  Usage:
  #   if seek_confirmation "Answer this question"; then
  #     something
  #   fi
  input "$@"
  if "${force}"; then
    echo ""
    verbose "Forcing confirmation with '--force' flag set"
    return 0
  else
    while true; do
      read -p " (y/n) " yn
      case $yn in
        [Yy]* ) return 0 ;;
        [Nn]* ) return 1 ;;
        * ) input "Please answer yes or no." ;;
      esac
    done
  fi
}

function execute() {
  # execute - wrap an external command in 'execute' to push native output to /dev/null
  #           and have control over the display of the results.  In "dryrun" mode these
  #           commands are not executed at all. In Verbose mode, the commands are executed
  #           with results printed to stderr and stdin
  #
  # usage:
  #   execute "cp -R somefile.txt someNewFile.txt" "Optional message to print to user"
  if ${dryrun}; then
    dryrun "${2:-$1}"
  else
    set +e # don't exit on error
    info "${2:-$1} ..."
    if $verbose; then
      eval "$1"
    else
      eval "$1" &> /dev/null
    fi
    if [ $? -eq 0 ]; then
      success "${2:-$1}"
    else
      warning "${2:-$1}"
    fi
    set -e
  fi
}
# Trap bad exits with your cleanup function
trap trapCleanup EXIT INT TERM

# Set IFS to preferred implementation
IFS=$' \n\t'

# Exit on error. Append '||true' when you run the script if you expect an error.
#set -o errexit

# Run in debug mode, if set
if ${debug}; then set -x ; fi

# Exit on empty variable
if ${strict}; then set -o nounset ; fi

# Exit on error
set -e

# Run your script
mainScript

# Exit cleanly
safeExit