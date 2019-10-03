### VARIABLES ###

now=$(LC_ALL=C date +"%m-%d-%Y %r")                   # Returns: 06-14-2015 10:34:40 PM
datestamp=$(LC_ALL=C date +%Y-%m-%d)                  # Returns: 2015-06-14
hourstamp=$(LC_ALL=C date +%r)                        # Returns: 10:34:40 PM
timestamp=$(LC_ALL=C date +%Y%m%d_%H%M%S)             # Returns: 20150614_223440
today=$(LC_ALL=C date +"%m-%d-%Y")                    # Returns: 06-14-2015
longdate=$(LC_ALL=C date +"%a, %d %b %Y %H:%M:%S %z") # Returns: Sun, 10 Jan 2016 20:47:53 -0500
gmtdate=$(LC_ALL=C date -u -R | sed 's/\+0000/GMT/')  # Returns: Wed, 13 Jan 2016 15:55:29 GMT

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

_alert_() {
  # DESC:   Controls all printing of messages to log files and stdout.
  # ARGS:   $1 (required) - The type of alert to print
  #                         (success, header, notice, dryrun, verbose, debug, warning, error,
  #                         fatal, info, die, input)
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

  [ -z ${scriptName-} ] && scriptName="$(basename "$0")"

  if [ -z "${logFile-}" ]; then
    readonly logLocation="${HOME}/logs"
    readonly logName="${scriptName%.sh}.log"
    [ ! -d "$logLocation" ] && mkdir -p "$logLocation"
    logFile="${logLocation}/${logName}"
  fi

  if [ -z "$line" ]; then
    [[ "$1" =~ ^(fatal|error|debug|warning) && "${FUNCNAME[2]}" != "_trapCleanup_" ]] \
      && message="$message $(_functionStack_)"
  else
    [[ "$1" =~ ^(fatal|error|debug) && "${FUNCNAME[2]}" != "_trapCleanup_" ]] \
      && message="$message (line: $line) $(_functionStack_)"
  fi

  if [ -n "$line" ]; then
    [[ "$1" =~ ^(warning|info|notice|dryrun) && "${FUNCNAME[2]}" != "_trapCleanup_" ]] \
      && message="$message (line: $line)"
  fi

  if [[ "${TERM}" != "xterm"* ]] || [ -t 1 ]; then
    # Don't use colors on pipes or non-recognized terminals regardles of alert type
    color=""
    reset=""
  elif [[ "${alertType}" =~ ^(error|fatal) ]]; then
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
    # Print to console when script is not 'quiet'
    ("$quiet") \
      && {
        tput cuu1
        return 0
      } # tput cuu1 moves cursor up one line

    echo -e "$(date +"%r") ${color}$(printf "[%7s]" "${alertType}") ${message}${reset}"
  }
  _writeToScreen_

  _writeToLog_() {
    [[ "$alertType" =~ ^(input|debug) ]] && return 0

    if [[ "${printLog}" == true ]] || [[ "${logErrors}" == "true" && "$alertType" =~ ^(error|fatal) ]]; then
      [[ ! -f "$logFile" ]] && touch "$logFile"
      # Don't use colors in logs
      if command -v gsed &>/dev/null; then
        local cleanmessage="$(echo "$message" | gsed -E 's/(\x1b)?\[(([0-9]{1,2})(;[0-9]{1,3}){0,2})?[mGK]//g')"
      else
        local cleanmessage="$(echo "$message" | sed -E 's/(\x1b)?\[(([0-9]{1,2})(;[0-9]{1,3}){0,2})?[mGK]//g')"
      fi
      echo -e "$(date +"%b %d %R:%S") $(printf "[%7s]" "${alertType}") ${cleanmessage}" >>"${logFile}"
    fi
  }
  _writeToLog_

} # /_alert_

error() { echo -e "$(_alert_ error "${1}" "${2-}")"; }
warning() { echo -e "$(_alert_ warning "${1}" "${2-}")"; }
notice() { echo -e "$(_alert_ notice "${1}" "${2-}")"; }
info() { echo -e "$(_alert_ info "${1}" "${2-}")"; }
success() { echo -e "$(_alert_ success "${1}" "${2-}")"; }
dryrun() { echo -e "$(_alert_ dryrun "${1}" "${2-}")"; }
input() { echo -n "$(_alert_ input "${1}" ${2-})"; }
header() { echo -e "$(_alert_ header "== ${1} ==" ${2-})"; }
die() { echo -e "$(_alert_ fatal "${1}" ${2-})"; _safeExit_ "1" ; }
fatal() { echo -e "$(_alert_ fatal "${1}" ${2-})"; _safeExit_ "1" ; }
debug() {
  ($verbose) \
    && {
      echo -e "$(_alert_ debug "${1}" "${2-}")"
    } \
    || return 0
}

verbose() {
  ($verbose) \
    && {
      echo -e "$(_alert_ debug "${1}" ${2-})"
    } \
    || return 0
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
    die "Unable to acquire script lock: ${tan}${lock_dir}${red}"
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

_checkBinary_() {
  # DESC:  Check if a binary exists in the search path
  # ARGS:   $1 (Required) - Name of the binary to check for existence
  # OUTS:   true/false
  # USAGE:  (_checkBinary_ ffmpeg ) && [SUCCESS] || [FAILURE]
  if [[ $# -lt 1 ]]; then
    error 'Missing required argument to _checkBinary_()!'
    return 1
  fi

  if ! command -v "$1" >/dev/null 2>&1; then
    verbose "Did not find dependency: '$1'"
    return 1
  fi
  return 0
}

_haveFunction_() {
  # DESC: Tests if a function exists.  Returns 0 if yes, 1 if no
  # ARGS:  $1 (Required) - Function name
  # OUTS:  true/false
  local f
  f="$1"

  if declare -f "$f" &>/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

_pauseScript_() {
  # DESC:  Pause a script at any point and continue after user input
  # ARGS:  $1 (Optional) - String for customized message
  # OUTS:  None

  local pauseMessage
  pauseMessage="${1:-Paused}. Ready to continue?"

  if _seekConfirmation_ "${pauseMessage}"; then
    info "Continuing..."
  else
    notice "Exiting Script"
    _safeExit_
  fi
}

_progressBar_() {
  # DESC:  Prints a progress bar within a for/while loop.
  # ARGS:  $1 (Required) - The total number of items counted
  #        $2 (Optional) - The optional title of the progress bar
  # OUTS:  None
  # USAGE:
  #   for number in $(seq 0 100); do
  #     sleep 1
  #     _progressBar_ "100" "Counting numbers"
  #   done

  ($quiet) && return
  ($verbose) && return
  [ ! -t 1 ] && return  # Do nothing if the output is not a terminal
  [ $1 == 1 ] && return # Do nothing with a single element

  local width bar_char perc num bar progressBarLine barTitle n

  n="${1:?_progressBar_ needs input}"
  ((n = n - 1))
  barTitle="${2:-Running Process}"
  width=30
  bar_char="#"

  # Reset the count
  [ -z "${progressBarProgress}" ] && progressBarProgress=0
  tput civis # Hide the cursor
  trap 'tput cnorm; exit 1' SIGINT

  if [ ! "${progressBarProgress}" -eq $n ]; then
    #echo "progressBarProgress: $progressBarProgress"
    # Compute the percentage.
    perc=$((progressBarProgress * 100 / $1))
    # Compute the number of blocks to represent the percentage.
    num=$((progressBarProgress * width / $1))
    # Create the progress bar string.
    bar=""
    if [ ${num} -gt 0 ]; then
      bar=$(printf "%0.s${bar_char}" $(seq 1 ${num}))
    fi
    # Print the progress bar.
    progressBarLine=$(printf "%s [%-${width}s] (%d%%)" "  ${barTitle}" "${bar}" "${perc}")
    echo -ne "${progressBarLine}\r"
    progressBarProgress=$((progressBarProgress + 1))
  else
    # Clear the progress bar when complete
    # echo -ne "\033[0K\r"
    tput el # Clear the line

    unset progressBarProgress
  fi

  tput cnorm
}

_safeExit_() {
  # DESC: Cleanup and exit from a script
  # ARGS: $1 (optional) - Exit code (defaults to 0)
  # OUTS: None

  if [[ -d ${script_lock-} ]]; then
    if command rm -rf "${script_lock}"; then
      verbose "Removing script lock"
    else
      warning "Script lock could not be removed. Try manually deleting ${tan}${lock_dir}${red}"
    fi
  fi

  if [[ -n "${tmpDir-}" && -d "${tmpDir-}" ]]; then
    if [[ ${1-} == 1 && -n "$(ls "${tmpDir}")" ]]; then
      if _seekConfirmation_ "Save the temp directory for debugging?"; then
        cp -r "${tmpDir}" "${tmpDir}.save"
        notice "'${tmpDir}.save' created"
      fi
      rm -r "${tmpDir}"
    else
      rm -r "${tmpDir}"
      verbose "Removing temp directory"
    fi
  fi

  trap - INT TERM EXIT
  exit ${1:-0}
}

_seekConfirmation_() {
  # DESC:  Seek user input for yes/no question
  # ARGS:   $1 (Optional) - Question being asked
  # OUTS:   true/false
  # USAGE:
  #   if _seekConfirmation_ "Answer this question"; then
  #     something
  #   fi

  input "${1-}"
  if "${force}"; then
    verbose "Forcing confirmation with '--force' flag set"
    echo -e ""
    return 0
  else
    while true; do
      read -r -p " (y/n) " yn
      case $yn in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        *) input "Please answer yes or no." ;;
      esac
    done
  fi
}

_setPATH_() {
  # DESC:   Add directories to $PATH so script can find executables
  # ARGS:   $@ - One or more paths
  # OUTS:   $PATH
  # USAGE:  _setPATH_ "/usr/local/bin" "${HOME}/bin" "$(npm bin)"
  local NEWPATH NEWPATHS USERPATH

  for USERPATH in "$@"; do
    NEWPATHS+=("$USERPATH")
  done

  for NEWPATH in "${NEWPATHS[@]}"; do
    if ! echo "$PATH" | grep -Eq "(^|:)${NEWPATH}($|:)"; then
      PATH="${NEWPATH}:${PATH}"
      verbose "Added '${tan}${NEWPATH}${purple}' to PATH"
    fi
  done
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
