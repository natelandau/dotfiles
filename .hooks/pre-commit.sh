#!/usr/bin/env bash

_mainScript_() {

  # Ensure that no symlinks are added. Here we add them to .gitignore
  GITROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  _setPATH_ "/usr/local/bin" "${HOME}/bin"

  _ignoreSymlinks_() {
    # Ensure that no symlinks have been added to the repository.

    local gitIgnore="${GITROOT}/.gitignore"
    local havesymlink=false

    # Work on files not yet staged
    for f in $(git status --porcelain | grep '^??' | sed 's/^?? //'); do
      if [ -L "${f}" ]; then
        if ! grep "${f}" "${gitIgnore}"; then
          if echo -e "\n${f}" >>"${gitIgnore}"; then
            info "Added symlink '${f}' to .gitignore"
          else
            fatal "Could not add symlink '${f}' to .gitignore"
          fi
        fi
        havesymlink=true
      fi
    done

    # Work on files that were mistakenly staged
    for f in $(git status --porcelain | grep '^A' | sed 's/^A //'); do
      if [ -L "${f}" ]; then
        if ! grep "${f}" "${gitIgnore}"; then
          if echo -e "\n${f}" >>"${gitIgnore}"; then
            info "Added symlink '${f}' to .gitignore"
          else
            fatal "Could not add symlink '${f}' to .gitignore"
          fi
        fi
        havesymlink=true
      fi
    done

    if ${havesymlink}; then
      error "At least one symlink was added to the repo."
      error "Commit aborted..."
      _safeExit_ 1
    fi
  }
  _ignoreSymlinks_

  # if you only want to lint the staged changes, not any un-staged changes, use:
  # git show ":$file" | <command>

  # Lint YAML files
  if command -v yaml-lint >/dev/null; then
    for file in $(git diff --cached --name-only | grep -E '\.(yaml|yml)$'); do
      if ! yaml-lint "${file}"; then
        error "Error in ${file}"
        _safeExit_ 1
      else
        success "yaml-lint passed: '${file}'"
      fi
    done
  fi

  # Lint shell scripts
  if command -v shellcheck >/dev/null; then
    for file in $(git diff --cached --name-only | grep -E '\.(sh|bash)$'); do
      if [ -f "$file" ]; then
        if ! shellcheck --exclude=2016,2059,2001,2002,2148,1090,2162,2005,2034,2154,2086,2155,2181,2164,2120,2119,1083,1117,2207 "${file}"; then
          error "Error in ${file}"
          _safeExit_ 1
        else
          success "shellcheck passed: '${file}'"
        fi
      fi
    done
  fi

  _BATS_() {
    local filename file

    # Run all tests if shared scripting functions are changed
    if git diff --cached --name-only | grep -E 'helpers/.*\.(bash|sh)$'; then
      if [ -f "${GITROOT}/test/runtests.sh" ]; then
        notice "## Running all bats tests ##"
        if ! "${GITROOT}/test/runtests.sh"; then
          error "Error encountered running automated testing. Exiting."
          _safeExit_ 1
        fi
      else
        notice "## Running all bats tests ##"
        for test in "${GITROOT}"/test/*.bats; do
          notice "####### Running: ${test} #######"
          if ! "${test} -t"; then
            error "Error found running ${test}"
            _safeExit_ 1
          fi
        done
      fi
      return 0
    fi

    # Run BATS unit tests on individual files
    for file in $(git diff --cached --name-only | grep -E '\.(sh|bash|bats|zsh)$'); do
      filename="$(basename "${file}")"
      filename="${filename%.*}"
      [ -f "${GITROOT}/test/${filename}.bats" ] \
        && {
          notice "Running ${filename}.bats"
          if ! "${GITROOT}/test/${filename}.bats" -t; then
            error "Error in ${file}"
            _safeExit_ 1
          fi
        }
      unset filename
    done

  }
  if command -v bats &>/dev/null; then _BATS_; fi

} # end _mainScript_

_sourceHelperFiles_() {
  # DESC: Sources script helper files
  local filesToSource
  local sourceFile
  filesToSource=(
    "${HOME}/dotfiles/scripting/helpers/baseHelpers.bash"
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
logErrors=false
verbose=false
force=false
dryrun=false
declare -a args=()

_usage_() {
  cat <<EOF

  ${bold}$(basename "$0") [OPTION]... [FILE]...${reset}

  This script runs a number of automated tests on files that are staged in Git prior to
  allowing them to be committed

  ${bold}Options:${reset}
    -h, --help        Display this help and exit
    -L, --noErrorLog  Default behavior is to print log level error and fatal to a log. Use
                      this flag to generate no log files at all.
    -l, --log         Print log to file with all log levels
    -n, --dryrun      Non-destructive. Makes no permanent changes.
    -q, --quiet       Quiet (no output)
    -v, --verbose     Output more information. (Items echoed to 'verbose')
    --force           Skip all user interaction.  Implied 'Yes' to all actions.
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
  set -- "${options[@]-}"
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
set -o errtrace                           # Trap errors in subshells and functions
set -o errexit                            # Exit on error. Append '||true' if you expect an error
set -o pipefail                           # Use last non-zero exit code in a pipeline
#shopt -s nullglob globstar               # Make `for f in *.txt` work when `*.txt` matches zero files
IFS=$' \n\t'                              # Set IFS to preferred implementation
# set -o xtrace                           # Run in debug mode
set -o nounset                            # Disallow expansion of unset variables
# [[ $# -eq 0 ]] && _parseOptions_ "-h"   # Force arguments when invoking the script
_parseOptions_ "$@"                       # Parse arguments passed to script
# _makeTempDir_ "$(basename "$0")"        # Create a temp directory '$tmpDir'
# _acquireScriptLock_                     # Acquire script lock
_mainScript_                              # Run script
_safeExit_                                # Exit cleanly
