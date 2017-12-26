#!/usr/bin/env bash

_mainScript_() {

  echo -e "hello world"

} # end _mainScript_

_sourceHelperFiles_() {
  local filesToSource
  local sourceFile

  filesToSource=(
    "${HOME}/dotfiles/scripting/helpers/baseHelpers.bash"
  )

  for sourceFile in "${filesToSource[@]}"; do
    [ ! -f "$sourceFile" ] \
      && {
        echo "error: Can not find sourcefile '$sourceFile'. Exiting."
        exit 1
      }

    source "$sourceFile"
  done
}
_sourceHelperFiles_

# Set Flags
quiet=false
printLog=false
logErrors=true
verbose=false
force=false
strict=false
dryrun=false
debug=false
sourceOnly=false
args=()

# Set Temp Directory
tmpDir="${TMPDIR-/tmp/}$(basename "$0").$RANDOM.$RANDOM.$RANDOM.$$"
(umask 077 && mkdir "${tmpDir}") || {
  fatal "Could not create temporary directory! Exiting."
}

# Options and Usage
# -----------------------------------
_usage_() {
  echo -n "$(basename "$0") [OPTION]... [FILE]...

This is a script template.  Edit this description to print help to users.

 ${bold}Options:${reset}
  -u, --username    Username for script

    $ $(basename "$0") --username 'USERNAME'

  -p, --password    User password

    $ $(basename "$0") --password 'PASSWORD'

 ${bold}Option Flags:${reset}

  -L, --noErrorLog  Print log level error and fatal to a log (default 'true')
  -l, --log         Print log to file
  -n, --dryrun      Non-destructive. Makes no permanent changes.
  -q, --quiet       Quiet (no output)
  -s, --strict      Exit script with null variables.  i.e 'set -o nounset'
  -v, --verbose     Output more information. (Items echoed to 'verbose')
  -d, --debug       Runs script in BASH debug mode (set -x)
  -h, --help        Display this help and exit
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
      for ((i = 1; i < ${#1}; i++)); do
        c=${1:i:1}

        # Add current char to options
        options+=("-$c")

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

# Print help if no arguments were passed.
# Uncomment to force arguments when invoking the script
# -------------------------------------
# [[ $# -eq 0 ]] && set -- "--help"

# Read the options and set stuff
while [[ $1 == -?* ]]; do
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
    -L | --noErrorLog) logErrors=false ;;
    -n | --dryrun) dryrun=true ;;
    -v | --verbose) verbose=true ;;
    -l | --log) printLog=true ;;
    -q | --quiet) quiet=true ;;
    -s | --strict) strict=true ;;
    -d | --debug) debug=true ;;
    --source-only) sourceOnly=true ;;
    --force) force=true ;;
    --endopts)
      shift
      break
      ;;
    *) die "invalid option: '$1'." ;;
  esac
  shift
done

# Store the remaining part as arguments.
args+=("$@")

# Trap bad exits with your cleanup function
trap '_trapCleanup_ $LINENO $BASH_LINENO "$BASH_COMMAND" "${FUNCNAME[*]}" "$0" "${BASH_SOURCE[0]}"' \
  EXIT INT TERM SIGINT SIGQUIT ERR

# Set IFS to preferred implementation
IFS=$' \n\t'

# Exit on error. Append '||true' when you run the script if you expect an error.
#set -o errtrace
#set -o errexit

# Force pipelines to fail on the first non-zero status code.
set -o pipefail

# Run in debug mode, if set
if ${debug}; then set -x; fi

# Exit on empty variable
if ${strict}; then set -o nounset; fi

# Run your script unless in 'source-only' mode
if ! ${sourceOnly}; then _mainScript_; fi

# Exit cleanly
if ! ${sourceOnly}; then _safeExit_; fi