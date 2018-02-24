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

  _apgradeAptGet_() {
    # Upgrade apt-get
    if [ -f "/etc/apt/sources.list" ]; then
      notice "Upgrading apt-get....(May take a while)"
      apt-get update
      apt-get upgrade -y
    else
      die "Can not proceed without apt-get"
    fi

    apt-get install -y git
    apt-get install -y mosh
    apt-get install -y sudo
    apt-get install -y ncurses
    apt-get install -y software-properties-common
    apt-get install -y python3-software-properties
    apt-get install -y python-software-properties

  }
  _apgradeAptGet_

  _setHostname_() {
    notice "Setting Hostname..."

    ipAddress=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')

    input "What is your hostname? [ENTER]: "
    read -r newHostname

    [ ! -n "$newHostname" ] && die "Hostname undefined"

    if command -v hostnamectl &>/dev/null; then
      _execute_ "hostnamectl set-hostname \"$newHostname\""
    else
      _execute_ "echo \"$newHostname\" > /etc/hostname"
      _execute_ "hostname -F /etc/hostname"
    fi

    _execute_ "echo \"$ipAddress\" \"$newHostname\" >> /etc/hosts"
  }
  _setHostname_

  _setTime_() {
    notice "Setting Time..."

    if command -v timedatectl &>/dev/null; then
      _execute_ "apt-get install -y ntp"
      _execute_ "timedatectl set-timezone \"America/New_York\""
      _execute_ "timedatectl set-ntp true"
    elif command -v dpkg-reconfigure; then
      dpkg-reconfigure tzdata
    else
      die "set time failed"
    fi
  }
  _setTime_

  _addUser_() {

    # Installs sudo if needed and creates a user in the sudo group.
    notice "Creating a new user account..."
    input "username? [ENTER]: "
    read -r USERNAME
    input "password? [ENTER]: "
    read -r -s USERPASS

    _execute_ "adduser ${USERNAME} --disabled-password --gecos \"\""
    _execute_ "echo \"${USERNAME}:${USERPASS}\" | chpasswd" "echo \"${USERNAME}:******\" | chpasswd"
    _execute_ "usermod -aG sudo ${USERNAME}"

    HOMEDIR="/home/${USERNAME}"
  }
  _addUser_

  _addPublicKey_() {
    # Adds the users public key to authorized_keys for the specified user. Make sure you wrap your input variables in double quotes, or the key may not load properly.

    if _seekConfirmation_ "Do you have a public key from another computer to add?"; then
      if [ ! -n "$USERNAME" ]; then
        die "We must have a user account configured..."
      fi

      input "paste your public key? [ENTER]: "
      read -r USERPUBKEY

      _execute_ "mkdir -p /home/${USERNAME}/.ssh"
      _execute_ "echo \"$USERPUBKEY\" >> /home/${USERNAME}/.ssh/authorized_keys"
      _execute_ "chown -R \"${USERNAME}\":\"${USERNAME}\" /home/${USERNAME}/.ssh"
    fi
  }
  _addPublicKey_

  _goodstuff_() {
    # Customize root terminal experience

    sed -i -e 's/^#PS1=/PS1=/' /root/.bashrc                          # enable the colorful root bash prompt
    sed -i -e "s/^#alias ll='ls -l'/alias ll='ls -al'/" /root/.bashrc # enable ll list long alias <3
    echo "alias ..='cd ..'" >>/root/.bashrc
  }
  _goodstuff_

  _installDotfiles_() {

    if command -v git &>/dev/null; then
      header "Installing dotfiles..."
      pushd "$HOMEDIR"
      git clone https://github.com/natelandau/dotfiles "${HOMEDIR}/dotfiles"
      chown -R $USERNAME:$USERNAME "${HOMEDIR}/dotfiles"
      popd
    else
      warning "Could not install dotfiles repo without git installed"
    fi
  }
  _installDotfiles_

  _ufwFirewall_() {
    header "Installing firewall with UFW"
    apt-get install -y ufw

    _execute_ "ufw default deny"
    _execute_ "ufw allow 'Nginx Full'"
    _execute_ "ufw allow ssh"
    _execute_ "ufw allow mosh"
    _execute_ "ufw enable"
  }
  _ufwFirewall_

  success "New computer bootstrapped."
  info "To continue you must log out as root and back in as the user you just"
  info "created. Once logged in you should see a 'dotfiles' folder in your user's home directory."
  info "Run the '~/dotfiles/bootstrap/install-linux-gnu.sh' script to continue"

  _disableRootSSH_() {
    notice "Disabling root access..."
    _execute_ "sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config"
    _execute_ "touch /tmp/restart-ssh"
    _execute_ "service ssh restart"
  }
  _disableRootSSH_

} # end _mainScript

_findBaseDir_() {
  #v1.0.0
  # fincBaseDir locates the real directory of the script being run. similar to GNU readlink -n
  # usage :  baseDir="$(_findBaseDir_)"
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

_execute_() {
  # v1.1.0
  # _execute_ Wrap an external command in '_execute_' to push native output to /dev/null
  #           and have control over the display of the results.
  #
  #           If $dryrun=true no commands are executed
  #           If $verbose=true the command's native output is printed to stderr and stdin
  #
  #
  #
  #
  #
  #           options:
  #             -v    Always print verbose output from the execute function
  #             -p    Pass a failed command with 'return 0'.  This effecively bypasses set -e.
  #             -e    Bypass _alert_ functions and use 'echo RESULT'
  #             -s    Use _alert_ success for successful output. (default is 'notice')
  #
  # usage:
  #   _execute_ "cp -R \"~/dir/somefile.txt\" \"someNewFile.txt\"" "Optional message to print to user"

  local localVerbose=false
  local passFailures=false
  local echoResult=false
  local successResult=false
  local opt

  local OPTIND=1
  while getopts ":vVpPeEsS" opt; do
    case $opt in
      v | V) localVerbose=true ;;
      p | P) passFailures=true ;;
      e | E) echoResult=true ;;
      s | S) successResult=true ;;
      *) {
        error "Unrecognized option '$1' passed to _execute. Exiting."
        _safeExit_
      }
        ;;
    esac
  done
  shift $((OPTIND - 1))

  local cmd="${1:?_execute_ needs a command}"
  local message="${2:-$1}"

  local saveVerbose=$verbose
  if "${localVerbose}"; then
    verbose=true
  fi

  if "${dryrun}"; then
    if [ -n "$2" ]; then
      dryrun "${1} (${2})" }
    else
      dryrun "${1}"
    fi
  elif ${verbose}; then
    if eval "${cmd}"; then
      if "$echoResult"; then
        echo "${message}"
      elif "${successResult}"; then
        success "${message}"
      else
        notice "${message}"
      fi
      verbose=$saveVerbose
      return 0
    else
      if "$echoResult"; then
        echo "error: ${message}"
      else
        warning "${message}"
      fi
      verbose=$saveVerbose
      "${passFailures}" && return 0 || return 1
    fi
  else
    if eval "${cmd}" &>/dev/null; then
      if "$echoResult"; then
        echo "${message}"
      elif "${successResult}"; then
        success "${message}"
      else
        notice "${message}"
      fi
      verbose=$saveVerbose
      return 0
    else
      if "$echoResult"; then
        echo "error: ${message}"
      else
        warning "${message}"
      fi
      verbose=$saveVerbose
      "${passFailures}" && return 0 || return 1
    fi
  fi
}

_seekConfirmation_() {
  # v1.0.1
  # Seeks a Yes or No answer to a question.  Usage:
  #   if _seekConfirmation_ "Answer this question"; then
  #     something
  #   fi

  input "$@"
  if "${force}"; then
    verbose "Forcing confirmation with '--force' flag set"
    echo -e ""
    return 0
  else
    while true; do
      read -r -p " (y/n) " yn
      case $yn in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        *) input "Please answer yes or no." ;;
      esac
    done
  fi
}

_safeExit_() {
  # Delete temp files with option to save if error is trapped
  # To exit the script with a non-zero exit code pass the requested code
  # to this function as an argument
  #
  #   Usage:    _safeExit_ "1"
  if [[ -n "${tmpDir}" && -d "${tmpDir}" ]]; then
    if [[ $1 == 1 && -n "$(ls "${tmpDir}")" ]]; then
      if _seekConfirmation_ "Save the temp directory for debugging?"; then
        cp -r "${tmpDir}" "${tmpDir}.save"
        notice "'${tmpDir}.save' created"
      fi
      rm -r "${tmpDir}"
    else
      rm -r "${tmpDir}"
    fi
  fi

  trap - INT TERM EXIT
  exit ${1:-0}
}

_trapCleanup_() {
  local line=$1 # LINENO
  local linecallfunc=$2
  local command="$3"
  local funcstack="$4"
  local script="$5"
  local sourced="$6"
  local scriptSpecific="$7"

  funcstack="'$(echo "$funcstack" | sed -E 's/ / < /g')'"

  #fatal "line $line - command '$command' $func"
  if [[ "${script##*/}" == "${sourced##*/}" ]]; then
    fatal "${7} command: '$command' (line: $line) (func: ${funcstack})"
  else
    fatal "${7} command: '$command' (func: ${funcstack} called at line $linecallfunc of '${script##*/}') (line: $line of '${sourced##*/}') "
  fi

  _safeExit_ "1"
}

# Set Base Variables
# ----------------------
scriptName=$(basename "$0")

# Set Flags
quiet=false
printLog=false
logErrors=false
verbose=false
force=false
strict=false
dryrun=false
debug=false
sourceOnly=false
args=()

if tput setaf 1 &>/dev/null; then
  bold=$(tput bold)
  reset=$(tput sgr0)
  purple=$(tput setaf 171)
  red=$(tput setaf 1)
  green=$(tput setaf 76)
  tan=$(tput setaf 3)
  blue=$(tput setaf 38)
  underline=$(tput sgr 0 1)
else
  bold=""
  reset="\033[m"
  purple="\033[1;31m"
  red="\033[0;31m"
  green="\033[1;32m"
  tan="\033[0;33m"
  blue="\033[0;34m"
  underline=""
fi

### ALERTS AND LOGGING ###

_alert_() {
  # v1.1.0

  local scriptName logLocation logName function_name color alertType line
  alertType="$1"
  line="${2}"

  scriptName=$(basename "$0")
  logLocation="${HOME}/logs"
  logName="${scriptName%.sh}.log"

  if [ -z "$logFile" ]; then
    [ ! -d "$logLocation" ] && mkdir -p "$logLocation"
    logFile="${logLocation}/${logName}"
  fi

  function_name="func: $(echo "$(
    IFS="<"
    echo "${FUNCNAME[*]:2}"
  )" | sed -E 's/</ < /g')"

  if [ -z "$line" ]; then
    [[ "$1" =~ ^(fatal|error|debug) && "${FUNCNAME[2]}" != "_trapCleanup_" ]] \
      && _message="$_message ($function_name)"
  else
    [[ "$1" =~ ^(fatal|error|debug) && "${FUNCNAME[2]}" != "_trapCleanup_" ]] \
      && _message="$_message (line: $line) ($function_name)"
  fi

  [ "${alertType}" = "error" ] && color="${bold}${red}"
  [ "${alertType}" = "fatal" ] && color="${bold}${red}"
  [ "${alertType}" = "warning" ] && color="${red}"
  [ "${alertType}" = "success" ] && color="${green}"
  [ "${alertType}" = "debug" ] && color="${purple}"
  [ "${alertType}" = "header" ] && color="${bold}${tan}"
  [ "${alertType}" = "input" ] && color="${bold}"
  [ "${alertType}" = "dryrun" ] && color="${blue}"
  [ "${alertType}" = "info" ] && color=""
  [ "${alertType}" = "notice" ] && color=""

  # Don't use colors on pipes or non-recognized terminals
  if [[ "${TERM}" != "xterm"* ]] || [ -t 1 ]; then
    color=""
    reset=""
  fi

  # Print to console when script is not 'quiet'
  _writeToScreen_() {
    ("$quiet") \
      && {
        tput cuu1
        return
      } # tput cuu1 moves cursor up one line

    echo -e "$(date +"%r") ${color}$(printf "[%7s]" "${1}") ${_message}${reset}"
  }
  _writeToScreen_ "$1"

  # Print to Logfile
  if "${printLog}"; then
    [[ "$alertType" =~ ^(input|dryrun|debug) ]] && return
    [ ! -f "$logFile" ] && touch "$logFile"
    color=""
    reset="" # Don't use colors in logs
    echo -e "$(date +"%b %d %R:%S") $(printf "[%7s]" "${1}") ${_message}" >>"${logFile}"
  elif [[ "${logErrors}" == "true" && "$alertType" =~ ^(error|fatal) ]]; then
    [ ! -f "$logFile" ] && touch "$logFile"
    color=""
    reset="" # Don't use colors in logs
    echo -e "$(date +"%b %d %R:%S") $(printf "[%7s]" "${1}") ${_message}" >>"${logFile}"
  else
    return 0
  fi
}
die() {
  local _message="${1}"
  echo -e "$(_alert_ fatal $2)"
  _safeExit_ "1"
}
fatal() {
  local _message="${1}"
  echo -e "$(_alert_ fatal $2)"
  _safeExit_ "1"
}
trapped() {
  local _message="${1}"
  echo -e "$(_alert_ trapped $2)"
  _safeExit_ "1"
}
error() {
  local _message="${1}"
  echo -e "$(_alert_ error $2)"
}
warning() {
  local _message="${1}"
  echo -e "$(_alert_ warning $2)"
}
notice() {
  local _message="${1}"
  echo -e "$(_alert_ notice $2)"
}
info() {
  local _message="${1}"
  echo -e "$(_alert_ info $2)"
}
debug() {
  local _message="${1}"
  echo -e "$(_alert_ debug $2)"
}
success() {
  local _message="${1}"
  echo -e "$(_alert_ success $2)"
}
dryrun() {
  local _message="${1}"
  echo -e "$(_alert_ dryrun $2)"
}
input() {
  local _message="${1}"
  echo -n "$(_alert_ input $2)"
}
header() {
  local _message="== ${*} ==  "
  echo -e "$(_alert_ header $2)"
}
verbose() {
  ($verbose) \
    && {
      local _message="${1}"
      echo -e "$(_alert_ debug $2)"
    } \
    || return 0
}

# Options and Usage
# -----------------------------------
_usage_() {
  echo -n "${scriptName} [OPTION]... [FILE]...

This script runs a series of installation scripts to bootstrap a new computer or VM running Debian GNU linux

 ${bold}Options:${reset}

  -n, --dryrun      Non-destructive. Makes no permanent changes.
  -q, --quiet       Quiet (no output)
  -l, --log         Print log to file
  -s, --strict      Exit script with null variables.  i.e 'set -o nounset'
  -v, --verbose     Output more information. (Items echoed to 'verbose')
  -d, --debug       Runs script in BASH debug mode (set -x)
  -h, --help        Display this help and exit
      --source-only Bypasses main script functionality to allow unit tests of functions
      --version     Output version information and exit
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

# Exit on error. Append '||true' to a command when you run the script if you expect an error.
set -o errtrace
set -o errexit

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
