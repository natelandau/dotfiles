#!/usr/bin/env bash

_mainScript_() {

  _actOnFile_() {

    [[ ${#args[@]} == 0 ]] && { return 1; }
    [[ ${#args[@]} -gt 1 ]] && { return 1; }

    if [[ ${#args[@]} == 1 ]]; then
      fileName="${args[0]}"
      if [ -e "$fileName" ]; then
        return 0
      else
        return 1
      fi
    fi

  }

  _automateHashCheck_() {
    local l h f n

    # shellcheck disable=SC2207
    local array=($(_listFiles_ r ".*\.[sha256|md5|txt]*"))

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
          [ ! -e "$f" ] &&
          fatal "could not find file: $f"

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

      ff=$(_realpath_ "$f")

      hh=$(eval "${command}" "$ff" | cut -d' ' -f2)

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
tmpDir="${TMPDIR:-/tmp/}$(basename "$0").$RANDOM.$RANDOM.$$"
(umask 077 && mkdir "${tmpDir}") || {
  fatal "Could not create temporary directory! Exiting."
}

# Options and Usage
# -----------------------------------
_usage_() {
echo -n "$(basename "$0") [OPTION]... [FILE]...

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

-L, --noErrorLog  Default behavior is to print log level error and fatal to a log. Use
this flag to generate no log files at all.
-l, --log         Print log to file with all log levels
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
  EXIT INT TERM SIGINT SIGQUIT

# Set IFS to preferred implementation
IFS=$' \n\t'

# Exit on error. Append '||true' to a command when you run the script if you expect an error.
set -o errtrace
set -o errexit

# Make `for f in *.txt` work correctly when `*.txt` matches zero files
shopt -s nullglob globstar

# Run in debug mode, if set
if ${debug}; then set -x; fi

# Exit on empty variable
if ${strict}; then set -o nounset; fi

# Run script unless in 'source-only' mode
if ! ${sourceOnly}; then _mainScript_; fi

# Exit cleanly
if ! ${sourceOnly}; then _safeExit_; fi