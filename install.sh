#!/usr/bin/env bash

_mainScript_() {

  while read -r f; do
    _makeSymlink_ "${f}" "${HOME}/$(basename "${f}")"
  done < <(find "$(_findBaseDir_)" -maxdepth 1 \
    -iregex '^/.*/\..*$' \
    -not -name '.vscode' \
    -not -name '.git' \
    -not -name '.DS_Store' \
    -not -name '.hooks' )

} # end _mainScript_

# Set initial flags
QUIET=false
LOGLEVEL=WARN
VERBOSE=false
FORCE=false
DRYRUN=false
declare -a args=()
now=$(LC_ALL=C date +"%m-%d-%Y %r")                   # Returns: 06-14-2015 10:34:40 PM
datestamp=$(LC_ALL=C date +%Y-%m-%d)                  # Returns: 2015-06-14
hourstamp=$(LC_ALL=C date +%r)                        # Returns: 10:34:40 PM
timestamp=$(LC_ALL=C date +%Y%m%d_%H%M%S)             # Returns: 20150614_223440
today=$(LC_ALL=C date +"%m-%d-%Y")                    # Returns: 06-14-2015
longdate=$(LC_ALL=C date +"%a, %d %b %Y %H:%M:%S %z") # Returns: Sun, 10 Jan 2016 20:47:53 -0500
gmtdate=$(LC_ALL=C date -u -R | sed 's/\+0000/GMT/')  # Returns: Wed, 13 Jan 2016 15:55:29 GMT

# Colors
if tput setaf 1 &>/dev/null; then
  bold=$(tput bold)
  white=$(tput setaf 7)
  reset=$(tput sgr0)
  purple=$(tput setaf 171)
  red=$(tput setaf 1)
  green=$(tput setaf 76)
  tan=$(tput setaf 3)
  yellow=$(tput setaf 3)
  blue=$(tput setaf 38)
  underline=$(tput sgr 0 1)
else
  bold="\033[4;37m"
  white="\033[0;37m"
  reset="\033[0m"
  purple="\033[0;35m"
  red="\033[0;31m"
  green="\033[1;32m"
  tan="\033[0;33m"
  yellow="\033[0;33m"
  blue="\033[0;34m"
  underline="\033[4;37m"
fi

_alert_() {
  # DESC:   Controls all printing of messages to log files and stdout.
  # ARGS:   $1 (required) - The type of alert to print
  #                         (success, header, notice, dryrun, debug, warning, error,
  #                         fatal, info, input)
  #         $2 (required) - The message to be printed to stdout and/or a log file
  #         $3 (optional) - Pass '$LINENO' to print the line number where the _alert_ was triggered
  # OUTS:   $logFile      - Path and filename of the logfile
  # USAGE:  [ALERTTYPE] "[MESSAGE]" "$LINENO"
  # NOTES:  If '$logFile' is not set, a new log file will be created
  #         The colors of each alert type are set in this function
  #         For specified alert types, the funcstac will be printed

  local scriptName logLocation logName function_name color
  local alertType="${1}"
  local message="${2}"
  local line="${3-}"

  [ -z "${scriptName-}" ] && scriptName="$(basename "$0")"

  if [ -z "${logFile-}" ]; then
    readonly logLocation="${HOME}/logs"
    readonly logName="${scriptName%.sh}.log"
    [ ! -d "${logLocation}" ] && mkdir -p "${logLocation}"
    logFile="${logLocation}/${logName}"
  fi

  if [ -z "${line}" ]; then
    [[ "$1" =~ ^(fatal|error|debug|warning) && "${FUNCNAME[2]}" != "_trapCleanup_" ]] \
      && message="${message} $(_functionStack_)"
  else
    [[ "$1" =~ ^(fatal|error|debug) && "${FUNCNAME[2]}" != "_trapCleanup_" ]] \
      && message="${message} (line: $line) $(_functionStack_)"
  fi

  if [ -n "${line}" ]; then
    [[ "$1" =~ ^(warning|info|notice|dryrun) && "${FUNCNAME[2]}" != "_trapCleanup_" ]] \
      && message="${message} (line: $line)"
  fi

  if [[ "${alertType}" =~ ^(error|fatal) ]]; then
    color="${bold}${red}"
  elif [ "${alertType}" = "warning" ]; then
    color="${red}"
  elif [ "${alertType}" = "success" ]; then
    color="${green}"
  elif [ "${alertType}" = "debug" ]; then
    color="${purple}"
  elif [ "${alertType}" = "header" ]; then
    color="${bold}${tan}"
  elif [[ "${alertType}" =~ ^(input|notice) ]]; then
    color="${bold}"
  elif [ "${alertType}" = "dryrun" ]; then
    color="${blue}"
  else
    color=""
  fi

  _writeToScreen_() {

    ("${QUIET}") && return 0  # Print to console when script is not 'quiet'
    [[ ${VERBOSE} == false && "${alertType}" =~ ^(debug|verbose) ]] && return 0

    if ! [[ -t 1 ]]; then  # Don't use colors on non-recognized terminals
      color=""
      reset=""
    fi

    echo -e "$(date +"%r") ${color}$(printf "[%7s]" "${alertType}") ${message}${reset}"
  }
  _writeToScreen_

  _writeToLog_() {
 [[ "${alertType}" == "input" ]] && return 0
    [[ "${LOGLEVEL}" =~ (off|OFF|Off) ]] && return 0
    [[ ! -f "${logFile}" ]] && touch "${logFile}"

    # Don't use colors in logs
    if command -v gsed &>/dev/null; then
      local cleanmessage="$(echo "${message}" | gsed -E 's/(\x1b)?\[(([0-9]{1,2})(;[0-9]{1,3}){0,2})?[mGK]//g')"
    else
      local cleanmessage="$(echo "${message}" | sed -E 's/(\x1b)?\[(([0-9]{1,2})(;[0-9]{1,3}){0,2})?[mGK]//g')"
    fi
    echo -e "$(date +"%b %d %R:%S") $(printf "[%7s]" "${alertType}") [$(/bin/hostname)] ${cleanmessage}" >>"${logFile}"
  }

# Write specified log level data to logfile
case "${LOGLEVEL:-ERROR}" in
  ALL|all|All)
    _writeToLog_
    ;;
  DEBUG|debug|Debug)
    _writeToLog_
    ;;
  INFO|info|Info)
    if [[ "${alertType}" =~ ^(die|error|fatal|warning|info|notice|success) ]]; then
      _writeToLog_
    fi
    ;;
  WARN|warn|Warn)
    if [[ "${alertType}" =~ ^(die|error|fatal|warning) ]]; then
      _writeToLog_
    fi
    ;;
  ERROR|error|Error)
    if [[ "${alertType}" =~ ^(die|error|fatal) ]]; then
      _writeToLog_
    fi
    ;;
  FATAL|fatal|Fatal)
    if [[ "${alertType}" =~ ^(die|fatal) ]]; then
      _writeToLog_
    fi
   ;;
  OFF|off)
    return 0
  ;;
  *)
    if [[ "${alertType}" =~ ^(die|error|fatal) ]]; then
      _writeToLog_
    fi
    ;;
esac

} # /_alert_

error() { _alert_ error "${1}" "${2-}"; }
warning() { _alert_ warning "${1}" "${2-}"; }
notice() { _alert_ notice "${1}" "${2-}"; }
info() { _alert_ info "${1}" "${2-}"; }
success() { _alert_ success "${1}" "${2-}"; }
dryrun() { _alert_ dryrun "${1}" "${2-}"; }
input() { _alert_ input "${1}" "${2-}"; }
header() { _alert_ header "== ${1} ==" "${2-}"; }
die() { _alert_ fatal "${1}" "${2-}"; _safeExit_ "1" ; }
fatal() { _alert_ fatal "${1}" "${2-}"; _safeExit_ "1" ; }
debug() { _alert_ debug "${1}" "${2-}"; }
verbose() { _alert_ debug "${1}" "${2-}"; }

_safeExit_() {
  # DESC: Cleanup and exit from a script
  # ARGS: $1 (optional) - Exit code (defaults to 0)
  # OUTS: None

  if [[ -d "${script_lock-}" ]]; then
    if command rm -rf "${script_lock}"; then
      debug "Removing script lock"
    else
      warning "Script lock could not be removed. Try manually deleting ${tan}'${lock_dir}'${red}"
    fi
  fi

  if [[ -n "${tmpDir-}" && -d "${tmpDir-}" ]]; then
    if [[ ${1-} == 1 && -n "$(ls "${tmpDir}")" ]]; then
      command rm -r "${tmpDir}"
    else
      command rm -r "${tmpDir}"
      debug "Removing temp directory"
    fi
  fi

  trap - INT TERM EXIT
  exit ${1:-0}
}

_trapCleanup_() {
  # DESC:  Log errors and cleanup from script when an error is trapped
  # ARGS:   $1 - Line number where error was trapped
  #         $2 - Line number in function
  #         $3 - Command executing at the time of the trap
  #         $4 - Names of all shell functions currently in the execution call stack
  #         $5 - Scriptname
  #         $6 - $BASH_SOURCE
  # OUTS:   None

  local line=${1-} # LINENO
  local linecallfunc=${2-}
  local command="${3-}"
  local funcstack="${4-}"
  local script="${5-}"
  local sourced="${6-}"

  funcstack="'$(echo "$funcstack" | sed -E 's/ / < /g')'"

  if [[ "${script##*/}" == "${sourced##*/}" ]]; then
    fatal "${7-} command: '$command' (line: $line) [func: $(_functionStack_)]"
  else
    fatal "${7-} command: '$command' (func: ${funcstack} called at line $linecallfunc of '${script##*/}') (line: $line of '${sourced##*/}') "
  fi

  _safeExit_ "1"
}

_execute_() {
  # DESC: Executes commands with safety and logging options
  # ARGS:  $1 (Required) - The command to be executed.  Quotation marks MUST be escaped.
  #        $2 (Optional) - String to display after command is executed
  # OPTS:  -v    Always print debug output from the execute function
  #        -p    Pass a failed command with 'return 0'.  This effecively bypasses set -e.
  #        -e    Bypass _alert_ functions and use 'echo RESULT'
  #        -s    Use '_alert_ success' for successful output. (default is 'info')
  #        -q    Do not print output (QUIET mode)
  # OUTS:  None
  # USE :  _execute_ "cp -R \"~/dir/somefile.txt\" \"someNewFile.txt\"" "Optional message"
  # NOTE:
  #        If $DRYRUN=true no commands are executed
  #        If $debug=true the command's native output is printed to stderr and stdin

  local localVerbose=false
  local passFailures=false
  local echoResult=false
  local successResult=false
  local quietResult=false
  local opt

  local OPTIND=1
  while getopts ":vVpPeEsSqQ" opt; do
    case $opt in
      v | V) localVerbose=true ;;
      p | P) passFailures=true ;;
      e | E) echoResult=true ;;
      s | S) successResult=true ;;
      q | Q) quietResult=true ;;
      *)
        {
          error "Unrecognized option '$1' passed to _execute_. Exiting."
          _safeExit_
        }
        ;;
    esac
  done
  shift $((OPTIND - 1))

  local cmd="${1:?_execute_ needs a command}"
  local message="${2:-$1}"

  local saveVerbose=$VERBOSE
  if "${localVerbose}"; then
    VERBOSE=true
  fi

  if "${DRYRUN}"; then
    if "$quietResult"; then
      VERBOSE=$saveVerbose
      return 0
    fi
    if [ -n "${2-}" ]; then
      dryrun "${1} (${2})" "$(caller)"
    else
      dryrun "${1}" "$(caller)"
    fi
  elif ${VERBOSE}; then
    if eval "${cmd}"; then
      if "$echoResult"; then
        echo "${message}"
      elif "${successResult}"; then
        success "${message}"
      else
        info "${message}"
      fi
      VERBOSE=$saveVerbose
      return 0
    else
      if "$echoResult"; then
        echo "warning: ${message}"
      else
        warning "${message}"
      fi
      VERBOSE=$saveVerbose
      "${passFailures}" && return 0 || return 1
    fi
  else
    if eval "${cmd}" &>/dev/null; then
      if "$quietResult"; then
        VERBOSE=$saveVerbose
        return 0
      elif "$echoResult"; then
        echo "${message}"
      elif "${successResult}"; then
        success "${message}"
      else
        info "${message}"
      fi
      VERBOSE=$saveVerbose
      return 0
    else
      if "$echoResult"; then
        echo "error: ${message}"
      else
        warning "${message}"
      fi
      VERBOSE=$saveVerbose
      "${passFailures}" && return 0 || return 1
    fi
  fi
}

_findBaseDir_() {
  # DESC: Locates the real directory of the script being run. similar to GNU readlink -n
  # ARGS:  None
  # OUTS:  Echo result to STDOUT
  # USE :  baseDir="$(_findBaseDir_)"

  local SOURCE
  local DIR

  # Is file sourced?
  [[ $_ != "$0" ]] \
    && SOURCE="${BASH_SOURCE[1]}" \
    || SOURCE="${BASH_SOURCE[0]}"

  while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="${DIR}/${SOURCE}" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  done
  echo "$(cd -P "$(dirname "${SOURCE}")" && pwd)"
}

_realpath_() {
  # DESC:   Convert a file with relative path to an absolute path
  # ARGS:   $1 (Required) - Input file
  # OPTS:   -d            - Print the directory information only, without the filename in the output
  # OUTS:   Prints absolute path of file. Returns 0 if successful or 1 if an error
  # NOTE:   http://github.com/morgant/realpath

  local file_basename
  local directory
  local output
  local showOnlyDir=false
  local OPTIND=1
  local opt

  while getopts ":dD" opt; do
    case $opt in
      d | D) showOnlyDir=true ;;
      *) {
        error "Unrecognized option '$1' passed to _execute. Exiting."
        _safeExit_
      }
        ;;
    esac
  done
  shift $((OPTIND - 1))

  local path="${1:?_realpath_ needs an input}"

  # make sure the string isn't empty as that implies something in further logic
  if [ -z "$path" ]; then
    return 1
  else
    # start with the file name (sans the trailing slash)
    path="${path%/}"

    # if we stripped off the trailing slash and were left with nothing, that means we're in the root directory
    if [ -z "$path" ]; then
      path="/"
    fi

    # get the basename of the file (ignoring '.' & '..', because they're really part of the path)
    file_basename="${path##*/}"
    if [[ ("$file_basename" == ".") || ("$file_basename" == "..") ]]; then
      file_basename=""
    fi

    # extracts the directory component of the full path, if it's empty then assume '.' (the current working directory)
    directory="${path%$file_basename}"
    if [ -z "$directory" ]; then
      directory='.'
    fi

    # attempt to change to the directory
    if ! cd "$directory" &>/dev/null; then
      return 1
    fi

    # does the filename exist?
    if [[ (-n "$file_basename") && (! -e "$file_basename") ]]; then
      return 1
    fi

    # get the absolute path of the current directory & change back to previous directory
    local abs_path
    abs_path="$(pwd -P)"
    cd "-" &>/dev/null || return

    # Append base filename to absolute path
    if [ "${abs_path}" = "/" ]; then
      output="${abs_path}${file_basename}"
    else
      output="${abs_path}/${file_basename}"
    fi

    # output the absolute path
    if ! $showOnlyDir ; then
      echo "${output}"
    else
      echo "${abs_path}"
    fi
  fi
}

_locateSourceFile_() {
  # DESC:   Find original file of a symlink
  # ARGS:   $1 (Required) - Input symlink
  # OUTS:   Print location of original file

  local TARGET_FILE
  local PHYS_DIR
  local RESULT

  # Error handling
  [ ! "$(declare -f "_realpath_")" ] \
    && {
      error "'_locateSourceFile_' requires function '_realpath_' "
      return 1
    }

  TARGET_FILE="${1:?_locateSourceFile_ needs a file}"

  cd "$(_realpath_ -d "${TARGET_FILE}")" &>/dev/null || return 1
  TARGET_FILE="$(basename "${TARGET_FILE}")"
  # Iterate down a (possible) chain of symlinks
  while [ -L "${TARGET_FILE}" ]; do
    TARGET_FILE=$(readlink "${TARGET_FILE}")
    cd "$(_realpath_ -d "${TARGET_FILE}")" &>/dev/null || return 1
    TARGET_FILE="$(basename "${TARGET_FILE}")"
  done

  # Compute the canonicalized name by finding the physical path
  # for the directory we're in and appending the target file.
  PHYS_DIR=$(pwd -P)
  RESULT="${PHYS_DIR}/${TARGET_FILE}"
  echo "${RESULT}"
  return 0
}

_backupFile_() {
  # DESC:   Creates a backup of a specified file with .bak.
  # ARGS:   $1 (Required)   - Source file
  #         $2 (Optional)   - Destination dir name used only with -d flag (defaults to ./backup)
  # OPTS:   -d              - Move files to a backup direcory
  #         -m              - Replaces copy (default) with move, effectively removing the
  # OUTS:   None
  # USAGE:  _backupFile_ "sourcefile.txt" "some/backup/dir"
  # NOTE:   dotfiles have their leading '.' removed in their backup

  local opt
  local OPTIND=1
  local useDirectory=false
  local moveFile=false

  while getopts ":dDmM" opt; do
    case ${opt} in
      d | D) useDirectory=true ;;
      m | M) moveFile=true ;;
      *)
        {
          error "Unrecognized option '$1' passed to _makeSymlink_" "${LINENO}"
          return 1
        }
        ;;
    esac
  done
  shift $((OPTIND - 1))

  [[ $# -lt 1 ]] && fatal 'Missing required argument to _backupFile_()!'

  local s="${1}"
  local d="${2:-backup}"
  local n # New filename (created by _uniqueFilename_)

  # Error handling
  [ ! "$(declare -f "_execute_")" ] \
    && {
      warning "need function _execute_"
      return 1
    }
  [ ! "$(declare -f "_uniqueFileName_")" ] \
    && {
      warning "need function _uniqueFileName_"
      return 1
    }
  [ ! -e "$s" ] \
    && {
      warning "Source '${s}' not found"
      return 1
    }

  if [ ${useDirectory} == true ]; then

    [ ! -d "${d}" ] \
      && _execute_ "mkdir -p \"${d}\"" "Creating backup directory"

    if [ -e "$s" ]; then
      n="$(basename "${s}")"
      n="$(_uniqueFileName_ "${d}/${s#.}")"
      if [ ${moveFile} == true ]; then
        _execute_ "mv \"${s}\" \"${d}/${n##*/}\"" "Moving: '${s}' to '${d}/${n##*/}'"
      else
        _execute_ "cp -R \"${s}\" \"${d}/${n##*/}\"" "Backing up: '${s}' to '${d}/${n##*/}'"
      fi
    fi
  else
    n="$(_uniqueFileName_ "${s}.bak")"
    if [ ${moveFile} == true ]; then
      _execute_ "mv \"${s}\" \"${n}\"" "Moving '${s}' to '${n}'"
    else
      _execute_ "cp -R \"${s}\" \"${n}\"" "Backing up '${s}' to '${n}'"
    fi
  fi
}

_makeSymlink_() {
  # DESC:   Creates a symlink and backs up a file which may be overwritten by the new symlink. If the
  #         exact same symlink already exists, nothing is done.
  #         Default behavior will create a backup of a file to be overwritten
  # ARGS:   $1 (Required) - Source file
  #         $2 (Required) - Destination
  #         $3 (Optional) - Backup directory for files which may be overwritten (defaults to 'backup')
  # OPTS:  -n             - Do not create a backup if target already exists
  #        -s             - Use sudo when removing old files to make way for new symlinks
  # OUTS:   None
  # USAGE:  _makeSymlink_ "/dir/someExistingFile" "/dir/aNewSymLink" "/dir/backup/location"
  # NOTE:   This function makes use of the _execute_ function

  local opt
  local OPTIND=1
  local backupOriginal=true
  local useSudo=false

  while getopts ":nNsS" opt; do
    case $opt in
      n | N) backupOriginal=false ;;
      s | S) useSudo=true ;;
      *)
        {
          error "Unrecognized option '$1' passed to _makeSymlink_" "$LINENO"
          return 1
        }
        ;;
    esac
  done
  shift $((OPTIND - 1))

  if ! command -v realpath >/dev/null 2>&1; then
    error "We must have 'realpath' installed and available in \$PATH to run."
    if [[ "$OSTYPE" == "darwin"* ]]; then
      notice "Install coreutils using homebrew and rerun this script."
      info "\t$ brew install coreutils"
    fi
    _safeExit_ 1
  fi

  [[ $# -lt 2 ]] && fatal 'Missing required argument to _makeSymlink_()!'

  local s="$1"
  local d="$2"
  local b="${3-}"
  local o

  # Fix files where $HOME is written as '~'
  d="${d/\~/$HOME}"
  s="${s/\~/$HOME}"
  b="${b/\~/$HOME}"

  [ ! -e "$s" ] \
    && {
      error "'$s' not found"
      return 1
    }
  [ -z "$d" ] \
    && {
      error "'${d}' not specified"
      return 1
    }
  [ ! "$(declare -f "_execute_")" ] \
    && {
      echo "need function _execute_"
      return 1
    }
  [ ! "$(declare -f "_backupFile_")" ] \
    && {
      echo "need function _backupFile_"
      return 1
    }

  # Create destination directory if needed
  [ ! -d "${d%/*}" ] \
    && _execute_ "mkdir -p \"${d%/*}\""

  if [ ! -e "${d}" ]; then
    _execute_ "ln -fs \"${s}\" \"${d}\"" "symlink ${s} → ${d}"
  elif [ -h "${d}" ]; then
    o="$(realpath "${d}")"

    [[ "${o}" == "${s}" ]] && {
      if [ "${DRYRUN}" == true ]; then
        dryrun "Symlink already exists: ${s} → ${d}"
      else
        info "Symlink already exists: ${s} → ${d}"
      fi
      return 0
    }

    if [[ "${backupOriginal}" == true ]]; then
      _backupFile_ "${d}" "${b:-backup}"
    fi
    if [[ "${DRYRUN}" == false ]]; then
      if [[ "${useSudo}" == true ]]; then
        command rm -rf "${d}"
      else
        command rm -rf "${d}"
      fi
    fi
    _execute_ "ln -fs \"${s}\" \"${d}\"" "symlink ${s} → ${d}"
  elif [ -e "${d}" ]; then
    if [[ "${backupOriginal}" == true ]]; then
      _backupFile_ "${d}" "${b:-backup}"
    fi
    if [[ "${DRYRUN}" == false ]]; then
      if [[ "${useSudo}" == true ]]; then
        sudo command rm -rf "${d}"
      else
        command rm -rf "${d}"
      fi
    fi
    _execute_ "ln -fs \"${s}\" \"${d}\"" "symlink ${s} → ${d}"
  else
    warning "Error linking: ${s} → ${d}"
    return 1
  fi
  return 0
}

_functionStack_() {
  # DESC:   Prints the function stack in use
  # ARGS:   None
  # OUTS:   Prints [function]:[file]:[line]
  # NOTE:   Does not print functions from the alert class
  local _i
  funcStackResponse=()
  for ((_i = 1; _i < ${#BASH_SOURCE[@]}; _i++)); do
    case "${FUNCNAME[$_i]}" in "_alert_" | "_trapCleanup_" | fatal | error | warning | verbose | debug | die) continue ;; esac
    funcStackResponse+=("${FUNCNAME[$_i]}:$(basename ${BASH_SOURCE[$_i]}):${BASH_LINENO[$_i - 1]}")
  done
  printf "( "
  printf %s "${funcStackResponse[0]}"
  printf ' < %s' "${funcStackResponse[@]:1}"
  printf ' )\n'
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
      -l | --loglevel)
        shift
        LOGLEVEL=${1}
        ;;
      -n | --dryrun) DRYRUN=true ;;
      -v | --verbose) VERBOSE=true ;;
      -q | --quiet) QUIET=true ;;
      --force) FORCE=true ;;
      --endopts)
        shift
        break
        ;;
      *) fatal "invalid option: '$1'." ;;
    esac
    shift
  done
  args+=("$@") # Store the remaining user input as arguments.
}

_usage_() {
  cat <<EOF

  ${bold}$(basename "$0") [OPTION]...${reset}

  This script creates symlinks in the user's home directory to the dotfiles contained in this repository.

  ${bold}Options:${reset}
    -h, --help        Display this help and exit
    -l, --loglevel    One of: FATAL, ERROR, WARN, INFO, DEBUG, ALL, OFF  (Default is 'ERROR')

      $ $(basename "$0") --loglevel 'WARN'

    -n, --dryrun      Non-destructive. Makes no permanent changes.
    -q, --quiet       Quiet (no output)
    -v, --verbose     Output more information. (Items echoed to 'verbose')
    --force           Skip all user interaction.  Implied 'Yes' to all actions.
EOF
}

# Initialize and run the script
trap '_trapCleanup_ ${LINENO} ${BASH_LINENO} "${BASH_COMMAND}" "${FUNCNAME[*]}" "${0}" "${BASH_SOURCE[0]}"' \
  EXIT INT TERM SIGINT SIGQUIT
set -o errtrace                           # Trap errors in subshells and functions
set -o errexit                            # Exit on error. Append '||true' if you expect an error
set -o pipefail                           # Use last non-zero exit code in a pipeline
# shopt -s nullglob globstar              # Make `for f in *.txt` work when `*.txt` matches zero files
IFS=$' \n\t'                              # Set IFS to preferred implementation
# set -o xtrace                           # Run in debug mode
set -o nounset                            # Disallow expansion of unset variables
_parseOptions_ "$@"                       # Parse arguments passed to script
_mainScript_                              # Run the main logic script
_safeExit_                                # Exit cleanly
