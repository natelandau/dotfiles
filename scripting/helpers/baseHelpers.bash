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
  reset=$(tput sgr0)
  purple=$(tput setaf 171)
  red=$(tput setaf 1)
  green=$(tput setaf 76)
  tan=$(tput setaf 3)
  blue=$(tput setaf 38)
  underline=$(tput sgr 0 1)
else
  bold=""
  reset="\033[m"
  purple="\033[1;31m"
  red="\033[0;31m"
  green="\033[1;32m"
  tan="\033[0;33m"
  blue="\033[0;34m"
  underline=""
fi

### ALERTS AND LOGGING ###

_alert_() {
  # v1.1.0

  local scriptName logLocation logName function_name color alertType line
  alertType="$1"
  line="${2}"

  scriptName=$(basename "$0")
  logLocation="${HOME}/logs"
  logName="${scriptName%.sh}.log"

  if [ -z "$logFile" ]; then
    [ ! -d "$logLocation" ] && mkdir -p "$logLocation"
    logFile="${logLocation}/${logName}"
  fi

  function_name="func: $(echo "$(
    IFS="<"
    echo "${FUNCNAME[*]:2}"
  )" | sed -E 's/</ < /g')"

  if [ -z "$line" ]; then
    [[ "$1" =~ ^(fatal|error|debug) && "${FUNCNAME[2]}" != "_trapCleanup_" ]] \
      && _message="$_message ($function_name)"
  else
    [[ "$1" =~ ^(fatal|error|debug) && "${FUNCNAME[2]}" != "_trapCleanup_" ]] \
      && _message="$_message (line: $line) ($function_name)"
  fi

  [ "${alertType}" = "error" ] && color="${bold}${red}"
  [ "${alertType}" = "fatal" ] && color="${bold}${red}"
  [ "${alertType}" = "warning" ] && color="${red}"
  [ "${alertType}" = "success" ] && color="${green}"
  [ "${alertType}" = "debug" ] && color="${purple}"
  [ "${alertType}" = "header" ] && color="${bold}${tan}"
  [ "${alertType}" = "input" ] && color="${bold}"
  [ "${alertType}" = "dryrun" ] && color="${blue}"
  [ "${alertType}" = "info" ] && color=""
  [ "${alertType}" = "notice" ] && color=""

  # Don't use colors on pipes or non-recognized terminals
  if [[ "${TERM}" != "xterm"* ]] || [ -t 1 ]; then
    color=""
    reset=""
  fi

  # Print to console when script is not 'quiet'
  _writeToScreen_() {
    ("$quiet") \
      && {
        tput cuu1
        return
      } # tput cuu1 moves cursor up one line

    echo -e "$(date +"%r") ${color}$(printf "[%7s]" "${1}") ${_message}${reset}"
  }
  _writeToScreen_ "$1"

  # Print to Logfile
  if "${printLog}"; then
    [[ "$alertType" =~ ^(input|dryrun|debug) ]] && return
    [ ! -f "$logFile" ] && touch "$logFile"
    color=""
    reset="" # Don't use colors in logs
    echo -e "$(date +"%b %d %R:%S") $(printf "[%7s]" "${1}") ${_message}" >>"${logFile}"
  elif [[ "${logErrors}" == "true" && "$alertType" =~ ^(error|fatal) ]]; then
    [ ! -f "$logFile" ] && touch "$logFile"
    color=""
    reset="" # Don't use colors in logs
    echo -e "$(date +"%b %d %R:%S") $(printf "[%7s]" "${1}") ${_message}" >>"${logFile}"
  else
    return 0
  fi
}
die() {
  local _message="${1}"
  echo -e "$(_alert_ fatal $2)"
  _safeExit_ "1"
}
fatal() {
  local _message="${1}"
  echo -e "$(_alert_ fatal $2)"
  _safeExit_ "1"
}
trapped() {
  local _message="${1}"
  echo -e "$(_alert_ trapped $2)"
  _safeExit_ "1"
}
error() {
  local _message="${1}"
  echo -e "$(_alert_ error $2)"
}
warning() {
  local _message="${1}"
  echo -e "$(_alert_ warning $2)"
}
notice() {
  local _message="${1}"
  echo -e "$(_alert_ notice $2)"
}
info() {
  local _message="${1}"
  echo -e "$(_alert_ info $2)"
}
debug() {
  local _message="${1}"
  echo -e "$(_alert_ debug $2)"
}
success() {
  local _message="${1}"
  echo -e "$(_alert_ success $2)"
}
dryrun() {
  local _message="${1}"
  echo -e "$(_alert_ dryrun $2)"
}
input() {
  local _message="${1}"
  echo -n "$(_alert_ input $2)"
}
header() {
  local _message="== ${*} ==  "
  echo -e "$(_alert_ header $2)"
}
verbose() {
  ($verbose) \
    && {
      local _message="${1}"
      echo -e "$(_alert_ debug $2)"
    } \
    || return 0
}

### FUNCTIONS ###

_execute_() {
  # v1.1.0
  # _execute_ - wrap an external command in '_execute_' to push native output to /dev/null
  #           and have control over the display of the results.  In "dryrun" mode these
  #           commands are not executed at all. In Verbose mode, the commands are executed
  #           with results printed to stderr and stdin
  #
  #           options:
  #             -v    Will always print verbose output from the execute function
  #             -p    Will pass a failed command with 'return 0'.  This effecively bypasses set -e.
  #
  # usage:
  #   _execute_ "cp -R \"~/dir/somefile.txt\" \"someNewFile.txt\"" "Optional message to print to user"

  local localVerbose=false
  local passFailures=false
  local opt

  local OPTIND=1
  while getopts ":vVpP" opt; do
    case $opt in
      v | V) localVerbose=true ;;
      p | P) passFailures=true ;;
      *) {
        error "Unrecognized option '$1' passed to _execute. Exiting."
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
    if [ -n "$2" ]; then
      dryrun "${1} (${2})" }
    else
      dryrun "${1}"
    fi
  elif ${verbose}; then
    if eval "${cmd}"; then
      success "${message}"
      verbose=$saveVerbose
      return 0
    else
      warning "${message}"
      verbose=$saveVerbose
      "${passFailures}" && return 0 || return 1
    fi
  else
    if eval "${cmd}" &>/dev/null; then
      success "${message}"
      verbose=$saveVerbose
      return 0
    else
      warning "${message}"
      verbose=$saveVerbose
      "${passFailures}" && return 0 || return 1
    fi
  fi
}

_executeStrict_() {
  # v1.0.2
  # _execute_ - wrap an external command in '_execute_' to push native output to /dev/null
  #           and have control over the display of the results.  In "dryrun" mode these
  #           commands are not executed at all. In Verbose mode, the commands are executed
  #           with results printed to stderr and stdin
  #
  # usage:
  #   _execute_ "cp -R \"~/dir/somefile.txt\" \"someNewFile.txt\"" "Optional message to print to user"
  local cmd="${1:?_execute_ needs a command}"
  local message="${2:-$1}"
  local save="$-"
  local resetSetAdd
  local resetSetRemove

  save="$(echo "$save" | sed -E 's/(i|s)//g')"

  if [[ $save =~ e ]]; then
    resetSetAdd="e"
  else
    resetSetRemove="e"
  fi
  if [[ $save =~ E ]]; then
    resetSetAdd="${resetSetAdd}E"
  else
    resetSetRemove="${resetSetRemove}E"
  fi

  set -Ee
  if ${dryrun}; then
    dryrun "${message}"
  else
    eval "$cmd"
    if [ $? -eq 0 ]; then
      success "${message}"
      set -$resetSetAdd
      set +$resetSetRemove
      return 0
    else
      fatal "${message}" "$LINENO"
    fi
  fi
}

_findBaseDir_() {
  #v1.0.0
  # fincBaseDir locates the real directory of the script being run. similar to GNU readlink -n
  # usage :  baseDir="$(_findBaseDir_)"
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

_haveFunction_() {
  # v1.0.0
  # Tests if a function exists.  Returns 0 if yes, 1 if no
  # usage: _haveFunction "_someFunction_"
  local f
  f="$1"

  if declare -f "$f" &>/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

_pauseScript_() {
  # v1.0.0
  # A simple function used to pause a script at any point and
  # only continue on user input
  if _seekConfirmation_ "Ready to continue?"; then
    info "Continuing..."
  else
    notice "Exiting Script"
    _safeExit_
  fi
}

_progressBar_() {
  # v1.0.0
  # Prints a progress bar within a for/while loop.
  # To use this function you must pass the total number of
  # times the loop will run to the function.
  #
  # Takes two inputs:
  #   $1 - The total number of items counted
  #   $2 - The optional title of the progress bar
  #
  # usage:
  #   for number in $(seq 0 100); do
  #     sleep 1
  #     _progressBar_ "100" "Counting numbers"
  #   done
  # -----------------------------------

  ($quiet) && return
  ($verbose) && return
  [ ! -t 1 ] && return # Do nothing if the output is not a terminal

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
  # Delete temp files with option to save if error is trapped
  # To exit the script with a non-zero exit code pass the requested code
  # to this function as an argument
  #
  #   Usage:    _safeExit_ "1"
  if [[ -n "${tmpDir}" && -d "${tmpDir}" ]]; then
    if [[ $1 == 1 && -n "$(ls "${tmpDir}")" ]]; then
      if _seekConfirmation_ "Save the temp directory for debugging?"; then
        cp -r "${tmpDir}" "${tmpDir}.save"
        notice "'${tmpDir}.save' created"
      fi
      rm -r "${tmpDir}"
    else
      rm -r "${tmpDir}"
    fi
  fi

  trap - INT TERM EXIT
  exit ${1:-0}
}

_seekConfirmation_() {
  # v1.0.1
  # Seeks a Yes or No answer to a question.  Usage:
  #   if _seekConfirmation_ "Answer this question"; then
  #     something
  #   fi

  input "$@"
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
  # v2.0.0
  # _setPATH_() Add specified directories to $PATH so the script can find executables
  # Usage:  _setPATH_ "/usr/local/bin" "${HOME}/bin" "$(npm bin)"
  local NEWPATH NEWPATHS USERPATH

  for USERPATH in "$@"; do
    NEWPATHS+=("$USERPATH")
  done

  for NEWPATH in "${NEWPATHS[@]}"; do
    if ! echo "$PATH" | grep -Eq "(^|:)${NEWPATH}($|:)"; then
      PATH="${NEWPATH}:${PATH}"
    fi
  done
}

_trapCleanup_() {
  local line=$1 # LINENO
  local linecallfunc=$2
  local command="$3"
  local funcstack="$4"
  local script="$5"
  local sourced="$6"
  local scriptSpecific="$7"

  funcstack="'$(echo "$funcstack" | sed -E 's/ / < /g')'"

  #fatal "line $line - command '$command' $func"
  if [[ "${script##*/}" == "${sourced##*/}" ]]; then
    fatal "${7} command: '$command' (line: $line) (func: ${funcstack})"
  else
    fatal "${7} command: '$command' (func: ${funcstack} called at line $linecallfunc of '${script##*/}') (line: $line of '${sourced##*/}') "
  fi

  _safeExit_ "1"
}
