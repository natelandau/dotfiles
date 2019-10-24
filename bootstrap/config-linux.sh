#!/usr/bin/env bash

_mainScript_() {

  [[ "${OSTYPE}" =~ linux-gnu* ]] || fatal "We are not on Linux"

  gitRoot="$(git rev-parse --show-toplevel 2>/dev/null)" \
    && verbose "gitRoot: ${gitRoot}"

  sudo -v    # Get privs upfront

  _upgradeAptGet_() {
    if ! _seekConfirmation_ "Update apt-get and Install Packages?"; then return; fi

    if [ -f "/etc/apt/sources.list" ]; then
      header "Upgrading apt-get....(May take a while)"
      _execute_ -v "sudo apt-get update"
      _execute_ -v "sudo apt-get upgrade -y"
    else
      fatal "Can not proceed without apt-get" ${LINENO}
    fi

    _execute_ -vp "sudo apt-get install -y autoconf"
    _execute_ -vp "sudo apt-get install -y autojump"
    _execute_ -vp "sudo apt-get install -y automake"
    _execute_ -vp "sudo apt-get install -y bzip2"
    _execute_ -vp "sudo apt-get install -y colordiff"
    _execute_ -vp "sudo apt-get install -y coreutils"
    _execute_ -vp "sudo apt-get install -y curl"
    _execute_ -vp "sudo apt-get install -y dnsutils"
    _execute_ -vp "sudo apt-get install -y git-extras"
    _execute_ -vp "sudo apt-get install -y git"
    _execute_ -vp "sudo apt-get install -y httpie"
    _execute_ -vp "sudo apt-get install -y jq"
    _execute_ -vp "sudo apt-get install -y less"
    _execute_ -vp "sudo apt-get install -y ncurses"
    _execute_ -vp "sudo apt-get install -y p7zip"
    _execute_ -vp "sudo apt-get install -y python-software-properties"
    _execute_ -vp "sudo apt-get install -y python3-software-properties"
    _execute_ -vp "sudo apt-get install -y shellcheck"
    _execute_ -vp "sudo apt-get install -y software-properties-common"
    _execute_ -vp "sudo apt-get install -y source-highlight"
    _execute_ -vp "sudo apt-get install -y sudo"
    _execute_ -vp "sudo apt-get install -y tree"
    _execute_ -vp "sudo apt-get install -y unzip"
    _execute_ -vp "sudo apt-get install -y wget"

    if ! _seekConfirmation_ "Install apt-get development packages?"; then return; fi
    _execute_ -vp "sudo apt-get install -y default-jre"
    _execute_ -vp "sudo apt-get install -y id3tool"
    _execute_ -vp "sudo apt-get install -y imagemagick"
    _execute_ -vp "sudo apt-get install -y jpegoptim"
    _execute_ -vp "sudo apt-get install -y optipng"
    _execute_ -vp "sudo apt-get install -y pngcrush"
    _execute_ -vp "sudo apt-get install -y python3-pip"
  }
  _upgradeAptGet_

  _setHostname_() {
    if ! _seekConfirmation_ "Set Hostname??"; then return; fi
    ipAddress=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')

    input "What is your hostname? [ENTER]: "
    read -r newHostname
    [ -z "${newHostname}" ] && fatal "Hostname undefined" ${LINENO}

    if command -v hostnamectl &>/dev/null; then
      _execute_ -v "hostnamectl set-hostname \"${newHostname}\""
    else
      _execute_ -v "echo \"${newHostname}\" > /etc/hostname"
      _execute_ -v "hostname -F /etc/hostname"
    fi

    _execute_ "echo \"${ipAddress}\" \"${newHostname}\" >> /etc/hosts"
  }
  _setHostname_

  _setTime_() {
    if ! _seekConfirmation_ "Set time?"; then return; fi

    if command -v timedatectl &>/dev/null; then
      _execute_ -v "sudo apt-get install -y ntp"
      _execute_ -v "timedatectl set-timezone \"America/New_York\""
      _execute_ -v "timedatectl set-ntp true"
    elif command -v dpkg-reconfigure; then
      dpkg-reconfigure tzdata
    else
      fatal "set time failed" ${LINENO}
    fi
  }
  _setTime_

  _addUser_() {
    if ! _seekConfirmation_ "Add user"; then return; fi

    input "username? [ENTER]: "
    read -r USERNAME
    input "password? [ENTER]: "
    read -r -s USERPASS

    _execute_ -v "adduser ${USERNAME} --disabled-password --gecos \"\""
    _execute_ -v "echo \"${USERNAME}:${USERPASS}\" | chpasswd" "echo \"${USERNAME}:******\" | chpasswd"
    _execute_ -v "usermod -aG sudo ${USERNAME}"

    HOMEDIR="/home/${USERNAME}"

    _addPublicKey_() {
      # Adds the users public key to authorized_keys for the specified user. Make sure you wrap your input variables in double quotes, or the key may not load properly.

      if _seekConfirmation_ "Do you have a public key from another computer to add?"; then
        if [ -z "${HOMEDIR}" ]; then
          fatal "We must have a user account and direcrtory configured..." $LINENO
        fi

        input "paste your public key? [ENTER]: "
        read -r USERPUBKEY

        _execute_ -v "mkdir -p \"${HOMEDIR}/.ssh\""
        _execute_ -v "echo \"${USERPUBKEY}\" >> \"${HOMEDIR}/.ssh/authorized_keys\""
        _execute_ -v "chown -R \"${USERNAME}\":\"${USERNAME}\" \"${HOMEDIR}/.ssh\""
      fi
    }
    _addPublicKey_

    if _seekConfirmation_ "Exit script and rerun as this new user?"; then
      info "Exiting.  Rerun this script after logging in."
      _safeExit_
    fi

    _installDotfiles_() {
      if ! _seekConfirmation_ "Install dotfiles in user directory"; then return; fi

      if command -v git &>/dev/null; then
        header "Installing dotfiles..."
        pushd "${HOMEDIR}"
        git clone https://github.com/natelandau/dotfiles "${HOMEDIR}/dotfiles"
        chown -R ${USERNAME}:${USERNAME} "${HOMEDIR}/dotfiles"
        popd
      else
        warning "Could not install dotfiles without git installed" $LINENO
      fi
    }
    _installDotfiles_

  }
  _addUser_

  _ufwFirewall_() {
    if ! _seekConfirmation_ "Install and configure UFW firewall?"; then return; fi
    _execute_ -v "sudo apt-get install -y ufw"

    _execute_ "ufw default deny"
    _execute_ "ufw allow 'Nginx Full'"
    _execute_ "ufw allow ssh"
    _execute_ "ufw allow mosh"
    _execute_ "ufw enable"
  }
  _ufwFirewall_

  _disableRootSSH_() {
    if ! _seekConfirmation_ "Disable root access?"; then return; fi
    notice "Disabling root access..."
    _execute_ -v "sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config"
    _execute_ -v "touch /tmp/restart-ssh"
    _execute_ -v "service ssh restart"
  }
  _disableRootSSH_

  _symlinks_() {
    # DESC:   Creates symlinks to dotfiles and custom scripts
    # ARGS:   None
    # OUTS:   None

    if _seekConfirmation_ "Create symlinks to dotfiles and custom scripts?"; then
      header "Creating Symlinks"

      # Dotfiles
      _makeSymlink_ "${gitRoot}/config/dotfiles/asdfrc"               "${HOME}/.asdfrc"
      _makeSymlink_ "${gitRoot}/config/dotfiles/bash_profile"         "${HOME}/.bash_profile"
      _makeSymlink_ "${gitRoot}/config/dotfiles/bashrc"               "${HOME}/.bashrc"
      _makeSymlink_ "${gitRoot}/config/dotfiles/curlrc"               "${HOME}/.curlrc"
      _makeSymlink_ "${gitRoot}/config/dotfiles/Gemfile"              "${HOME}/.Gemfile"
      _makeSymlink_ "${gitRoot}/config/dotfiles/gemrc"                "${HOME}/.gemrc"
      _makeSymlink_ "${gitRoot}/config/dotfiles/gitattributes"        "${HOME}/.gitattributes"
      _makeSymlink_ "${gitRoot}/config/dotfiles/gitconfig"            "${HOME}/.gitconfig"
      _makeSymlink_ "${gitRoot}/config/dotfiles/gitignore"            "${HOME}/.gitignore"
      _makeSymlink_ "${gitRoot}/config/dotfiles/hushlogin"            "${HOME}/.hushlogin"
      _makeSymlink_ "${gitRoot}/config/dotfiles/inputrc"              "${HOME}/.inputrc"
      _makeSymlink_ "${gitRoot}/config/dotfiles/micro/bindings.json"  "${HOME}/.config/micro/bindings.json"
      _makeSymlink_ "${gitRoot}/config/dotfiles/micro/settings.json"  "${HOME}/.config/micro/settings.json"
      _makeSymlink_ "${gitRoot}/config/dotfiles/profile"              "${HOME}/.profile"
      _makeSymlink_ "${gitRoot}/config/dotfiles/ruby-version"         "${HOME}/.ruby-version"
      _makeSymlink_ "${gitRoot}/config/dotfiles/sed"                  "${HOME}/.sed"
      _makeSymlink_ "${gitRoot}/config/dotfiles/zsh_plugins.txt"      "${HOME}/.zsh_plugins.txt"
      _makeSymlink_ "${gitRoot}/config/dotfiles/zshrc"                "${HOME}/.zshrc"

      # Custom Scripts
      _makeSymlink_ "${gitRoot}/bin/cleanFilenames"   "${HOME}/bin/cleanFilenames"
      _makeSymlink_ "${gitRoot}/bin/git-churn"        "${HOME}/bin/git-churn"
      _makeSymlink_ "${gitRoot}/bin/hashCheck.sh"     "${HOME}/bin/hashCheck"
      _makeSymlink_ "${gitRoot}/bin/lessfilter.sh"    "${HOME}/bin/lessfilter.sh"
      _makeSymlink_ "${gitRoot}/bin/newscript.sh"     "${HOME}/bin/newscript"
      _makeSymlink_ "${gitRoot}/bin/removeSymlink"    "${HOME}/bin/removeSymlink"
      _makeSymlink_ "${gitRoot}/bin/seconds"          "${HOME}/bin/seconds"
      _makeSymlink_ "${gitRoot}/bin/trash"            "${HOME}/bin/trash"
    fi
  }
  _symlinks_

  _generateKey_() {
    local EMAIL
    if [ ! -f "${HOME}/.ssh/id_rsa.pub" ]; then
      header "Generating public ssh key...."
      input "what is your email? [ENTER]: "
      read -r EMAIL
      ssh-keygen -t rsa -b 4096 -C "${EMAIL}"
    else
      success "Existing public key found..."
    fi
  }
  _generateKey_

  _installGitHooks_() {
    local hooksLocation="${gitRoot}/.hooks"

    [ -d "${hooksLocation}" ] \
      || {
        warning "Can't find hooks. Exiting."
        return
    }

    local h
    while read -r h; do
      h="$(basename ${h})"
      [[ -L "${gitRoot}/.git/hooks/${h%.sh}" ]] \
        || _makeSymlink_ -n "${hooksLocation}/${h}" "${gitRoot}/.git/hooks/${h%.sh}"
    done < <(find "${hooksLocation}" -name "*.sh" -type f -maxdepth 1 | sort)

  }
  _installGitHooks_

  _installBats_() {
    if ! _seekConfirmation_ "Install BATS shell script test framework?"; then return; fi

    if command -v bats &>/dev/null; then
      success "BATS installed"
      return
    fi

    if _execute_ -v "sudo add-apt-repository ppa:duggan/bats"; then
      _execute_ -v "sudo apt-get update"
      _execute_ -v "sudo apt-get install bats"
    else
      error "Could not install BATS. See documentation: https://github.com/sstephenson/bats"
    fi

    notice "If installing BATS failed see documentation here: https://github.com/sstephenson/bats"
  }
  _installBats_

  _installGitFriendly_() {
    if ! _seekConfirmation_ "Install Git Friendly?"; then return; fi
    if ! command -v pull &>/dev/null; then
      _installGitFriendly_() {

        # github.com/jamiew/git-friendly
        # the `push` command which copies the github compare URL to my clipboard is heaven
        bash < <(sudo curl https://raw.github.com/jamiew/git-friendly/master/install.sh)
      }
      _installGitFriendly_
    else
      success "'git-friendly' installed"
    fi
  }
  _installGitFriendly_

  _installZSH_() {
    if ! _seekConfirmation_ "Install zsh?"; then return; fi
    _execute_ -vp "sudo apt-get install -y zsh"
    _execute_ -vp "curl -sfL git.io/antibody | sudo sh -s - -b /usr/local/bin"

    if ! _seekConfirmation_ "Make zsh your default shell?"; then return; fi
    chsh -s "$(command -v zsh)"
  }
  _installZSH_

} # end _mainScript_

_sourceHelperFiles_() {
  # DESC: Sources script helper files
  local filesToSource
  local sourceFile
  filesToSource=(
    "${HOME}/dotfiles/scripting/helpers/baseHelpers.bash"
    "${HOME}/dotfiles/scripting/helpers/files.bash"
    "${HOME}/dotfiles/scripting/helpers/textProcessing.bash"
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

  ${bold}$(basename "$0") [OPTION]...${reset}

  Configures a new computer running linux.  Performs the following
  optional actions:

    * Symlink dotfiles
    * Generates a SSH key
    * Install apt-get and associated packages
    * Install BATs test framework
    * Install Git Friendly


  ${bold}Options:${reset}

    -h, --help        Display this help and exit
    -l, --log         Print log to file with all log levels
    -L, --noErrorLog  Default behavior is to print log level error and fatal to a log. Use
                      this flag to generate no log files at all.
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
set -o errtrace                           # Trap errors in subshells and functions
set -o errexit                            # Exit on error. Append '||true' if you expect an error
set -o pipefail                           # Use last non-zero exit code in a pipeline
shopt -s nullglob globstar                # Make `for f in *.txt` work when `*.txt` matches zero files
IFS=$' \n\t'                              # Set IFS to preferred implementation
# set -o xtrace                           # Run in debug mode
#set -o nounset                           # Disallow expansion of unset variables
# [[ $# -eq 0 ]] && _parseOptions_ "-h"   # Force arguments when invoking the script
_parseOptions_ "$@"                       # Parse arguments passed to script
# _makeTempDir_ "$(basename "$0")"        # Create a temp directory '$tmpDir'
_acquireScriptLock_                       # Acquire script lock
_mainScript_                              # Run script unless in 'source-only' mode
_safeExit_                                # Exit cleanly