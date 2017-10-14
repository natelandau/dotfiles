#!/usr/bin/env bash
# shellcheck disable=2154
version="1.0.0"

_mainScript_() {

  if ! [[ "$OSTYPE" =~ "darwin"* ]]; then
    notice "Can only run on macOS.  Exiting."
    _safeExit_
  fi

  if [[ "$OSTYPE" == "darwin"* ]]; then
    _configureITerm2_() {
      header "Configuring iTerm..."

      if ! [ -e /Applications/iTerm.app ]; then
        warning "Could not find iTerm.app. Please install iTerm and run this again."
        return
      else

        # iTerm config files location
        iTermConfig="${baseDir}/config/iTerm"

        if [ -d "${iTermConfig}" ]; then

          # 1. Copy fonts
          fontLocation="${HOME}/Library/Fonts"
          for font in ${iTermConfig}/fonts/**/*.otf; do
            baseFontName=$(basename "$font")
            destFile="${fontLocation}/${baseFontName}"
            if [ ! -e "$destFile" ]; then
              _execute_ "cp \"${font}\" \"$destFile\""
            fi
          done

          # 2. symlink preferences
          sourceFile="${iTermConfig}/com.googlecode.iterm2.plist"
          destFile="${HOME}/Library/Preferences/com.googlecode.iterm2.plist"

          if [ ! -e "$destFile" ]; then
            _execute_ "cp \"${sourceFile}\" \"${destFile}\"" "cp $sourceFile → $destFile"
          elif [ -h "$destFile" ]; then
            originalFile=$(_locateSourceFile_ "$destFile")
            _backupOriginalFile_ "$originalFile"
            if ! $dryrun; then rm -rf "$destFile"; fi
            _execute_ "cp \"$sourceFile\" \"$destFile\"" "cp $sourceFile → $destFile"
          elif [ -e "$destFile" ]; then
            _backupOriginalFile_ "$destFile"
            if ! $dryrun; then rm -rf "$destFile"; fi
            _execute_ "cp \"$sourceFile\" \"$destFile\"" "cp $sourceFile → $destFile"
          else
            warning "Error linking: $sourceFile → $destFile"
          fi

          #3 Install preferred colorscheme
          _execute_ "open ${baseDir}/config/iTerm/themes/dotfiles.itermcolors" "Installing preferred color scheme"
        else
          warning "Couldn't find iTerm configuration files"
        fi
      fi
    }
    _configureITerm2_
  fi
}

_trapCleanup_() {
  echo ""
  die "Exit trapped. In function: '${FUNCNAME[*]:1}'"
}

_safeExit_() {
  trap - INT TERM EXIT
  exit ${1:-0}
}

_backupOriginalFile_() {
  local newFile
  local backupDir

  # Set backup directory location
  backupDir="${baseDir}/dotfiles_backup"

  if [[ ! -d "$backupDir" && "$dryrun" == false ]]; then
    _execute_ "mkdir \"$backupDir\"" "Creating backup dir: $backupDir"
  fi

  if [ -e "$1" ]; then
    newFile="$(basename "$1")"
    _execute_ "cp -R \"${1}\" \"${backupDir}/${newFile#.}\"" "Backing up: ${newFile}"
  fi
}

_seekConfirmation_() {
  # v1.0.1
  input "$@"
  if "${force}"; then
    verbose "Forcing confirmation with '--force' flag set"
    echo -e ""
    return 0
  else
    while true; do
      read -r -p " (y/n) " yn
      case $yn in
        [Yy]* ) return 0;;
        [Nn]* ) return 1;;
        * ) input "Please answer yes or no.";;
      esac
    done
  fi
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

# Set Base Variables
# ----------------------
scriptName=$(basename "$0")

# Set Flags
quiet=false;              printLog=false;             verbose=false;
force=false;              strict=false;               dryrun=false;
debug=false;              sourceOnly=false;           args=();

# Set Colors
bold=$(tput bold);        reset=$(tput sgr0);         purple=$(tput setaf 171);
red=$(tput setaf 1);      green=$(tput setaf 76);     tan=$(tput setaf 3);
blue=$(tput setaf 38);    underline=$(tput sgr 0 1);

# Logging & Feedback
logFile="${HOME}/Library/Logs/${scriptName%.sh}.log"

_alert_() {
  # v1.0.0
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

This script configures iTerm on Mac OS

 ${bold}Options:${reset}
  -n, --dryrun      Non-destructive. Makes no permanent changes.
  -q, --quiet       Quiet (no output)
  -l, --log         Print log to file
  -s, --strict      Exit script with null variables.  i.e 'set -o nounset'
  -v, --verbose     Output more information. (Items echoed to 'verbose')
  -d, --debug       Runs script in BASH debug mode (set -x)
  -h, --help        Display this help and exit
      --version     Output version information and exit
      --source-only Bypasses main script functionality to allow unit tests of functions
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
trap _trapCleanup_ EXIT INT TERM

# Set IFS to preferred implementation
IFS=$' \n\t'

# Exit on error. Append '||true' when you run the script if you expect an error.
# if using the 'execute' function this must be disabled for warnings to be shown if tasks fail
#set -o errexit

# Force pipelines to fail on the first non-zero status code.
set -o pipefail

# Run in debug mode, if set
if ${debug}; then set -x ; fi

# Exit on empty variable
if ${strict}; then set -o nounset ; fi

# Exit the script if a command fails
#set -e

# Run your script unless in 'source-only' mode
if ! ${sourceOnly}; then _mainScript_; fi

# Exit cleanly
if ! ${sourceOnly}; then _safeExit_; fi