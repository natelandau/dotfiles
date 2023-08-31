#!/usr/bin/env bash

_mainScript_() {

    LOGFILE="${HOME}/logs/$(basename "$(_findBaseDir_)")-$(basename "$0").log"
    _setPATH_ "/usr/local/bin" "/opt/homebrew/bin"

    REPOS=(
        "\"https://github.com/scopatz/nanorc.git\" \"${HOME}/.nano/\""
    )

    # Create symlinks
    makesymlink_args=("-c")
    if ${SKIP_BACKUP}; then
        makesymlink_args+=("-n")
    fi

    i=0
    while read -r f; do
        _makeSymlink_ "${makesymlink_args[@]}" "${f}" "${USER_HOME}/$(basename "${f}")"
        ((i = i + 1))
    done < <(find "$(_findBaseDir_)/dotfiles" -maxdepth 1 \
        -iregex '^/.*/\..*$' \
        -not -name '.DS_Store')
    notice "Symlinks confirmed: ${i}"

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
    notice "Repositories confirmed: ${i}"

}
# end _mainScript_

# ################################## Flags and defaults
# Required variables
LOGFILE="${HOME}/logs/$(basename "$0").log"
QUIET=false
LOGLEVEL=ERROR
VERBOSE=false
FORCE=false
DRYRUN=false
declare -a ARGS=()

# Script specific
USER_HOME="${HOME}"
SKIP_BACKUP=false

# ################################## Custom utility functions (Pasted from repository)
_execute_() {
    # DESC:
    #         Executes commands while respecting global DRYRUN, VERBOSE, LOGGING, and QUIET flags
    # ARGS:
    #         $1 (Required) - The command to be executed.  Quotation marks MUST be escaped.
    #         $2 (Optional) - String to display after command is executed
    # OPTS:
    #         -v    Always print output from the execute function to STDOUT
    #         -n    Use NOTICE level alerting (default is INFO)
    #         -p    Pass a failed command with 'return 0'.  This effectively bypasses set -e.
    #         -e    Bypass _alert_ functions and use 'printf RESULT'
    #         -s    Use '_alert_ success' for successful output. (default is 'info')
    #         -q    Do not print output (QUIET mode)
    # OUTS:
    #         stdout: Configurable output
    # USE :
    #         _execute_ "cp -R \"~/dir/somefile.txt\" \"someNewFile.txt\"" "Optional message"
    #         _execute_ -sv "mkdir \"some/dir\""
    # NOTE:
    #         If $DRYRUN=true, no commands are executed and the command that would have been executed
    #         is printed to STDOUT using dryrun level alerting
    #         If $VERBOSE=true, the command's native output is printed to stdout. This can be forced
    #         with '_execute_ -v'

    local _localVerbose=false
    local _passFailures=false
    local _echoResult=false
    local _echoSuccessResult=false
    local _quietMode=false
    local _echoNoticeResult=false
    local opt

    local OPTIND=1
    while getopts ":vVpPeEsSqQnN" opt; do
        case ${opt} in
            v | V) _localVerbose=true ;;
            p | P) _passFailures=true ;;
            e | E) _echoResult=true ;;
            s | S) _echoSuccessResult=true ;;
            q | Q) _quietMode=true ;;
            n | N) _echoNoticeResult=true ;;
            *)
                {
                    error "Unrecognized option '$1' passed to _execute_. Exiting."
                    _safeExit_
                }
                ;;
        esac
    done
    shift $((OPTIND - 1))

    [[ $# == 0 ]] && fatal "Missing required argument to ${FUNCNAME[0]}"

    local _command="${1}"
    local _executeMessage="${2:-$1}"

    local _saveVerbose=${VERBOSE}
    if "${_localVerbose}"; then
        VERBOSE=true
    fi

    if "${DRYRUN:-}"; then
        if "${_quietMode}"; then
            VERBOSE=${_saveVerbose}
            return 0
        fi
        if [ -n "${2:-}" ]; then
            dryrun "${1} (${2})" "$(caller)"
        else
            dryrun "${1}" "$(caller)"
        fi
    elif ${VERBOSE:-}; then
        if eval "${_command}"; then
            if "${_quietMode}"; then
                VERBOSE=${_saveVerbose}
            elif "${_echoResult}"; then
                printf "%s\n" "${_executeMessage}"
            elif "${_echoSuccessResult}"; then
                success "${_executeMessage}"
            elif "${_echoNoticeResult}"; then
                notice "${_executeMessage}"
            else
                info "${_executeMessage}"
            fi
        else
            if "${_quietMode}"; then
                VERBOSE=${_saveVerbose}
            elif "${_echoResult}"; then
                printf "%s\n" "warning: ${_executeMessage}"
            else
                warning "${_executeMessage}"
            fi
            VERBOSE=${_saveVerbose}
            "${_passFailures}" && return 0 || return 1
        fi
    else
        if eval "${_command}" >/dev/null 2>&1; then
            if "${_quietMode}"; then
                VERBOSE=${_saveVerbose}
            elif "${_echoResult}"; then
                printf "%s\n" "${_executeMessage}"
            elif "${_echoSuccessResult}"; then
                success "${_executeMessage}"
            elif "${_echoNoticeResult}"; then
                notice "${_executeMessage}"
            else
                info "${_executeMessage}"
            fi
        else
            if "${_quietMode}"; then
                VERBOSE=${_saveVerbose}
            elif "${_echoResult}"; then
                printf "%s\n" "error: ${_executeMessage}"
            else
                warning "${_executeMessage}"
            fi
            VERBOSE=${_saveVerbose}
            "${_passFailures}" && return 0 || return 1
        fi
    fi
    VERBOSE=${_saveVerbose}
    return 0
}

_findBaseDir_() {
    # DESC:
    #         Locates the real directory of the script being run. Similar to GNU readlink -n
    # ARGS:
    #         None
    # OUTS:
    #         stdout: prints result
    # USAGE:
    #         baseDir="$(_findBaseDir_)"
    #         cp "$(_findBaseDir_ "somefile.txt")" "other_file.txt"

    local _source
    local _dir

    # Is file sourced?
    if [[ ${_} != "${0}" ]]; then
        _source="${BASH_SOURCE[1]}"
    else
        _source="${BASH_SOURCE[0]}"
    fi

    while [ -h "${_source}" ]; do # Resolve $SOURCE until the file is no longer a symlink
        _dir="$(cd -P "$(dirname "${_source}")" && pwd)"
        _source="$(readlink "${_source}")"
        [[ ${_source} != /* ]] && _source="${_dir}/${_source}" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    printf "%s\n" "$(cd -P "$(dirname "${_source}")" && pwd)"
}

_backupFile_() {
    # DESC:
    #         Creates a backup of a specified file with .bak extension or optionally to a
    #         specified directory
    # ARGS:
    #         $1 (Required)   - Source file
    #         $2 (Optional)   - Destination dir name used only with -d flag (defaults to ./backup)
    # OPTS:
    #         -d  - Move files to a backup directory
    #         -m  - Replaces copy (default) with move, effectively removing the original file
    # REQUIRES:
    #         _execute_
    #         _createUniqueFilename_
    # OUTS:
    #         0 - Success
    #         1 - Error
    #         filesystem: Backup of files
    # USAGE:
    #         _backupFile_ "sourcefile.txt" "some/backup/dir"
    # NOTE:
    #         Dotfiles have their leading '.' removed in their backup

    local opt
    local OPTIND=1
    local _useDirectory=false
    local _moveFile=false

    while getopts ":dDmM" opt; do
        case ${opt} in
            d | D) _useDirectory=true ;;
            m | M) _moveFile=true ;;
            *)
                {
                    error "Unrecognized option '${1}' passed to _backupFile_" "${LINENO}"
                    return 1
                }
                ;;
        esac
    done
    shift $((OPTIND - 1))

    [[ $# == 0 ]] && fatal "Missing required argument to ${FUNCNAME[0]}"

    local _fileToBackup="${1}"
    local _backupDir="${2:-backup}"
    local _newFilename

    # Error handling
    declare -f _execute_ &>/dev/null || fatal "_backupFile_ needs function _execute_"
    declare -f _createUniqueFilename_ &>/dev/null || fatal "_backupFile_ needs function _createUniqueFilename_"

    [ ! -e "${_fileToBackup}" ] \
        && {
            debug "Source '${_fileToBackup}' not found"
            return 1
        }

    if [[ ${_useDirectory} == true ]]; then

        [ ! -d "${_backupDir}" ] \
            && _execute_ "mkdir -p \"${_backupDir}\"" "Creating backup directory"

        _newFilename="$(_createUniqueFilename_ "${_backupDir}/${_fileToBackup#.}")"
        if [[ ${_moveFile} == true ]]; then
            _execute_ "mv \"${_fileToBackup}\" \"${_backupDir}/${_newFilename##*/}\"" "Moving: '${_fileToBackup}' to '${_backupDir}/${_newFilename##*/}'"
        else
            _execute_ "cp -R \"${_fileToBackup}\" \"${_backupDir}/${_newFilename##*/}\"" "Backing up: '${_fileToBackup}' to '${_backupDir}/${_newFilename##*/}'"
        fi
    else
        _newFilename="$(_createUniqueFilename_ "${_fileToBackup}.bak")"
        if [[ ${_moveFile} == true ]]; then
            _execute_ "mv \"${_fileToBackup}\" \"${_newFilename}\"" "Moving '${_fileToBackup}' to '${_newFilename}'"
        else
            _execute_ "cp -R \"${_fileToBackup}\" \"${_newFilename}\"" "Backing up '${_fileToBackup}' to '${_newFilename}'"
        fi
    fi
}

_makeSymlink_() {
    # DESC:
    #         Creates a symlink and backs up a file which may be overwritten by the new symlink. If the
    #         exact same symlink already exists, nothing is done.
    #         Default behavior will create a backup of a file to be overwritten
    # ARGS:
    #         $1 (Required) - Source file
    #         $2 (Required) - Destination
    # OPTS:
    #         -c  - Only report on new/changed symlinks.  Quiet when nothing done.
    #         -n  - Do not create a backup if target already exists
    #         -s  - Use sudo when removing old files to make way for new symlinks
    # OUTS:
    #         0 - Success
    #         1 - Error
    #         Filesystem: Create's symlink if required
    # USAGE:
    #         _makeSymlink_ "/dir/someExistingFile" "/dir/aNewSymLink" "/dir/backup/location"

    local opt
    local OPTIND=1
    local _backupOriginal=true
    local _useSudo=false
    local _onlyShowChanged=false

    while getopts ":cCnNsS" opt; do
        case ${opt} in
            n | N) _backupOriginal=false ;;
            s | S) _useSudo=true ;;
            c | C) _onlyShowChanged=true ;;
            *) fatal "Missing required argument to ${FUNCNAME[0]}" ;;
        esac
    done
    shift $((OPTIND - 1))

    declare -f _execute_ &>/dev/null || fatal "${FUNCNAME[0]} needs function _execute_"
    declare -f _backupFile_ &>/dev/null || fatal "${FUNCNAME[0]} needs function _backupFile_"

    if ! command -v realpath >/dev/null 2>&1; then
        error "We must have 'realpath' installed and available in \$PATH to run."
        if [[ ${OSTYPE} == "darwin"* ]]; then
            notice "Install coreutils using homebrew and rerun this script."
            info "\t$ brew install coreutils"
        fi
        _safeExit_ 1
    fi

    [[ $# -lt 2 ]] && fatal "Missing required argument to ${FUNCNAME[0]}"

    local _sourceFile="$1"
    local _destinationFile="$2"
    local _originalFile

    # Fix files where $HOME is written as '~'
    _destinationFile="${_destinationFile/\~/${HOME}}"
    _sourceFile="${_sourceFile/\~/${HOME}}"

    [ ! -e "${_sourceFile}" ] \
        && {
            error "'${_sourceFile}' not found"
            return 1
        }
    [ -z "${_destinationFile}" ] \
        && {
            error "'${_destinationFile}' not specified"
            return 1
        }

    # Create destination directory if needed
    [ ! -d "${_destinationFile%/*}" ] \
        && _execute_ "mkdir -p \"${_destinationFile%/*}\""

    if [ ! -e "${_destinationFile}" ]; then
        _execute_ "ln -fs \"${_sourceFile}\" \"${_destinationFile}\"" "symlink ${_sourceFile} → ${_destinationFile}"
    elif [ -h "${_destinationFile}" ]; then
        _originalFile="$(realpath "${_destinationFile}")"

        [[ ${_originalFile} == "${_sourceFile}" ]] && {
            if [[ ${_onlyShowChanged} == true ]]; then
                debug "Symlink already exists: ${_sourceFile} → ${_destinationFile}"
            elif [[ ${DRYRUN:-} == true ]]; then
                dryrun "Symlink already exists: ${_sourceFile} → ${_destinationFile}"
            else
                info "Symlink already exists: ${_sourceFile} → ${_destinationFile}"
            fi
            return 0
        }

        if [[ ${_backupOriginal} == true ]]; then
            _backupFile_ "${_destinationFile}"
        fi
        if [[ ${DRYRUN} == false ]]; then
            if [[ ${_useSudo} == true ]]; then
                command rm -rf "${_destinationFile}"
            else
                command rm -rf "${_destinationFile}"
            fi
        fi
        _execute_ "ln -fs \"${_sourceFile}\" \"${_destinationFile}\"" "symlink ${_sourceFile} → ${_destinationFile}"
    elif [ -e "${_destinationFile}" ]; then
        if [[ ${_backupOriginal} == true ]]; then
            _backupFile_ "${_destinationFile}"
        fi
        if [[ ${DRYRUN} == false ]]; then
            if [[ ${_useSudo} == true ]]; then
                sudo command rm -rf "${_destinationFile}"
            else
                command rm -rf "${_destinationFile}"
            fi
        fi
        _execute_ "ln -fs \"${_sourceFile}\" \"${_destinationFile}\"" "symlink ${_sourceFile} → ${_destinationFile}"
    else
        warning "Error linking: ${_sourceFile} → ${_destinationFile}"
        return 1
    fi
    return 0
}

_createUniqueFilename_() {
    # DESC:
    #         Ensure a file to be created has a unique filename to avoid overwriting other
    #         filenames by incrementing a number at the end of the filename
    # ARGS:
    #         $1 (Required) - Name of file to be created
    #         $2 (Optional) - Separation character (Defaults to a period '.')
    # OUTS:
    #         stdout: Unique name of file
    #         0 if successful
    #         1 if not successful
    # OPTS:
    #         -i:   Places the unique integer before the file extension
    # USAGE:
    #         _createUniqueFilename_ "/some/dir/file.txt" --> /some/dir/file.txt.1
    #         _createUniqueFilename_ -i"/some/dir/file.txt" "-" --> /some/dir/file-1.txt
    #         printf "%s" "line" > "$(_createUniqueFilename_ "/some/dir/file.txt")"

    [[ $# -lt 1 ]] && fatal "Missing required argument to ${FUNCNAME[0]}"

    local opt
    local OPTIND=1
    local _internalInteger=false
    while getopts ":iI" opt; do
        case ${opt} in
            i | I) _internalInteger=true ;;
            *)
                error "Unrecognized option '${1}' passed to ${FUNCNAME[0]}" "${LINENO}"
                return 1
                ;;
        esac
    done
    shift $((OPTIND - 1))

    [[ $# == 0 ]] && fatal "Missing required argument to ${FUNCNAME[0]}"

    local _fullFile="${1}"
    local _spacer="${2:-.}"
    local _filePath
    local _originalFile
    local _extension
    local _newFilename
    local _num
    local _levels
    local _fn
    local _ext
    local i

    # Find directories with realpath if input is an actual file
    if [ -e "${_fullFile}" ]; then
        _fullFile="$(realpath "${_fullFile}")"
    fi

    _filePath="$(dirname "${_fullFile}")"
    _originalFile="$(basename "${_fullFile}")"

    #shellcheck disable=SC2064
    trap '$(shopt -p nocasematch)' RETURN # reset nocasematch when function exits
    shopt -s nocasematch                  # Use case-insensitive regex

    # Detect some common multi-extensions
    case $(tr '[:upper:]' '[:lower:]' <<<"${_originalFile}") in
        *.tar.gz | *.tar.bz2) _levels=2 ;;
        *) _levels=1 ;;
    esac

    # Find Extension
    _fn="${_originalFile}"
    for ((i = 0; i < _levels; i++)); do
        _ext=${_fn##*.}
        if [[ ${i} == 0 ]]; then
            _extension=${_ext}${_extension:-}
        else
            _extension=${_ext}.${_extension:-}
        fi
        _fn=${_fn%."${_ext}"}
    done

    if [[ ${_extension} == "${_originalFile}" ]]; then
        _extension=""
    else
        _originalFile="${_originalFile%."${_extension}"}"
        _extension=".${_extension}"
    fi

    _newFilename="${_filePath}/${_originalFile}${_extension:-}"

    if [ -e "${_newFilename}" ]; then
        _num=1
        if [ "${_internalInteger}" = true ]; then
            while [[ -e "${_filePath}/${_originalFile}${_spacer}${_num}${_extension:-}" ]]; do
                ((_num++))
            done
            _newFilename="${_filePath}/${_originalFile}${_spacer}${_num}${_extension:-}"
        else
            while [[ -e "${_filePath}/${_originalFile}${_extension:-}${_spacer}${_num}" ]]; do
                ((_num++))
            done
            _newFilename="${_filePath}/${_originalFile}${_extension:-}${_spacer}${_num}"
        fi
    fi

    printf "%s\n" "${_newFilename}"
    return 0
}
# ################################## Functions required for this template to work

_setColors_() {
    # DESC:
    #         Sets colors use for alerts.
    # ARGS:
    #         None
    # OUTS:
    #         None
    # USAGE:
    #         printf "%s\n" "${blue}Some text${reset}"

    if tput setaf 1 >/dev/null 2>&1; then
        bold=$(tput bold)
        underline=$(tput smul)
        reverse=$(tput rev)
        reset=$(tput sgr0)

        if [[ $(tput colors) -ge 256 ]] >/dev/null 2>&1; then
            white=$(tput setaf 231)
            blue=$(tput setaf 38)
            yellow=$(tput setaf 11)
            green=$(tput setaf 82)
            red=$(tput setaf 1)
            purple=$(tput setaf 171)
            gray=$(tput setaf 250)
        else
            white=$(tput setaf 7)
            blue=$(tput setaf 38)
            yellow=$(tput setaf 3)
            green=$(tput setaf 2)
            red=$(tput setaf 1)
            purple=$(tput setaf 13)
            gray=$(tput setaf 7)
        fi
    else
        bold="\033[4;37m"
        reset="\033[0m"
        underline="\033[4;37m"
        # shellcheck disable=SC2034
        reverse=""
        white="\033[0;37m"
        blue="\033[0;34m"
        yellow="\033[0;33m"
        green="\033[1;32m"
        red="\033[0;31m"
        purple="\033[0;35m"
        gray="\033[0;37m"
    fi
}

_alert_() {
    # DESC:
    #         Controls all printing of messages to log files and stdout.
    # ARGS:
    #         $1 (required) - The type of alert to print
    #                         (success, header, notice, dryrun, debug, warning, error,
    #                         fatal, info, input)
    #         $2 (required) - The message to be printed to stdout and/or a log file
    #         $3 (optional) - Pass '${LINENO}' to print the line number where the _alert_ was triggered
    # OUTS:
    #         stdout: The message is printed to stdout
    #         log file: The message is printed to a log file
    # USAGE:
    #         [_alertType] "[MESSAGE]" "${LINENO}"
    # NOTES:
    #         - The colors of each alert type are set in this function
    #         - For specified alert types, the funcstac will be printed

    local _color
    local _alertType="${1}"
    local _message="${2}"
    local _line="${3:-}" # Optional line number

    [[ $# -lt 2 ]] && fatal 'Missing required argument to _alert_'

    if [[ -n ${_line} && ${_alertType} =~ ^(fatal|error) && ${FUNCNAME[2]} != "_trapCleanup_" ]]; then
        _message="${_message} ${gray}(line: ${_line}) $(_printFuncStack_)"
    elif [[ -n ${_line} && ${FUNCNAME[2]} != "_trapCleanup_" ]]; then
        _message="${_message} ${gray}(line: ${_line})"
    elif [[ -z ${_line} && ${_alertType} =~ ^(fatal|error) && ${FUNCNAME[2]} != "_trapCleanup_" ]]; then
        _message="${_message} ${gray}$(_printFuncStack_)"
    fi

    if [[ ${_alertType} =~ ^(error|fatal) ]]; then
        _color="${bold}${red}"
    elif [ "${_alertType}" == "info" ]; then
        _color="${gray}"
    elif [ "${_alertType}" == "warning" ]; then
        _color="${red}"
    elif [ "${_alertType}" == "success" ]; then
        _color="${green}"
    elif [ "${_alertType}" == "debug" ]; then
        _color="${purple}"
    elif [ "${_alertType}" == "header" ]; then
        _color="${bold}${white}${underline}"
    elif [ "${_alertType}" == "notice" ]; then
        _color="${bold}"
    elif [ "${_alertType}" == "input" ]; then
        _color="${bold}${underline}"
    elif [ "${_alertType}" = "dryrun" ]; then
        _color="${blue}"
    else
        _color=""
    fi

    _writeToScreen_() {
        ("${QUIET}") && return 0 # Print to console when script is not 'quiet'
        [[ ${VERBOSE} == false && ${_alertType} =~ ^(debug|verbose) ]] && return 0

        if ! [[ -t 1 || -z ${TERM:-} ]]; then # Don't use colors on non-recognized terminals
            _color=""
            reset=""
        fi

        if [[ ${_alertType} == header ]]; then
            printf "${_color}%s${reset}\n" "${_message}"
        else
            printf "${_color}[%7s] %s${reset}\n" "${_alertType}" "${_message}"
        fi
    }
    _writeToScreen_

    _writeToLog_() {
        [[ ${_alertType} == "input" ]] && return 0
        [[ ${LOGLEVEL} =~ (off|OFF|Off) ]] && return 0
        if [ -z "${LOGFILE:-}" ]; then
            LOGFILE="$(pwd)/$(basename "$0").log"
        fi
        [ ! -d "$(dirname "${LOGFILE}")" ] && mkdir -p "$(dirname "${LOGFILE}")"
        [[ ! -f ${LOGFILE} ]] && touch "${LOGFILE}"

        # Don't use colors in logs
        local _cleanmessage
        _cleanmessage="$(printf "%s" "${_message}" | sed -E 's/(\x1b)?\[(([0-9]{1,2})(;[0-9]{1,3}){0,2})?[mGK]//g')"
        # Print message to log file
        printf "%s [%7s] %s %s\n" "$(date +"%b %d %R:%S")" "${_alertType}" "[$(/bin/hostname)]" "${_cleanmessage}" >>"${LOGFILE}"
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
            if [[ ${_alertType} =~ ^(error|fatal|warning|info|notice|success) ]]; then
                _writeToLog_
            fi
            ;;
        NOTICE | notice | Notice)
            if [[ ${_alertType} =~ ^(error|fatal|warning|notice|success) ]]; then
                _writeToLog_
            fi
            ;;
        WARN | warn | Warn)
            if [[ ${_alertType} =~ ^(error|fatal|warning) ]]; then
                _writeToLog_
            fi
            ;;
        ERROR | error | Error)
            if [[ ${_alertType} =~ ^(error|fatal) ]]; then
                _writeToLog_
            fi
            ;;
        FATAL | fatal | Fatal)
            if [[ ${_alertType} =~ ^fatal ]]; then
                _writeToLog_
            fi
            ;;
        OFF | off)
            return 0
            ;;
        *)
            if [[ ${_alertType} =~ ^(error|fatal) ]]; then
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
header() { _alert_ header "${1}" "${2:-}"; }
debug() { _alert_ debug "${1}" "${2:-}"; }
fatal() {
    _alert_ fatal "${1}" "${2:-}"
    _safeExit_ "1"
}

_printFuncStack_() {
    # DESC:
    #         Prints the function stack in use. Used for debugging, and error reporting.
    # ARGS:
    #         None
    # OUTS:
    #         stdout: Prints [function]:[file]:[line]
    # NOTE:
    #         Does not print functions from the alert class
    local _i
    declare -a _funcStackResponse=()
    for ((_i = 1; _i < ${#BASH_SOURCE[@]}; _i++)); do
        case "${FUNCNAME[${_i}]}" in
            _alert_ | _trapCleanup_ | fatal | error | warning | notice | info | debug | dryrun | header | success)
                continue
                ;;
            *)
                _funcStackResponse+=("${FUNCNAME[${_i}]}:$(basename "${BASH_SOURCE[${_i}]}"):${BASH_LINENO[_i - 1]}")
                ;;
        esac

    done
    printf "( "
    printf %s "${_funcStackResponse[0]}"
    printf ' < %s' "${_funcStackResponse[@]:1}"
    printf ' )\n'
}

_safeExit_() {
    # DESC:
    #       Cleanup and exit from a script
    # ARGS:
    #       $1 (optional) - Exit code (defaults to 0)
    # OUTS:
    #       None

    if [[ -d ${SCRIPT_LOCK:-} ]]; then
        if command rm -rf "${SCRIPT_LOCK}"; then
            debug "Removing script lock"
        else
            warning "Script lock could not be removed. Try manually deleting ${yellow}'${SCRIPT_LOCK}'"
        fi
    fi

    if [[ -n ${TMP_DIR:-} && -d ${TMP_DIR:-} ]]; then
        if [[ ${1:-} == 1 && -n "$(ls "${TMP_DIR}")" ]]; then
            command rm -r "${TMP_DIR}"
        else
            command rm -r "${TMP_DIR}"
            debug "Removing temp directory"
        fi
    fi

    trap - INT TERM EXIT
    exit "${1:-0}"
}

_trapCleanup_() {
    # DESC:
    #         Log errors and cleanup from script when an error is trapped.  Called by 'trap'
    # ARGS:
    #         $1:  Line number where error was trapped
    #         $2:  Line number in function
    #         $3:  Command executing at the time of the trap
    #         $4:  Names of all shell functions currently in the execution call stack
    #         $5:  Scriptname
    #         $6:  $BASH_SOURCE
    # USAGE:
    #         trap '_trapCleanup_ ${LINENO} ${BASH_LINENO} "${BASH_COMMAND}" "${FUNCNAME[*]}" "${0}" "${BASH_SOURCE[0]}"' EXIT INT TERM SIGINT SIGQUIT SIGTERM ERR
    # OUTS:
    #         Exits script with error code 1

    local _line=${1:-} # LINENO
    local _linecallfunc=${2:-}
    local _command="${3:-}"
    local _funcstack="${4:-}"
    local _script="${5:-}"
    local _sourced="${6:-}"

    if declare -f "fatal" &>/dev/null && declare -f "_printFuncStack_" &>/dev/null; then

        _funcstack="'$(printf "%s" "${_funcstack}" | sed -E 's/ / < /g')'"

        if [[ ${_script##*/} == "${_sourced##*/}" ]]; then
            fatal "${7:-} command: '${_command}' (line: ${_line}) [func: $(_printFuncStack_)]"
        else
            fatal "${7:-} command: '${_command}' (func: ${_funcstack} called at line ${_linecallfunc} of '${_script##*/}') (line: ${_line} of '${_sourced##*/}') "
        fi
    else
        printf "%s\n" "Fatal error trapped. Exiting..."
    fi

    if declare -f _safeExit_ &>/dev/null; then
        _safeExit_ 1
    else
        exit 1
    fi
}

_makeTempDir_() {
    # DESC:
    #         Creates a temp directory to house temporary files
    # ARGS:
    #         $1 (Optional) - First characters/word of directory name
    # OUTS:
    #         Sets $TMP_DIR variable to the path of the temp directory
    # USAGE:
    #         _makeTempDir_ "$(basename "$0")"

    [ -d "${TMP_DIR:-}" ] && return 0

    if [ -n "${1:-}" ]; then
        TMP_DIR="${TMPDIR:-/tmp/}${1}.${RANDOM}.${RANDOM}.$$"
    else
        TMP_DIR="${TMPDIR:-/tmp/}$(basename "$0").${RANDOM}.${RANDOM}.${RANDOM}.$$"
    fi
    (umask 077 && mkdir "${TMP_DIR}") || {
        fatal "Could not create temporary directory! Exiting."
    }
    debug "\$TMP_DIR=${TMP_DIR}"
}

# shellcheck disable=SC2120
_acquireScriptLock_() {
    # DESC:
    #         Acquire script lock to prevent running the same script a second time before the
    #         first instance exits
    # ARGS:
    #         $1 (optional) - Scope of script execution lock (system or user)
    # OUTS:
    #         exports $SCRIPT_LOCK - Path to the directory indicating we have the script lock
    #         Exits script if lock cannot be acquired
    # NOTE:
    #         If the lock was acquired it's automatically released in _safeExit_()

    local _lockDir
    if [[ ${1:-} == 'system' ]]; then
        _lockDir="${TMPDIR:-/tmp/}$(basename "$0").lock"
    else
        _lockDir="${TMPDIR:-/tmp/}$(basename "$0").${UID}.lock"
    fi

    if command mkdir "${_lockDir}" 2>/dev/null; then
        readonly SCRIPT_LOCK="${_lockDir}"
        debug "Acquired script lock: ${yellow}${SCRIPT_LOCK}${purple}"
    else
        if declare -f "_safeExit_" &>/dev/null; then
            error "Unable to acquire script lock: ${yellow}${_lockDir}${red}"
            fatal "If you trust the script isn't running, delete the lock dir"
        else
            printf "%s\n" "ERROR: Could not acquire script lock. If you trust the script isn't running, delete: ${_lockDir}"
            exit 1
        fi

    fi
}

_setPATH_() {
    # DESC:
    #         Add directories to $PATH so script can find executables
    # ARGS:
    #         $@ - One or more paths
    # OUTS:   Adds items to $PATH
    # USAGE:
    #         _setPATH_ "/usr/local/bin" "${HOME}/bin" "$(npm bin)"

    [[ $# == 0 ]] && fatal "Missing required argument to ${FUNCNAME[0]}"

    local _newPath

    for _newPath in "$@"; do
        if [ -d "${_newPath}" ]; then
            if ! printf "%s" "${PATH}" | grep -Eq "(^|:)${_newPath}($|:)"; then
                if PATH="${_newPath}:${PATH}"; then
                    debug "Added '${_newPath}' to PATH"
                else
                    return 1
                fi
            else
                debug "_setPATH_: '${_newPath}' already exists in PATH"
            fi
        else
            debug "_setPATH_: can not find: ${_newPath}"
            continue
        fi
    done
    return 0
}

_useGNUutils_() {
    # DESC:
    #					Add GNU utilities to PATH to allow consistent use of sed/grep/tar/etc. on MacOS
    # ARGS:
    #					None
    # OUTS:
    #					0 if successful
    #         1 if unsuccessful
    #         PATH: Adds GNU utilities to the path
    # USAGE:
    #					# if ! _useGNUUtils_; then exit 1; fi
    # NOTES:
    #					GNU utilities can be added to MacOS using Homebrew

    ! declare -f "_setPATH_" &>/dev/null && fatal "${FUNCNAME[0]} needs function _setPATH_"

    if _setPATH_ \
        "/usr/local/opt/gnu-tar/libexec/gnubin" \
        "/usr/local/opt/coreutils/libexec/gnubin" \
        "/usr/local/opt/gnu-sed/libexec/gnubin" \
        "/usr/local/opt/grep/libexec/gnubin" \
        "/usr/local/opt/findutils/libexec/gnubin" \
        "/opt/homebrew/opt/findutils/libexec/gnubin" \
        "/opt/homebrew/opt/gnu-sed/libexec/gnubin" \
        "/opt/homebrew/opt/grep/libexec/gnubin" \
        "/opt/homebrew/opt/coreutils/libexec/gnubin" \
        "/opt/homebrew/opt/gnu-tar/libexec/gnubin"; then
        return 0
    else
        return 1
    fi

}

_parseOptions_() {
    # DESC:
    #					Iterates through options passed to script and sets variables. Will break -ab into -a -b
    #         when needed and --foo=bar into --foo bar
    # ARGS:
    #					$@ from command line
    # OUTS:
    #					Sets array 'ARGS' containing all arguments passed to script that were not parsed as options
    # USAGE:
    #					_parseOptions_ "$@"

    # Iterate over options
    local _optstring=h
    declare -a _options
    local _c
    local i
    while (($#)); do
        case $1 in
            # If option is of type -ab
            -[!-]?*)
                # Loop over each character starting with the second
                for ((i = 1; i < ${#1}; i++)); do
                    _c=${1:i:1}
                    _options+=("-${_c}") # Add current char to options
                    # If option takes a required argument, and it's not the last char make
                    # the rest of the string its argument
                    if [[ ${_optstring} == *"${_c}:"* && -n ${1:i+1} ]]; then
                        _options+=("${1:i+1}")
                        break
                    fi
                done
                ;;
            # If option is of type --foo=bar
            --?*=*) _options+=("${1%%=*}" "${1#*=}") ;;
            # add --endopts for --
            --) _options+=(--endopts) ;;
            # Otherwise, nothing special
            *) _options+=("$1") ;;
        esac
        shift
    done
    set -- "${_options[@]:-}"
    unset _options

    # Read the options and set stuff
    # shellcheck disable=SC2034
    while [[ ${1:-} == -?* ]]; do
        case $1 in
            # Custom options
            --user-home)
                shift
                USER_HOME="$1"
                ;;
            --skip-backup)
                SKIP_BACKUP=true
                ;;
            # Common options
            -h | --help)
                _usage_
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
            *)
                if declare -f _safeExit_ &>/dev/null; then
                    fatal "invalid option: $1"
                else
                    printf "%s\n" "ERROR: Invalid option: $1"
                    exit 1
                fi
                ;;
        esac
        shift
    done

    if [[ -z ${*} ]]; then
        ARGS=()
    else
        ARGS+=("$@") # Store the remaining user input as arguments.
    fi
}

_usage_() {
    cat <<USAGE_TEXT

  ${bold}$(basename "$0") [OPTION]...${reset}

  This script creates symlinks in the user's home directory to the dotfiles contained in
  this repository.  In addition, selected git repositories are cloned into the users home directory.

  Be sure to review the settings and information within this repository as well as the repos
  specified in _mainScript_() before running this script.

  ${bold}Options:${reset}
    --user-home [DIR]       Set user home directory to symlink dotfiles to (Defaults to '~/')
    --skip-backup           Skip backing up existing dotfiles. Default will create a backup of
                            existing dotfiles in the user's home directory which are modified by
                            this script.
    -h, --help              Display this help and exit
    --loglevel [LEVEL]      One of: FATAL, ERROR, WARN, INFO, NOTICE, DEBUG, ALL, OFF
                            (Default is 'ERROR')
    --logfile [FILE]        Full PATH to logfile.  (Default is '${HOME}/logs/$(basename "$0").log')
    -n, --dryrun            Non-destructive. Makes no permanent changes.
    -q, --quiet             Quiet (no output)
    -v, --verbose           Output more information. (Items echoed to 'verbose')
    --force                 Skip all user interaction.  Implied 'Yes' to all actions.

  ${bold}Example Usage:${reset}

      $ $(basename "$0") --user-home "/user/home/user1/"
USAGE_TEXT
}

# ################################## INITIALIZE AND RUN THE SCRIPT
#                                    (Comment or uncomment the lines below to customize script behavior)

trap '_trapCleanup_ ${LINENO} ${BASH_LINENO} "${BASH_COMMAND}" "${FUNCNAME[*]}" "${0}" "${BASH_SOURCE[0]}"' EXIT INT TERM SIGINT SIGQUIT SIGTERM

# Trap errors in subshells and functions
set -o errtrace

# Exit on error. Append '||true' if you expect an error
set -o errexit

# Use last non-zero exit code in a pipeline
set -o pipefail

# Confirm we have BASH greater than v4
#[ "${BASH_VERSINFO:-0}" -ge 4 ] || {
#    printf "%s\n" "ERROR: BASH_VERSINFO is '${BASH_VERSINFO:-0}'.  This script requires BASH v4 or greater."
#    exit 1
#}

# Make `for f in *.txt` work when `*.txt` matches zero files
# shopt -s nullglob globstar

# Set IFS to preferred implementation
IFS=$' \n\t'

# Run in debug mode
# set -o xtrace

# Initialize color constants
_setColors_

# Disallow expansion of unset variables
# set -o nounset

# Force arguments when invoking the script
# [[ $# -eq 0 ]] && _parseOptions_ "-h"

# Parse arguments passed to script
_parseOptions_ "$@"

# Create a temp directory '$TMP_DIR'
# _makeTempDir_ "$(basename "$0")"

# Acquire script lock
# _acquireScriptLock_

# Source GNU utilities for use on MacOS
_useGNUutils_

# Run the main logic script
_mainScript_

# Exit cleanly
_safeExit_
