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

  local color
  local alertType="${1}"
  local message="${2}"


  if [[ "${alertType}" =~ ^(error|fatal) ]]; then
    color="${BOLD}${RED}"
  elif [ "${alertType}" = "warning" ]; then
    color="${RED}"
  elif [ "${alertType}" = "success" ]; then
    color="${GREEN}"
  elif [ "${alertType}" = "debug" ]; then
    color="${PURPLE}"
  elif [ "${alertType}" = "header" ]; then
    color="${BOLD}${TAN}"
  elif [[ "${alertType}" =~ ^(input|notice) ]]; then
    color="${BOLD}"
  elif [ "${alertType}" = "dryrun" ]; then
    color="${BLUE}"
  else
    color=""
  fi

  _writeToScreen_() {

    if ! [[ -t 1 ]]; then  # Don't use colors on non-recognized terminals
      color=""
      reset=""
    fi

    echo -e "$(date +"%r") ${color}$(printf "[%7s]" "${alertType}") ${message}${reset}"
  }
  _writeToScreen_


} # /_alert_

error() { _alert_ error "${1}" "${2-}"; }
warning() { _alert_ warning "${1}" "${2-}"; }
notice() { _alert_ notice "${1}" "${2-}"; }
info() { _alert_ info "${1}" "${2-}"; }
success() { _alert_ success "${1}" "${2-}"; }
dryrun() { _alert_ dryrun "${1}" "${2-}"; }
input() { _alert_ input "${1}" "${2-}"; }
header() { _alert_ header "== ${1} ==" "${2-}"; }
die() { _alert_ fatal "${1}" "${2-}" ; }
fatal() { _alert_ fatal "${1}" "${2-}"; }
debug() { _alert_ debug "${1}" "${2-}"; }
verbose() { _alert_ debug "${1}" "${2-}"; }
