#!/usr/bin/env bash

version="1.0.0"

_mainScript_() {

  if ! [[ "$OSTYPE" =~ linux-gnu* ]]; then
    die "We are not on Linux"
  fi

  # Get privs upfront
  sudo -v

  # Set Variables
  baseDir="$(_findBaseDir_)"
  rootDIR="$(dirname "$baseDir")"
  privateInstallScript="${HOME}/dotfiles-private/privateInstall.sh"
  pluginScripts="${baseDir}/plugins"

  # Config files
  configSymlinks="${baseDir}/config/symlinks.yaml"
  configAptGet="${baseDir}/config/aptGet.yaml"
  configNode="${baseDir}/config/node.yaml"
  configRuby="${baseDir}/config/ruby.yaml"

  scriptFlags=()
  ($dryrun) && scriptFlags+=(--dryrun)
  ($quiet) && scriptFlags+=(--quiet)
  ($printLog) && scriptFlags+=(--log)
  ($verbose) && scriptFlags+=(--verbose)
  ($debug) && scriptFlags+=(--debug)
  ($strict) && scriptFlags+=(--strict)

  # Create symlinks
  if _seekConfirmation_ "Create symlinks to configuration files?"; then
    header "Creating Symlinks"
    _doSymlinks_ "${configSymlinks}"
  fi

  _privateRepo_() {
    if _seekConfirmation_ "Run Private install script"; then
      [ ! -f "${privateInstallScript}" ] \
        && {
          warning "Could not find private install script"
          return 1
        }
      "${privateInstallScript}" "${scriptFlags[*]}"
    fi
  }
  _privateRepo_

  _generateKey_() {
    if [ ! -f "${HOME}/.ssh/id_rsa.pub" ]; then
      header "Generating public ssh key...."
      input "what is your email? [ENTER]: "
      read -r EMAIL

      ssh-keygen -t rsa -b 4096 -C "$EMAIL"
    else
      success "Existing public key found..."
    fi
  }
  _generateKey_

  _upgradeAptGet_() {
    if [ -f "/etc/apt/sources.list" ]; then
      header "Upgrading apt-get....(May take a while)"
      _execute_ -v "sudo apt-get update"
      _execute_ -v "sudo apt-get upgrade -y"
    else
      die "Can not proceed without apt-get"
    fi
  }
  _upgradeAptGet_

  _aptGet_() {
    local t="${tmpDir}/${RANDOM}.${RANDOM}.${RANDOM}.txt"
    local c="$1" # Config YAML file

    if ! _seekConfirmation_ "Install Apt Get Packages?"; then return; fi
    header "Installing apt-get packages"

    [ ! -f "$c" ] \
      && {
        error "Can not find config file '$c'"
        return 1
      }

    # Parse & source Config File
    # shellcheck disable=2015
    (_parseYAML_ "${c}" >"${t}") \
      && { if $verbose; then
        verbose "-- Config Variables"
        _readFile_ "$t"
      fi; } \
      || die "Could not parse YAML config file"

    _sourceFile_ "$t"

    # shellcheck disable=2154
    for package in "${GeneralPackages[@]}"; do
      package=$(echo "${package}" | cut -d'#' -f1 | _trim_) # remove comments if exist
      _execute_ -v "sudo apt-get install -y \"${package}\""
    done

    # shellcheck disable=2154
    if _seekConfirmation_ "Install packages for web development?"; then
      for package in "${WebDevelopmentPackages[@]}"; do
        package=$(echo "${package}" | cut -d'#' -f1 | _trim_) # remove comments if exist
        _execute_ -v "sudo apt-get install -y \"${package}\""
      done
    fi

  }
  _aptGet_ "$configAptGet"

  _node_() {
    local package
    local npmPackages
    local modules
    local t="${tmpDir}/${RANDOM}.${RANDOM}.${RANDOM}.txt"
    local c="$1" # Config YAML file

    if ! _seekConfirmation_ "Install Node Packages?"; then return; fi

    [ ! -f "$c" ] \
      && {
        error "Can not find config file '$c'"
        return 1
      }

    # Parse & source Config File
    # shellcheck disable=2015
    (_parseYAML_ "${c}" >"${t}") \
      && { if $verbose; then
        verbose "-- Config Variables"
        _readFile_ "$t"
      fi; } \
      || die "Could not parse YAML config file"

    _sourceFile_ "$t"

    header "Installing node"

    notice "Installing nvm, node, and packages"
    _execute_ -v "sudo apt-get install -y build-essential libssl-dev checkinstall"

    NODEVERSION="8.6.0"

    if test ! "$(which node)"; then
      pushd "${HOME}"
      _execute_ -v "git clone git://github.com/creationix/nvm.git \"${HOME}/.nvm\""
      source "${HOME}/.bash_profile"
      source "${HOME}/.nvm/nvm.sh"
      _execute_ -v "nvm install \"${NODEVERSION}\""
      _execute_ "nvm use \"${NODEVERSION}\""
      success "Installed nvm and nodejs"
      popd
    fi

    # Grab packages already installed
    {
      pushd "$(npm config get prefix)/lib/node_modules"
      installed=(*)
      popd
    } &>/dev/null

    # If comments exist in the list of npm packaged to be installed remove them
    # shellcheck disable=2207
    for package in "${nodePackages[@]}"; do
      npmPackages+=($(echo "${package}" | cut -d'#' -f1 | _trim_))
    done

    # Install packages that do not already exist
    # shellcheck disable=2207
    modules=($(_setdiff_ "${npmPackages[*]}" "${installed[*]}"))
    if ((${#modules[@]} > 0)); then
      pushd ${HOME} >/dev/null
      _execute_ -v "npm install -g ${modules[*]}"
      popd >/dev/null
    else
      info "All node packages already installed"
    fi
  }
  _node_ "$configNode"

  _ruby_() {
    local RUBYVERSION
    local gem
    local testInstalled
    local t="${tmpDir}/${RANDOM}.${RANDOM}.${RANDOM}.txt"
    local c="$1" # Config YAML file

    if ! _seekConfirmation_ "Install Ruby, RVM, and Gems?"; then return; fi
    header "Installing ruby"

    [ ! -f "$c" ] \
      && {
        error "Can not find config file '$c'"
        return 1
      }

    # Parse & source Config File
    # shellcheck disable=2015
    (_parseYAML_ "${c}" >"${t}") \
      && { if $verbose; then
        verbose "-- Config Variables"
        _readFile_ "$t"
      fi; } \
      || die "Could not parse YAML config file"

    _sourceFile_ "$t"

    RUBYVERSION="2.3.4" # Version of Ruby to install via RVM

    # Install 2 packages used to fix broken rmagick gem
    _execute_ -v "sudo apt-get install -y libmagickcore-dev"
    _execute_ -v "sudo apt-get install -y libmagickwand-dev"

    if ! command -v rvm &>/dev/null; then
      pushd "${HOME}"
      _execute_ -v "curl -sSL https://get.rvm.io | bash -s stable"
      export PATH="${PATH}:${HOME}/.rvm/bin"
      _execute_ "source ${HOME}/.rvm/scripts/rvm"
      _execute_ "source ${HOME}/.bash_profile"
      _execute_ -v "rvm install ${RUBYVERSION}"
      _execute_ -v "rvm use ${RUBYVERSION} --default"
    fi

    header "Installing global ruby gems..."

    # shellcheck disable=2154
    for gem in "${rubyGems[@]}"; do
      # Strip comments
      gem=$(echo "$gem" | cut -d'#' -f1 | _trim_)

      # strip flags from package names
      testInstalled=$(echo "$gem" | cut -d' ' -f1 | _trim_)

      if ! gem list "$testInstalled" -i >/dev/null; then
        _execute_ -v "gem install ${gem}"
      else
        info "${testInstalled} already installed"
      fi
    done

    popd
  }
  _ruby_ "$configRuby"

  _runPlugins_() {
    local plugin pluginName flags v d

    header "Running plugin scripts"

    if [ ! -d "$pluginScripts" ]; then
      error "Can't find plugins." "$LINENO"
      return 1
    fi

    # Run the bootstrap scripts in numerical order
    for plugin in ${pluginScripts}/*.sh; do
      pluginName="$(basename ${plugin})"
      pluginName="$(echo $pluginName | sed -e 's/[0-9][0-9]-//g' | sed -e 's/-/ /g' | sed -e 's/\.sh//g')"
      if _seekConfirmation_ "Run '${pluginName}' plugin?"; then

        #Build flags
        [ -n "${scriptFlags[*]}" ] \
          && flags="${scriptFlags[*]}"
        [[ "$flags" =~ (--verbose|v) ]] \
          || flags="${flags} --verbose"
        ($dryrun) && {
          d=true
          dryrun=false
        }
        flags="${flags} --rootDIR $rootDIR"

        _execute_ -vsp "${plugin} ${flags}" "'${pluginName}' plugin"

        ($d) && dryrun=true
      fi
    done
  }
  _runPlugins_

} # end _mainScript_

# ### CUSTOM FUNCTIONS ###########################

_doSymlinks_() {
  # Takes an input of a configuration YAML file and creates symlinks from it.
  # Note that the YAML file must group symlinks in a section named 'symlinks'
  local l                                 # link
  local d                                 # destination
  local s                                 # source
  local c="${1:?Must have a config file}" # config file
  local line
  local t="${tmpDir}/${RANDOM}.${RANDOM}.${RANDOM}.txt"

  [ ! -f "$c" ] \
    && {
      error "Can not find config file '$c'"
      return 1
    }

  # Parse & source Config File
  # shellcheck disable=2015
  (_parseYAML_ "${c}" >"${t}") \
    && { if $verbose; then
      verbose "-- Config Variables"
      _readFile_ "$t"
    fi; } \
    || die "Could not parse YAML config file"

  _sourceFile_ "$t"

  [ "${#symlinks[@]}" -eq 0 ] \
    && {
      warning "No symlinks found in '$c'"
      return 1
    }

  # For each link do the following
  for l in "${symlinks[@]}"; do
    verbose "Working on: $l"

    # Parse destination and source
    d=$(echo "$l" | cut -d':' -f1 | _trim_)
    s=$(echo "$l" | cut -d':' -f2 | _trim_)
    s=$(echo "$s" | cut -d'#' -f1 | _trim_) # remove comments if exist

    # Add the rootDIR to source if it exists
    [ -n "$rootDIR" ] \
      && s="${rootDIR}/${s}"

    # Grab the absolute path for the source
    s="$(_realpath_ "${s}")"

    # Skip macOS specific files
    [[ "$s" =~ xld|Library|mailReIndex ]] \
      && continue

    # If we can't find a source file, skip it
    [ ! -e "${s}" ] \
      && {
        warning "Can't find source '${s}'"
        continue
      }

    (_makeSymlink_ "${s}" "${d}") \
      || {
        warning "_makeSymlink_ failed for source: '$s'"
        return 1
      }

  done
}

# Set Base Variables
# ----------------------
scriptName=$(basename "$0")

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
tmpDir="/tmp/${scriptName}.$RANDOM.$RANDOM.$RANDOM.$$"
(umask 077 && mkdir "${tmpDir}") || {
  die "Could not create temporary directory! Exiting."
}

_sourceHelperFiles_() {
  local filesToSource
  local sourceFile

  filesToSource=(
    "${HOME}/dotfiles/scripting/helpers/baseHelpers.bash"
    "${HOME}/dotfiles/scripting/helpers/files.bash"
    "${HOME}/dotfiles/scripting/helpers/arrays.bash"
    "${HOME}/dotfiles/scripting/helpers/textProcessing.bash"
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

# Options and Usage
# -----------------------------------
_usage_() {
  echo -n "${scriptName} [OPTION]... [FILE]...

This is a script template.  Edit this description to print help to users.

 ${bold}Option Flags:${reset}

  -L, --noErrorLog  Print log level error and fatal to a log (default 'true')
  -l, --log         Print log to file
  -n, --dryrun      Non-destructive. Makes no permanent changes.
  -q, --quiet       Quiet (no output)
  -s, --strict      Exit script with null variables.  i.e 'set -o nounset'
  -v, --verbose     Output more information. (Items echoed to 'verbose')
  -d, --debug       Runs script in BASH debug mode (set -x)
  -h, --help        Display this help and exit
      --version     Output version information and exit
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
    --version)
      echo "$(basename $0) ${version}"
      _safeExit_
      ;;
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

# Exit on error. Append '||true' when you run the script if you expect an error.
set -o errexit
set -o errtrace

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
