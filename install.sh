#!/usr/bin/env bash

_mainScript_() {

    _setPATH_ "/usr/local/bin"

    i=0
    while read -r f; do
        _makeSymlink_ -c "${f}" "${USER_HOME}/$(basename "${f}")"
        ((i = i + 1))
    done < <(find "$(_findBaseDir_)" -maxdepth 1 \
        -iregex '^/.*/\..*$' \
        -not -name '.vscode' \
        -not -name '.git' \
        -not -name '.DS_Store' \
        -not -name '.yamllint.yml' \
        -not -name '.ansible-lint.yml' \
        -not -name '.hooks')
    notice "Confirmed ${i} symlinks"

    REPOS=(
        "\"git@github.com:scopatz/nanorc\" \"${HOME}/.nano/\""
    )

    i=0
    for r in "${REPOS[@]}"; do
        ((i = i + 1))
        REPO_DIR="$(echo "${r}" | awk 'BEGIN { FS = "\"" } ; { print $4 }')"
        if [ -d "${REPO_DIR}" ]; then
            debug "${REPO_DIR} already exists"
        else
            _execute_ -s "git clone ${r}"
        fi
    done
    notice "Confirmed ${i} repositories"

}
  # end _mainScript_

# ################################## Flags and defaults
  # Script specific
    USER_HOME="${HOME}"
  # Common
    LOGFILE="${HOME}/logs/$(basename "$0").log"
    QUIET=false
    LOGLEVEL=ERROR
    VERBOSE=false
    FORCE=false
    DRYRUN=false
    declare -a ARGS=()
    NOW=$(LC_ALL=C date +"%m-%d-%Y %r")                   # Returns: 06-14-2015 10:34:40 PM
    DATESTAMP=$(LC_ALL=C date +%Y-%m-%d)                  # Returns: 2015-06-14
    HOURSTAMP=$(LC_ALL=C date +%r)                        # Returns: 10:34:40 PM
    TIMESTAMP=$(LC_ALL=C date +%Y%m%d_%H%M%S)             # Returns: 20150614_223440
    LONGDATE=$(LC_ALL=C date +"%a, %d %b %Y %H:%M:%S %z") # Returns: Sun, 10 Jan 2016 20:47:53 -0500
    GMTDATE=$(LC_ALL=C date -u -R | sed 's/\+0000/GMT/')  # Returns: Wed, 13 Jan 2016 15:55:29 GMT

# ################################## Custom utility functions
_execute_() {
    # DESC: Executes commands with safety and logging options
    # ARGS:  $1 (Required) - The command to be executed.  Quotation marks MUST be escaped.
    #        $2 (Optional) - String to display after command is executed
    # OPTS:  -v    Always print debug output from the execute function
    #        -p    Pass a failed command with 'return 0'.  This effectively bypasses set -e.
    #        -e    Bypass _alert_ functions and use 'echo RESULT'
    #        -s    Use '_alert_ success' for successful output. (default is 'info')
    #        -q    Do not print output (QUIET mode)
    # OUTS:  None
    # USE :  _execute_ "cp -R \"~/dir/somefile.txt\" \"someNewFile.txt\"" "Optional message"
    #        _execute_ -sv "mkdir \"some/dir\""
    # NOTE:
    #         If $DRYRUN=true no commands are executed
    #         If $VERBOSE=true the command's native output is printed to
    #         stderr and stdin. This can be forced with `_execute_ -v`

    local LOCAL_VERBOSE=false
    local PASS_FAILURES=false
    local ECHO_RESULT=false
    local SUCCESS_RESULT=false
    local QUIET_RESULT=false
    local opt

    local OPTIND=1
    while getopts ":vVpPeEsSqQ" opt; do
        case $opt in
            v | V) LOCAL_VERBOSE=true ;;
            p | P) PASS_FAILURES=true ;;
            e | E) ECHO_RESULT=true ;;
            s | S) SUCCESS_RESULT=true ;;
            q | Q) QUIET_RESULT=true ;;
            *)
                {
                    error "Unrecognized option '$1' passed to _execute_. Exiting."
                    _safeExit_
                }
                ;;
        esac
    done
    shift $((OPTIND - 1))

    local CMD="${1:?_execute_ needs a command}"
    local EXECUTE_MESSAGE="${2:-$1}"

    local SAVE_VERBOSE=${VERBOSE}
    if "${LOCAL_VERBOSE}"; then
        VERBOSE=true
    fi

    if "${DRYRUN}"; then
        if "${QUIET_RESULT}"; then
            VERBOSE=$SAVE_VERBOSE
            return 0
        fi
        if [ -n "${2:-}" ]; then
            dryrun "${1} (${2})" "$(caller)"
        else
            dryrun "${1}" "$(caller)"
        fi
    elif ${VERBOSE}; then
        if eval "${CMD}"; then
            if "${ECHO_RESULT}"; then
                echo "${EXECUTE_MESSAGE}"
            elif "${SUCCESS_RESULT}"; then
                success "${EXECUTE_MESSAGE}"
            else
                info "${EXECUTE_MESSAGE}"
            fi
            VERBOSE=${SAVE_VERBOSE}
            return 0
        else
            if "${ECHO_RESULT}"; then
                echo "warning: ${EXECUTE_MESSAGE}"
            else
                warning "${EXECUTE_MESSAGE}"
            fi
            VERBOSE=${SAVE_VERBOSE}
            "${PASS_FAILURES}" && return 0 || return 1
        fi
    else
        if eval "${CMD}" &>/dev/null; then
            if "${QUIET_RESULT}"; then
                VERBOSE=${SAVE_VERBOSE}
                return 0
            elif "${ECHO_RESULT}"; then
                echo "${EXECUTE_MESSAGE}"
            elif "${SUCCESS_RESULT}"; then
                success "${EXECUTE_MESSAGE}"
            else
                info "${EXECUTE_MESSAGE}"
            fi
            VERBOSE=${SAVE_VERBOSE}
            return 0
        else
            if "${ECHO_RESULT}"; then
                echo "error: ${EXECUTE_MESSAGE}"
            else
                warning "${EXECUTE_MESSAGE}"
            fi
            VERBOSE=${SAVE_VERBOSE}
            "${PASS_FAILURES}" && return 0 || return 1
        fi
    fi
}

_findBaseDir_() {
    # DESC: Locates the real directory of the script being run. Similar to GNU readlink -n
    # ARGS:  None
    # OUTS:  Echo result to STDOUT
    # USE :  baseDir="$(_findBaseDir_)"
    #        cp "$(_findBaseDir_ "somefile.txt")" "other_file.txt"

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
            debug "Added '${tan}${NEWPATH}${purple}' to PATH"
        fi
    done
}

_uniqueFileName_() {
    # DESC:   Ensure a file to be created has a unique filename to avoid overwriting other
    #         filenames by appending an integer to the filename if it already exists.
    # ARGS:   $1 (Required) - Name of file to be created
    #         $2 (Optional) - Separation characted (Defaults to a period '.')
    # OUTS:   Prints unique filename to STDOUT
    # OPTS:  -i             - Places the unique integer before the file extension
    # USAGE:  _uniqueFileName_ "/some/dir/file.txt" "-"

    local opt
    local OPTIND=1
    local INTERNAL_INTEGER=false
    while getopts ":iI" opt; do
        case ${opt} in
            i | I) INTERNAL_INTEGER=true ;;
            *)
                {
                    error "Unrecognized option '${1}' passed to _uniqueFileName_" "${LINENO}"
                    return 1
                }
                ;;
        esac
    done
    shift $((OPTIND - 1))

    local fullfile="${1:?_uniqueFileName_ needs a file}"
    local spacer="${2:-.}"
    local directory
    local filename
    local extension
    local newfile
    local num

    if ! command -v realpath >/dev/null 2>&1; then
        error "We must have 'realpath' installed and available in \$PATH to run."
        if [[ $OSTYPE == "darwin"* ]]; then
            notice "Install coreutils using homebrew and rerun this script."
            info "\t$ brew install coreutils"
        fi
        _safeExit_ 1
    fi

    # Find directories with realpath if input is an actual file
    if [ -e "${fullfile}" ]; then
        fullfile="$(realpath "${fullfile}")"
    fi

    directory="$(dirname "${fullfile}")"
    filename="$(basename "${fullfile}")"

    # Extract extensions only when they exist
    if [[ "${filename}" =~ \.[a-zA-Z]{2,4}$ ]]; then
        extension=".${filename##*.}"
        filename="${filename%.*}"
    fi
    if [[ "${filename}" == "${extension:-}" ]]; then
        extension=""
    fi

    newfile="${directory}/${filename}${extension:-}"

    if [ -e "${newfile}" ]; then
        num=1
        if [ "${INTERNAL_INTEGER}" = true ]; then
            while [[ -e "${directory}/${filename}${spacer}${num}${extension:-}" ]]; do
                ((num++))
            done
            newfile="${directory}/${filename}${spacer}${num}${extension:-}"
        else
            while [[ -e "${directory}/${filename}${extension:-}${spacer}${num}" ]]; do
                ((num++))
            done
            newfile="${directory}/${filename}${extension:-}${spacer}${num}"
        fi
    fi

    echo "${newfile}"
    return 0
}

_backupFile_() {
    # DESC:   Creates a backup of a specified file with .bak extension or
    #         optionally to a specified directory
    # ARGS:   $1 (Required)   - Source file
    #         $2 (Optional)   - Destination dir name used only with -d flag (defaults to ./backup)
    # OPTS:   -d              - Move files to a backup direcory
    #         -m              - Replaces copy (default) with move, effectively removing
    #                           the original file
    # OUTS:   None
    # USAGE:  _backupFile_ "sourcefile.txt" "some/backup/dir"
    # NOTE:   dotfiles have their leading '.' removed in their backup

    local opt
    local OPTIND=1
    local useDirectory=false
    local MOVE_FILE=false

    while getopts ":dDmM" opt; do
        case ${opt} in
            d | D) useDirectory=true ;;
            m | M) MOVE_FILE=true ;;
            *)
                {
                    error "Unrecognized option '${1}' passed to _backupFile_" "${LINENO}"
                    return 1
                }
                ;;
        esac
    done
    shift $((OPTIND - 1))

    [[ $# -lt 1 ]] && fatal 'Missing required argument to _backupFile_()!'

    local SOURCE_FILE="${1}"
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
    [ ! -e "${SOURCE_FILE}" ] \
        && {
            warning "Source '${SOURCE_FILE}' not found"
            return 1
        }

    if [ ${useDirectory} == true ]; then

        [ ! -d "${d}" ] \
            && _execute_ "mkdir -p \"${d}\"" "Creating backup directory"

        if [ -e "${SOURCE_FILE}" ]; then
            n="$(_uniqueFileName_ "${d}/${SOURCE_FILE#.}")"
            if [ ${MOVE_FILE} == true ]; then
                _execute_ "mv \"${SOURCE_FILE}\" \"${d}/${n##*/}\"" "Moving: '${SOURCE_FILE}' to '${d}/${n##*/}'"
            else
                _execute_ "cp -R \"${SOURCE_FILE}\" \"${d}/${n##*/}\"" "Backing up: '${SOURCE_FILE}' to '${d}/${n##*/}'"
            fi
        fi
    else
        n="$(_uniqueFileName_ "${SOURCE_FILE}.bak")"
        if [ ${MOVE_FILE} == true ]; then
            _execute_ "mv \"${SOURCE_FILE}\" \"${n}\"" "Moving '${SOURCE_FILE}' to '${n}'"
        else
            _execute_ "cp -R \"${SOURCE_FILE}\" \"${n}\"" "Backing up '${SOURCE_FILE}' to '${n}'"
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
    # OPTS:   -c             - Only report on new/changed symlinks.  Quiet when nothing done.
    #         -n             - Do not create a backup if target already exists
    #         -s             - Use sudo when removing old files to make way for new symlinks
    # OUTS:   None
    # USAGE:  _makeSymlink_ "/dir/someExistingFile" "/dir/aNewSymLink" "/dir/backup/location"
    # NOTE:   This function makes use of the _execute_ function

    local opt
    local OPTIND=1
    local backupOriginal=true
    local useSudo=false
    local ONLY_SHOW_CHANGED=false

    while getopts ":cCnNsS" opt; do
        case $opt in
            n | N) backupOriginal=false ;;
            s | S) useSudo=true ;;
            c | C) ONLY_SHOW_CHANGED=true ;;
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
        if [[ $OSTYPE == "darwin"* ]]; then
            notice "Install coreutils using homebrew and rerun this script."
            info "\t$ brew install coreutils"
        fi
        _safeExit_ 1
    fi

    [[ $# -lt 2 ]] && fatal 'Missing required argument to _makeSymlink_()!'

    local s="$1"
    local d="$2"
    local b="${3:-}"
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

        [[ ${o} == "${s}" ]] && {

            if [ ${ONLY_SHOW_CHANGED} == true ]; then
                debug "Symlink already exists: ${s} → ${d}"
            elif [ "${DRYRUN}" == true ]; then
                dryrun "Symlink already exists: ${s} → ${d}"
            else
                info "Symlink already exists: ${s} → ${d}"
            fi
            return 0
        }

        if [[ ${backupOriginal} == true ]]; then
            _backupFile_ "${d}" "${b:-backup}"
        fi
        if [[ ${DRYRUN} == false ]]; then
            if [[ ${useSudo} == true ]]; then
                command rm -rf "${d}"
            else
                command rm -rf "${d}"
            fi
        fi
        _execute_ "ln -fs \"${s}\" \"${d}\"" "symlink ${s} → ${d}"
    elif [ -e "${d}" ]; then
        if [[ ${backupOriginal} == true ]]; then
            _backupFile_ "${d}" "${b:-backup}"
        fi
        if [[ ${DRYRUN} == false ]]; then
            if [[ ${useSudo} == true ]]; then
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
# ################################## Common Functions for script template
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
    #         $3 (optional) - Pass '${LINENO}' to print the line number where the _alert_ was triggered
    # OUTS:   None
    # USAGE:  [ALERTTYPE] "[MESSAGE]" "${LINENO}"
    # NOTES:  The colors of each alert type are set in this function
    #         For specified alert types, the funcstac will be printed

    local function_name color
    local alertType="${1}"
    local message="${2}"
    local line="${3:-}"  # Optional line number

    if [[ -n "${line}" && "${alertType}" =~ ^(fatal|error) && "${FUNCNAME[2]}" != "_trapCleanup_" ]]; then
        message="${message} (line: ${line}) $(_functionStack_)"
    elif [[ -n "${line}" && "${FUNCNAME[2]}" != "_trapCleanup_" ]]; then
        message="${message} (line: ${line})"
    elif [[ -z "${line}" && "${alertType}" =~ ^(fatal|error) && "${FUNCNAME[2]}" != "_trapCleanup_" ]]; then
        message="${message} $(_functionStack_)"
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

        ("${QUIET}") && return 0 # Print to console when script is not 'quiet'
        [[ ${VERBOSE} == false && "${alertType}" =~ ^(debug|verbose) ]] && return 0

        if ! [[ -t 1 ]]; then # Don't use colors on non-recognized terminals
            color=""
            reset=""
        fi

        echo -e "$(date +"%r") ${color}$(printf "[%7s]" "${alertType}") ${message}${reset}"
    }
    _writeToScreen_

    _writeToLog_() {
        [[ "${alertType}" == "input" ]] && return 0
        [[ "${LOGLEVEL}" =~ (off|OFF|Off) ]] && return 0
        [ -z "${LOGFILE:-}" ] && LOGFILE="$(pwd)/$(basename "$0").log"
        [ ! -d "$(dirname "${LOGFILE}")" ] && command mkdir -p "$(dirname "${LOGFILE}")"
        [[ ! -f "${LOGFILE}" ]] && touch "${LOGFILE}"

        # Don't use colors in logs
        if command -v gsed &>/dev/null; then
            local cleanmessage="$(echo "${message}" | gsed -E 's/(\x1b)?\[(([0-9]{1,2})(;[0-9]{1,3}){0,2})?[mGK]//g')"
        else
            local cleanmessage="$(echo "${message}" | sed -E 's/(\x1b)?\[(([0-9]{1,2})(;[0-9]{1,3}){0,2})?[mGK]//g')"
        fi
        echo -e "$(date +"%b %d %R:%S") $(printf "[%7s]" "${alertType}") [$(/bin/hostname)] ${cleanmessage}" >>"${LOGFILE}"
    }

    # Write specified log level data to logfile
    case "${LOGLEVEL:-ERROR}" in
        ALL | all | All)
            _writeToLog_
            ;;
        DEBUG | debug | Debug)
            _writeToLog_
            ;;
        INFO | info | Info)
            if [[ "${alertType}" =~ ^(die|error|fatal|warning|info|notice|success) ]]; then
                _writeToLog_
            fi
            ;;
        WARN | warn | Warn)
            if [[ "${alertType}" =~ ^(die|error|fatal|warning) ]]; then
                _writeToLog_
            fi
            ;;
        ERROR | error | Error)
            if [[ "${alertType}" =~ ^(die|error|fatal) ]]; then
                _writeToLog_
            fi
            ;;
        FATAL | fatal | Fatal)
            if [[ "${alertType}" =~ ^(die|fatal) ]]; then
                _writeToLog_
            fi
            ;;
        OFF | off)
            return 0
            ;;
        *)
            if [[ "${alertType}" =~ ^(die|error|fatal) ]]; then
                _writeToLog_
            fi
            ;;
    esac

} # /_alert_

error() { _alert_ error "${1}" "${2:-}"; }
warning() { _alert_ warning "${1}" "${2:-}"; }
notice() { _alert_ notice "${1}" "${2:-}"; }
info() { _alert_ info "${1}" "${2:-}"; }
success() { _alert_ success "${1}" "${2:-}"; }
dryrun() { _alert_ dryrun "${1}" "${2:-}"; }
input() { _alert_ input "${1}" "${2:-}"; }
header() { _alert_ header "== ${1} ==" "${2:-}"; }
die() {
    _alert_ fatal "${1}" "${2:-}"
    _safeExit_ "1"
}
fatal() {
    _alert_ fatal "${1}" "${2:-}"
    _safeExit_ "1"
}
debug() { _alert_ debug "${1}" "${2:-}"; }
verbose() { _alert_ debug "${1}" "${2:-}"; }

_safeExit_() {
    # DESC: Cleanup and exit from a script
    # ARGS: $1 (optional) - Exit code (defaults to 0)
    # OUTS: None

    if [[ -d "${SCRIPT_LOCK:-}" ]]; then
        if command rm -rf "${SCRIPT_LOCK}"; then
            debug "Removing script lock"
        else
            warning "Script lock could not be removed. Try manually deleting ${tan}'${LOCK_DIR}'${red}"
        fi
    fi

    if [[ -n "${TMP_DIR:-}" && -d "${TMP_DIR:-}" ]]; then
        if [[ ${1:-} == 1 && -n "$(ls "${TMP_DIR}")" ]]; then
            # Do something here to save TMP_DIR on a non-zero script exit for debugging
            command rm -r "${TMP_DIR}"
            debug "Removing temp directory"
        else
            command rm -r "${TMP_DIR}"
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

    local line=${1:-} # LINENO
    local linecallfunc=${2:-}
    local command="${3:-}"
    local funcstack="${4:-}"
    local script="${5:-}"
    local sourced="${6:-}"

    funcstack="'$(echo "$funcstack" | sed -E 's/ / < /g')'"

    if [[ "${script##*/}" == "${sourced##*/}" ]]; then
        fatal "${7:-} command: '${command}' (line: ${line}) [func: $(_functionStack_)]"
    else
        fatal "${7:-} command: '${command}' (func: ${funcstack} called at line ${linecallfunc} of '${script##*/}') (line: $line of '${sourced##*/}') "
    fi

    _safeExit_ "1"
}

_makeTempDir_() {
    # DESC:   Creates a temp directory to house temporary files
    # ARGS:   $1 (Optional) - First characters/word of directory name
    # OUTS:   $TMP_DIR       - Temporary directory
    # USAGE:  _makeTempDir_ "$(basename "$0")"

    [ -d "${TMP_DIR:-}" ] && return 0

    if [ -n "${1:-}" ]; then
        TMP_DIR="${TMPDIR:-/tmp/}${1}.$RANDOM.$RANDOM.$$"
    else
        TMP_DIR="${TMPDIR:-/tmp/}$(basename "$0").$RANDOM.$RANDOM.$RANDOM.$$"
    fi
    (umask 077 && mkdir "${TMP_DIR}") || {
        fatal "Could not create temporary directory! Exiting."
    }
    debug "\$TMP_DIR=${TMP_DIR}"
}

_acquireScriptLock_() {
    # DESC: Acquire script lock
    # ARGS: $1 (optional) - Scope of script execution lock (system or user)
    # OUTS: $SCRIPT_LOCK - Path to the directory indicating we have the script lock
    # NOTE: This lock implementation is extremely simple but should be reliable
    #       across all platforms. It does *not* support locking a script with
    #       symlinks or multiple hardlinks as there's no portable way of doing so.
    #       If the lock was acquired it's automatically released in _safeExit_()

    local LOCK_DIR
    if [[ ${1:-} == 'system' ]]; then
        LOCK_DIR="${TMPDIR:-/tmp/}$(basename "$0").lock"
    else
        LOCK_DIR="${TMPDIR:-/tmp/}$(basename "$0").$UID.lock"
    fi

    if command mkdir "${LOCK_DIR}" 2>/dev/null; then
        readonly SCRIPT_LOCK="${LOCK_DIR}"
        debug "Acquired script lock: ${tan}${SCRIPT_LOCK}${purple}"
    else
        error "Unable to acquire script lock: ${tan}${LOCK_DIR}${red}"
        fatal "If you trust the script isn't running, delete the lock dir"
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
        case "${FUNCNAME[$_i]}" in "_alert_" | "_trapCleanup_" | fatal | error | warning | notice | info | verbose | debug | dryrun | header | success | die) continue ;; esac
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
    set -- "${options[@]:-}"
    unset options

    # Read the options and set stuff
    while [[ ${1:-} == -?* ]]; do
        case $1 in
            # Custom options
            --user-home)
                shift
                USER_HOME="$1"
                ;;
            # Common options
            -h | --help)
                _usage_ >&2
                _safeExit_
                ;;
            --loglevel)
                shift
                LOGLEVEL=${1}
                ;;
            --logfile)
                shift
                LOGFILE="${1}"
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
    ARGS+=("$@") # Store the remaining user input as arguments.
}

_usage_() {
    cat <<EOF

  ${bold}$(basename "$0") [OPTION]...${reset}

  This script creates symlinks in the user's home directory to the dotfiles contained in this repository.  In addition, selected git repositories are cloned into the users home directory.

  Be sure to review the settings and information within this repository as well as the repos
  specified in _mainScript_() before running this script.

  ${bold}Options:${reset}
    --user-home             Set user home directory to symlink dotfiles to (Defaults to '~/')
    -h, --help              Display this help and exit
    --loglevel [LEVEL]      One of: FATAL, ERROR, WARN, INFO, DEBUG, ALL, OFF  (Default is 'ERROR')
    --logfile [FILE]        Full PATH to logfile.  (Default is '${HOME}/logs/$(basename "$0").log')
    -n, --dryrun            Non-destructive. Makes no permanent changes.
    -q, --quiet             Quiet (no output)
    -v, --verbose           Output more information. (Items echoed to 'verbose')
    --force                 Skip all user interaction.  Implied 'Yes' to all actions.

  ${bold}Example Usage:${reset}

      $ $(basename "$0") --user-home "/user/home/user1/"
EOF
}

# ################################## INITIALIZE AND RUN THE SCRIPT
#                                    (Comment or uncomment the lines below to customize script behavior)

trap '_trapCleanup_ ${LINENO} ${BASH_LINENO} "${BASH_COMMAND}" "${FUNCNAME[*]}" "${0}" "${BASH_SOURCE[0]}"' \
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
# _makeTempDir_ "$(basename "$0")"        # Create a temp directory '$TMP_DIR'
# _acquireScriptLock_                     # Acquire script lock
_mainScript_                              # Run the main logic script
_safeExit_                                # Exit cleanly
