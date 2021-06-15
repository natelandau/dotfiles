#!/usr/bin/env bash

_mainScript_() {

  echo -e "hello world"

} # end _mainScript_

# Set initial flags
quiet=false
LOGLEVEL=WARN
verbose=false
force=false
dryrun=false
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

    ("${quiet}") && return 0  # Print to console when script is not 'quiet'
    [[ ${verbose} == false && "${alertType}" =~ ^(debug|verbose) ]] && return 0

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

_usage_() {
  cat <<EOF

  ${bold}$(basename "$0") [OPTION]... [FILE]...${reset}

  This is a script template.  Edit this description to print help to users.

  ${bold}Options:${reset}
    -u, --username    Username for script

      $ $(basename "$0") --username 'USERNAME'

    -p, --password    User password

      $ $(basename "$0") --password 'PASSWORD'

    -h, --help        Display this help and exit
    -l, --loglevel    One of: FATAL, ERROR, WARN, INFO, DEBUG, ALL, OFF  (Default is 'ERROR')

      $ $(basename "$0") --loglevel 'WARN'

    -n, --dryrun      Non-destructive. Makes no permanent changes.
    -q, --quiet       Quiet (no output)
    -v, --verbose     Output more information. (Items echoed to 'verbose')
    --force           Skip all user interaction.  Implied 'Yes' to all actions.
EOF
}

_safeExit_() {
  # DESC: Cleanup and exit from a script
  # ARGS: $1 (optional) - Exit code (defaults to 0)
  # OUTS: None

  if [[ -d "${script_lock-}" ]]; then
    if command rm -rf "${script_lock}"; then
      verbose "Removing script lock"
    else
      warning "Script lock could not be removed. Try manually deleting ${tan}'${lock_dir}'${red}"
    fi
  fi

  if [[ -n "${tmpDir-}" && -d "${tmpDir-}" ]]; then
    if [[ ${1-} == 1 && -n "$(ls "${tmpDir}")" ]]; then
      command rm -r "${tmpDir}"
    else
      command rm -r "${tmpDir}"
      verbose "Removing temp directory"
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

_makeTempDir_() {
  # DESC:   Creates a temp direcrtory to house temporary files
  # ARGS:   $1 (Optional) - First characters/word of directory name
  # OUTS:   $tmpDir       - Temporary directory
  # USAGE:  _makeTempDir_ "$(basename "$0")"

  [ -d "${tmpDir:-}" ] && return 0

  if [ -n "${1-}" ]; then
    tmpDir="${TMPDIR:-/tmp/}${1}.$RANDOM.$RANDOM.$$"
  else
    tmpDir="${TMPDIR:-/tmp/}$(basename "$0").$RANDOM.$RANDOM.$RANDOM.$$"
  fi
  (umask 077 && mkdir "${tmpDir}") || {
    fatal "Could not create temporary directory! Exiting."
  }
  verbose "\$tmpDir=$tmpDir"
}

_acquireScriptLock_() {
  # DESC: Acquire script lock
  # ARGS: $1 (optional) - Scope of script execution lock (system or user)
  # OUTS: $script_lock - Path to the directory indicating we have the script lock
  # NOTE: This lock implementation is extremely simple but should be reliable
  #       across all platforms. It does *not* support locking a script with
  #       symlinks or multiple hardlinks as there's no portable way of doing so.
  #       If the lock was acquired it's automatically released in _safeExit_()

  local lock_dir
  if [[ ${1-} == 'system' ]]; then
    lock_dir="${TMPDIR:-/tmp/}$(basename "$0").lock"
  else
    lock_dir="${TMPDIR:-/tmp/}$(basename "$0").$UID.lock"
  fi

  if command mkdir "${lock_dir}" 2>/dev/null; then
    readonly script_lock="${lock_dir}"
    verbose "Acquired script lock: ${tan}${script_lock}${purple}"
  else
    error "Unable to acquire script lock: ${tan}${lock_dir}${red}"
    fatal "If you trust the script isn't running, delete the lock dir"
  fi
}

_execute_() {
  # DESC: Executes commands with safety and logging options
  # ARGS:  $1 (Required) - The command to be executed.  Quotation marks MUST be escaped.
  #        $2 (Optional) - String to display after command is executed
  # OPTS:  -v    Always print verbose output from the execute function
  #        -p    Pass a failed command with 'return 0'.  This effecively bypasses set -e.
  #        -e    Bypass _alert_ functions and use 'echo RESULT'
  #        -s    Use '_alert_ success' for successful output. (default is 'info')
  #        -q    Do not print output (quiet mode)
  # OUTS:  None
  # USE :  _execute_ "cp -R \"~/dir/somefile.txt\" \"someNewFile.txt\"" "Optional message"
  # NOTE:
  #        If $dryrun=true no commands are executed
  #        If $verbose=true the command's native output is printed to stderr and stdin

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

  local saveVerbose=$verbose
  if "${localVerbose}"; then
    verbose=true
  fi

  if "${dryrun}"; then
    if "$quietResult"; then
      verbose=$saveVerbose
      return 0
    fi
    if [ -n "${2-}" ]; then
      dryrun "${1} (${2})" "$(caller)"
    else
      dryrun "${1}" "$(caller)"
    fi
  elif ${verbose}; then
    if eval "${cmd}"; then
      if "$echoResult"; then
        echo "${message}"
      elif "${successResult}"; then
        success "${message}"
      else
        info "${message}"
      fi
      verbose=$saveVerbose
      return 0
    else
      if "$echoResult"; then
        echo "warning: ${message}"
      else
        warning "${message}"
      fi
      verbose=$saveVerbose
      "${passFailures}" && return 0 || return 1
    fi
  else
    if eval "${cmd}" &>/dev/null; then
      if "$quietResult"; then
        verbose=$saveVerbose
        return 0
      elif "$echoResult"; then
        echo "${message}"
      elif "${successResult}"; then
        success "${message}"
      else
        info "${message}"
      fi
      verbose=$saveVerbose
      return 0
    else
      if "$echoResult"; then
        echo "error: ${message}"
      else
        warning "${message}"
      fi
      verbose=$saveVerbose
      "${passFailures}" && return 0 || return 1
    fi
  fi
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
      -u | --username)
        shift
        username=${1}
        ;;
      -p | --password)
        shift
        echo "Enter Pass: "
        stty -echo
        read -r PASS
        stty echo
        echo
        ;;
      -l | --loglevel)
        shift
        LOGLEVEL=${1}
        ;;
      -n | --dryrun) dryrun=true ;;
      -v | --verbose) verbose=true ;;
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

# Initialize and run the script
trap '_trapCleanup_ $LINENO $BASH_LINENO "$BASH_COMMAND" "${FUNCNAME[*]}" "$0" "${BASH_SOURCE[0]}"' \
  EXIT INT TERM SIGINT SIGQUIT
set -o errtrace                           # Trap errors in subshells and functions
set -o errexit                            # Exit on error. Append '||true' if you expect an error
set -o pipefail                           # Use last non-zero exit code in a pipeline
# shopt -s nullglob globstar              # Make `for f in *.txt` work when `*.txt` matches zero files
IFS=$' \n\t'                              # Set IFS to preferred implementation
# set -o xtrace                           # Run in debug mode
set -o nounset                            # Disallow expansion of unset variables
# [[ $# -eq 0 ]] && _parseOptions_ "-h"   # Force arguments when invoking the script
_parseOptions_ "$@"                       # Parse arguments passed to script
# _makeTempDir_ "$(basename "$0")"        # Create a temp directory '$tmpDir'
# _acquireScriptLock_                     # Acquire script lock
_mainScript_                              # Run script
_safeExit_                                # Exit cleanly