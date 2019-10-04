#!/usr/bin/env bash

_mainScript_() {

  _actOnFile_() {

    if [[ ${#args[@]} == 1 ]]; then
      fileName="${args[0]}"
      if [ -e "$fileName" ]; then
        return 0
      else
        return 1
      fi
    else
      return 1
    fi

  }

  _automateHashCheck_() {
    local l h f n

    # shellcheck disable=SC2207
    #local array=("$(_listFiles_ r ".*\.[sha256|md5|txt]*")")
    readarray -t array < <(_listFiles_ r ".*\.[sha256|md5|txt]*")

    for l in "${array[@]}"; do

      if [[ "$l" =~ sha256 ]]; then
        if _seekConfirmation_ "We found a ''.sha256' file. Do you want to automatically check the validity?"; then
          notice "Parsing $l"

          h=$(_readFile_ "$l" | cut -d' ' -f1)
          f=$(_readFile_ "$l" | cut -d' ' -f2)
          if [ -z "$f" ]; then f=$(_readFile_ "$l" | cut -d' ' -f3); fi

          info "file contained hash: $h"
          info "referring to: $f"

          notice "Generating and comparing sha256 hash of $f"
          [ ! -e "$f" ] \
            && fatal "could not find file: $f"

          n=$(openssl dgst -sha256 "$f" | cut -d' ' -f2)

          if [[ "$h" == "$n" ]]; then
            success "The two sha256 hashes match"
            _safeExit_ 0
          else
            warning "The two sha256 hashes do not match"
            _safeExit_ 1
          fi
        fi
      fi
    done
  }
  _automateHashCheck_

  _manualHashCheck_() {
    local hashType n h f ff command
    input "What type of hash are you validating?\n"
    info "[1] - md5"
    info "[2] - SHA-1"
    info "[3] - SHA-256"
    read -r -p "Enter number: " n

    case $n in
      1)
        hashType="md5"
        command="openssl md5"
        ;;
      2)
        hashType="SHA-1"
        command="openssl sha1"
        ;;
      3)
        hashType="SHA-256"
        command="openssl dgst -sha256"
        ;;
      *)
        notice "Could not understand input: '$n'"
        _safeExit_ 0
        ;;
    esac

    read -r -p "Paste the $hashType hash: " h

    if _actOnFile_; then
      f="$fileName"
    else
      read -r -p "Paste the filename to check: " f
    fi

    notice "Comparing the $hashType hash of '$f'"

    [ ! -f "$f" ] \
      && {
        warning "Can not find sourcefile '$f'. Exiting."
        _safeExit_ 1
      }

    ff="$(_realpath_ "$f")"

    hh="$(eval "${command}" "$ff" | cut -d' ' -f2)"

    if [[ "$h" == "$hh" ]]; then
      success "The two $hashType hashes match"
      _safeExit_ 0
    else
      warning "The two $hashType hashes do not match"
      _safeExit_ 1
    fi
  }
  _manualHashCheck_

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

# Set initial flags
quiet=false
printLog=false
logErrors=true
verbose=false
force=false
dryrun=false
declare -a args=()

_usage_() {
  cat <<EOF

  $(basename "$0") [OPTION]... [FILE]...

  This script is to make it easy to compare a file to its MD5, SHA-1, or SHA-256 hash.
  If a ''.sha256' file is available, it will offer to automatially compare the hashes
  found within that file.

  It will also take user input of a hash and a filename to compare the two.  This
  script requires no options and is fully interactive.

  ${bold}Usage:${reset}

    To run in an automated fashion simply invoke the script

      $ hascheck

    To specify the file on which you'd like to run the script

      $ hascheck [filename]

  ${bold}Option Flags:${reset}

  -h, --help        Display this help and exit
  -l, --log         Print log to file with all log levels
  -L, --noErrorLog  Default behavior is to print log level error and fatal to a log. Use
                    this flag to generate no log files at all.
  -n, --dryrun      Non-destructive. Makes no permanent changes.
  -q, --quiet       Quiet (no output)
  -v, --verbose     Output more information. (Items echoed to 'verbose')
  --force       Skip all user interaction.  Implied 'Yes' to all actions.
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
      -L | --noErrorLog) logErrors=false ;;
      -n | --dryrun) dryrun=true ;;
      -v | --verbose) verbose=true ;;
      -l | --log) printLog=true ;;
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

# Initialize and run the script
trap '_trapCleanup_ $LINENO $BASH_LINENO "$BASH_COMMAND" "${FUNCNAME[*]}" "$0" "${BASH_SOURCE[0]}"' \
  EXIT INT TERM SIGINT SIGQUIT
set -o errtrace                         # Trap errors in subshells and functions
set -o errexit                          # Exit on error. Append '||true' if you expect an error
set -o pipefail                         # Use last non-zero exit code in a pipeline
#shopt -s nullglob globstar             # Make `for f in *.txt` work when `*.txt` matches zero files
IFS=$' \n\t'                            # Set IFS to preferred implementation
# set -o xtrace                         # Run in debug mode
set -o nounset                          # Disallow expansion of unset variables
# [[ $# -eq 0 ]] && _parseOptions_ "-h" # Force arguments when invoking the script
# _makeTempDir_ "$(basename "$0")"      # Create a temp directory '$tmpDir'
# _acquireScriptLock_                   # Acquire script lock
_parseOptions_ "$@"                     # Parse arguments passed to script
_mainScript_                            # Run script
_safeExit_                              # Exit cleanly
