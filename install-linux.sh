#!/usr/bin/env bash

version="1.0.0"

_mainScript_() {

  [[ "$OSTYPE" != "linux-gnu" ]] && die "We are not on Linux"

  # Get privs upfront
  sudo -v

  # Set Variables
  baseDir="$(_findBaseDir_)"
  utilsFile="${baseDir}/lib/utils.sh"
  configFile="${baseDir}/install-config.yaml"
  privateInstallScript="${HOME}/dotfiles-private/privateInstall.sh"
  bootstrapScripts="${baseDir}/lib/bootstrap"
  configureScripts="${baseDir}/lib/configure"

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

  # Upgrade apt-get
  if [ -f "/etc/apt/sources.list" ]; then
    notice "Updating apt-get"
    sudo apt-get update
    sudo apt-get upgrade -y
  else
    die "Can not proceed without apt-get"
  fi

  header "Now performing user actions"

  _generateKey_() {
    notice "generating public ssh key...."
    input "what is your email? [ENTER]: "
    read -r EMAIL

    ssh-keygen -t rsa -b 4096 -C "$EMAIL"
  }
  #_generateKey_

 _doSymlinks_() {

    if ! _seekConfirmation_ "Create symlinks?"; then return; fi

    [ ! -d "${HOME}/bin" ] && _execute_ "mkdir \"${HOME}/bin\""

    filesToLink=("${symlinks[@]}") # array is populated from YAML
    _createSymlinks_ "Symlinks"
    unset filesToLink
  }
  _doSymlinks_

  _installGitHooks_() {
    info "Installing git hooks for this repository..."

    local GITROOT
    local hook
    GITROOT=$(git rev-parse --show-toplevel 2> /dev/null)

    if [ "${GITROOT}" == "" ]; then
      warning "This does not appear to be a git repo."
      return
    fi

    # Location of hooks
    local hooksLocation="${GITROOT}/.hooks"

    if ! [ -d "$hooksLocation" ]; then
      warning "Can't find hooks. Exiting."
      return
    fi

    for hook in ${hooksLocation}/*.sh; do
      hook="$(basename ${hook})"

      local sourceFile="${hooksLocation}/${hook}"
      local destFile="${GITROOT}/.git/hooks/${hook%.sh}"

      if [ -e "$destFile" ]; then
        _execute_ "rm $destFile"
      fi
      _execute_ "ln -fs \"$sourceFile\" \"$destFile\"" "symlink $sourceFile → $destFile"

    done
  }
  _installGitHooks_

  _execute_ "sudo bash < <( curl https://raw.github.com/jamiew/git-friendly/master/install.sh)"


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

_executeFunction_() {
  local functionName="$1"
  local functionDesc="${2:-next step?}"

  if _seekConfirmation_ "${functionDesc}?"; then
    "${functionName}"
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
    sourceFile="${baseDir}/${sourceFile}"

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
scriptName=$(basename "$0")

# Set Flags
quiet=false;              printLog=false;             verbose=false;
force=false;              strict=false;               dryrun=false;
debug=false;              sourceOnly=false;           args=();

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
  # _execute_ - wrap an external command in '_execute_' to push native output to /dev/null
  #           and have control over the display of the results.  In "dryrun" mode these
  #           commands are not executed at all. In Verbose mode, the commands are executed
  #           with results printed to stderr and stdin
  #
  # usage:
  #   _execute_ "cp -R \"~/dir/somefile.txt\" \"someNewFile.txt\"" "Optional message to print to user"
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
      #error "${message}"
      die "${message}"
    fi
  fi
}
# Options and Usage
# -----------------------------------
_usage_() {
  echo -n "${scriptName} [OPTION]... [FILE]...

This is a script template.  Edit this description to print help to users.

 ${bold}Options:${reset}
  -u, --username    Username for script
  -p, --password    User password
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
    -u|--username) shift; username=${1} ;;
    -p|--password) shift; echo "Enter Pass: "; stty -echo; read -r PASS; stty echo;
      echo ;;
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
