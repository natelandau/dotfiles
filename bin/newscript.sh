#!/usr/bin/env bash

_mainScript_() {

  template="${HOME}/dotfiles/scripting/scriptTemplate.sh"
  [ ! -f "$template" ] \
    && {
      error "Can not find script template expected at '$template'"
      _safeExit_
    }

  [ ${#args[@]} -eq 0 ] && error "No script name specified"

  _errorChecks_() {

    [ -e "${1}" ] \
      && {
        warning "'${1}' already exists."
        return 1
      }
    return 0
  }

  _addExtension_() {
    case "${1}" in
      *.*)
        echo "$1"
        return 0
        ;;
    esac

    echo "${1}.sh"
  }

  for a in "${args[@]}"; do
    a="$(_addExtension_ "$a")"

    if ! _errorChecks_ "$a"; then
      break
    fi
    _execute_ -s "cp \"$template\" \"$a\"; chmod a+x \"$a\"" "Created '${a}'"
  done

} # end _mainScript_

_sourceHelperFiles_() {
  local filesToSource
  local sourceFile
  filesToSource=(
    "${HOME}/dotfiles/scripting/helpers/baseHelpers.bash"
    "${HOME}/dotfiles/scripting/helpers/files.bash"
  )
  for sourceFile in "${filesToSource[@]}"; do
    [ ! -f "$sourceFile" ] \
      && {
        echo "error: Can not find sourcefile '$sourceFile'."
        echo "exiting..."
        exit 1
      }
    source "$sourceFile"
  done
}
_sourceHelperFiles_

# Set Flags
quiet=false
printLog=false
logErrors=false
verbose=false
force=false
dryrun=false
args=()

# Options and Usage
# -----------------------------------
_usage_() {
  cat <<EOF

  $(basename "$0") [OPTIONS]... [NEWSCRIPTNAME]...

  Create a blank shell script based on a script template in the current directory.

 ${bold}Usage:${reset}

    $ $(basename "$0") NEWSCRIPTNAME.SH

 ${bold}Options:${reset}
  -l, --log         Print log to file with all log levels
  -n, --dryrun      Non-destructive. Makes no permanent changes.
  -q, --quiet       Quiet (no output)
  -v, --verbose     Output more information. (Items echoed to 'verbose')
  -h, --help        Display this help and exit
EOF
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
          options+=("-$c")  # Add current char to options
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
  while [[ $1 == -?* ]]; do
    case $1 in
      -h | --help)
        _usage_ >&2
        _safeExit_
        ;;
      -L | --noErrorLog) logErrors=false ;;
      -n | --dryrun) dryrun=true ;;
      -v | --verbose) verbose=true ;;
      -l | --log) printLog=true ;;
      -q | --quiet) quiet=true ;;
      --endopts)
        shift
        break
        ;;
      *) die "invalid option: '$1'." ;;
    esac
    shift
  done
  args+=("$@")  # Store the remaining user input as arguments.
}
_parseOptions_ "$@"

# Initialize and run the script
trap '_trapCleanup_ $LINENO $BASH_LINENO "$BASH_COMMAND" "${FUNCNAME[*]}" "$0" "${BASH_SOURCE[0]}"' \
  EXIT INT TERM SIGINT SIGQUIT
set -o errtrace                             # Trap errors in subshells and functions
set -o errexit                              # Exit on error. Append '||true' if you expect an error
set -o pipefail                             # Use last non-zero exit code in a pipeline
shopt -s nullglob globstar                  # Make `for f in *.txt` work when `*.txt` matches zero files
IFS=$' \n\t'                                # Set IFS to preferred implementation
# set -o xtrace                             # Uncomment to run in debug mode
set -o nounset                              # Disallow expansion of unset variables
[[ $# -eq 0 ]] && _parseOptions_ "-h"       # Uncomment to force arguments when invoking the script
# _makeTempDir_ "$(basename "$0")"          # Uncomment to create a temp directory '$tmpDir'
# _acquireScriptLock_                       # Uncomment to acquire script lock
_mainScript_                              # Run script unless in 'source-only' mode
_safeExit_                                # Exit cleanly