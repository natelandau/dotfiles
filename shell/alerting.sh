_alert_() {
    # DESC:   Controls all printing of messages to stdout.
    # ARGS:   $1 (required) - The type of alert to print
    #                         (success, header, notice, dryrun, debug, warning, error,
    #                         fatal, info, input)
    #         $2 (required) - The message to be printed to stdout
    # OUTS:   None
    # USAGE:  [ALERTTYPE] "[MESSAGE]"

    local function_name color
    local alertType="${1}"
    local message="${2}"

    if [[ ${alertType} =~ ^(error|fatal) ]]; then
        color="${bold}${red}"
    elif [ "${alertType}" == "info" ]; then
        color="${gray}"
    elif [ "${alertType}" == "warning" ]; then
        color="${red}"
    elif [ "${alertType}" == "success" ]; then
        color="${green}"
    elif [ "${alertType}" == "debug" ]; then
        color="${purple}"
    elif [ "${alertType}" == "header" ]; then
        color="${bold}${tan}"
    elif [ ${alertType} == "notice" ]; then
        color="${bold}"
    elif [ ${alertType} == "input"  ]; then
        color="${bold}${underline}"
    elif [ "${alertType}" = "dryrun" ]; then
        color="${blue}"
    else
        color=""
    fi

    _writeToScreen_() {

        if ! [[ -t 1 ]]; then # Don't use colors on non-recognized terminals
            color=""
            reset=""
        fi

        echo -e "$(date +"%r") ${color}$(printf "[%7s]" "${alertType}") ${message}${reset}"
    }
    _writeToScreen_

} # /_alert_

error() { _alert_ error "${1}" "${2:-}"; }
warning() { _alert_ warning "${1}" "${2:-}"; }
notice() { _alert_ notice "${1}" "${2:-}"; }
info() { _alert_ info "${1}" "${2:-}"; }
success() { _alert_ success "${1}" "${2:-}"; }
dryrun() { _alert_ dryrun "${1}" "${2:-}"; }
input() { _alert_ input "${1}" "${2:-}"; }
header() { _alert_ header "${reverse}${1}" "${2:-}"; }
die() { _alert_ fatal "${1}" "${2:-}"; }
fatal() { _alert_ fatal "${1}" "${2:-}"; }
debug() { _alert_ debug "${1}" "${2:-}"; }
