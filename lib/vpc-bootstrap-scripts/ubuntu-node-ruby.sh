#! /bin/bash
#
# <UDF name="HOSTNAME" Label="Hostname of this Linode" />
# <UDF name="USERNAME" Label="Main user name" />
# <UDF name="PASSWORD" Label="Main user password" />
# <UDF name="SSHKEY"  Label="Main user RSA SSH key" />
# <UDF name="NODEVERSION" Label="Node.js version" default="8.1.3" />
# <UDF name="RUBYVERSION" Label="Ruby version" default="2.3.4" />
#
# If not deploying to Linode, set these environment variables. All required:
#   - HOSTNAME
#   - USERNAME
#   - PASSWORD
#   - SSHKEY
#   - NODEVERSION
#   - RUBYVERSION

_mainScript_() {

  # Variables
  #shellcheck disable=2153
  HOMEDIR="/home/${USERNAME}"
  IPADDRESS=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')

  # Update
  apt-get update
  apt-get upgrade -y
  apt-get -y install git bzip2 unzip


  _createGemrc_() {
    cat > "${HOMEDIR}/.gemrc" << EOF
verbose: true
bulk_treshold: 1000
install: --no-ri --no-rdoc --env-shebang
benchmark: false
backtrace: false
update: --no-ri --no-rdoc --env-shebang
update_sources: true
EOF

    chown $USERNAME:$USERNAME "${HOMEDIR}/.gemrc";
  }

  _setHostname_() {
    header "Setting hostname..."

    if [ -z "$HOSTNAME" ]; then
      warning "Hostname undefined"
      return 1;
    fi

    if command -v hostnamectl &>/dev/null; then
      hostnamectl set-hostname "$HOSTNAME"
    else
      echo "$HOSTNAME" > /etc/hostname
      hostname -F /etc/hostname
    fi

    echo "$IPADDRESS" "$HOSTNAME" >> /etc/hosts
  }
  _setHostname_

  _setTime_() {
    header "Setting time..."
    if command -v timedatectl &> /dev/null; then
      apt-get install -y ntp
      timedatectl set-timezone "America/New_York"
      timedatectl set-ntp true
    else
      warning "Set Time Failed"
      return 1;
    fi
  }
  _setTime_

  _addUser_() {
    header "Adding user..."

    if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
      warning "USERNAME or PASSWORD undefined"
      return 1;
    fi

    adduser "$USERNAME" --disabled-password --gecos ""
    echo "$USERNAME:$PASSWORD" | chpasswd
    usermod -aG sudo "$USERNAME"
  }
  _addUser_

  _addPublicKey_() {
    header "Adding public key"
    # Adds the users public key to authorized_keys for the specified user. Make sure you wrap your input variables in double quotes, or the key may not load properly.

    if [ -z "$SSHKEY" ]; then
      warning "SSHKEY undefined"
      return 1;
    fi

      mkdir -p "${HOMEDIR}/.ssh"
      echo "$SSHKEY" >> "${HOMEDIR}/.ssh/authorized_keys"
      chown -R $USERNAME:$USERNAME "${HOMEDIR}/.ssh"
  }
  _addPublicKey_

  _installPackages_ () {
    header "Installing apt-get packages..."

    packagesToInstall=(
      autojump
      bats
      colordiff
      coreutils
      default-jre
      git-extras
      httpie
      imagemagick
      jpegoptim
      jq
      less
      mosh
      ngrok-server
      ngrok-client
      optipng
      pngcrush
      shellcheck
      source-highlight
      thefuck
      tree
      wget
      )
    for package in "${packagesToInstall[@]}"; do
      _execute_ "apt-get install -y $package"
    done
  }
  _installPackages_

  _installRuby_() {

    header "Installing Ruby..."

    # Install 2 packages used to fix broken rmagick gem
    _execute_ "apt-get install -y libmagickcore-dev"
    _execute_ "apt-get install -y libmagickwand-dev"

    pushd "$HOMEDIR";
    su $USERNAME -s /bin/bash -l -c "\curl -sSL https://get.rvm.io | bash -s stable"
    export PATH="$PATH:${HOMEDIR}/.rvm/bin"
    source "${HOMEDIR}/.rvm/scripts/rvm"
    rvm install "${RUBYVERSION}";
    rvm use ${RUBYVERSION} --default;
    chown -R $USERNAME:$USERNAME .rvm;
    _createGemrc_
    su $USERNAME -s /bin/bash -l -c "gem install bundler ghi jekyll rake yaml-lint";
    popd;
  }
  _installRuby_

  _installNode_() {
    apt-get install -y build-essential libssl-dev checkinstall

    # nvm & node
    pushd "$HOMEDIR";
    git clone git://github.com/creationix/nvm.git "${HOMEDIR}/.nvm";
    touch "${HOMEDIR}/.bash_profile"
    echo ". ~/.nvm/nvm.sh" >> "${HOMEDIR}/.bash_profile"
    echo "nvm use $NODEVERSION" >> "${HOMEDIR}/.bash_profile"
    echo "Installed nvm"
    . "${HOMEDIR}/.nvm/nvm.sh";
    nvm install "$NODEVERSION";
    nvm use "$NODEVERSION";
    echo "Installed nodejs"
    chown -R $USERNAME:$USERNAME "${HOMEDIR}/.nvm";
    su $USERNAME -s /bin/bash -l -c "npm install -g lessmd";
    popd;
  }
  _installNode_

  _installDotfiles_() {
    header "Installing dotfiles..."
    pushd "$HOMEDIR";
    git clone https://github.com/natelandau/dotfiles "${HOMEDIR}/dotfiles"
    chown -R $USERNAME:$USERNAME "${HOMEDIR}/dotfiles"
    popd;
  }
  _installDotfiles_


  _installNGIX_() {
    header "installing ngix"
    _execute_ "sudo apt-get install nginx"

    mkdir -p /var/www/dev/html
    mkdir -p /var/www/stage/html
    mkdir -p /var/www/prod/html
    chown -R $USERNAME:$USERNAME /var/www/dev/html
    chown -R $USERNAME:$USERNAME /var/www/stage/html
    chown -R $USERNAME:$USERNAME /var/www/prod/html
    chmod -R 755 /var/www

    cp /etc/nginx/sites-available/default /etc/nginx/sites-available/dev

  }

  _ufwFirewall_() {
    header "Installing firwall with UFW"
    _execute_ "sudo apt-get install ufw"

    ufw default deny
    ufw allow 'Nginx Full'
    ufw allow ssh
    ufw allow mosh
    ufw enable
  }
  _ufwFirewall_

  _iptablesFirewall_() {
    header "Creating firewall"

    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A INPUT -i lo -m comment --comment "Allow loopback connections" -j ACCEPT
    iptables -A INPUT ! -i lo -s 127.0.0.0/8 -j REJECT
    iptables -A INPUT -p icmp -m comment --comment "Allow Ping to work as expected" -j ACCEPT
    iptables -A INPUT -p tcp -m multiport --destination-ports 22,25,53,80,443,465,5222,5269,5280,8080,8888,8999:9003 -j ACCEPT
    iptables -A INPUT -p udp -m multiport --destination-ports 53,22,60000:61000 -j ACCEPT
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
  }
  #_iptablesFirewall_

  _goodstuff_() {
    # Enables color root prompt and the "ll" list long alias
    sed -i 's/^#PS1=/PS1=/' /root/.bashrc # enable the colorful root bash prompt
    sed -i "s/^#alias ll='ls -l'/alias ll='ls -al'/" /root/.bashrc # enable ll list long alias <3
  }
  _goodstuff_

  _lockThingsDown_() {
    sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    #sed -i 's/\#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    service ssh restart
  }
  _lockThingsDown_

  success "Yay! All done."

}

_trapCleanup_() {
  echo ""
  # Delete temp files, if any
  [ -d "${tmpDir}" ] && rm -r "${tmpDir}"
  die "Exit trapped. In function: '${FUNCNAME[*]:1}'"
}

_safeExit_() {
  # Delete temp files, if any
  [ -d "${tmpDir}" ] && rm -r "${tmpDir}"
  trap - INT TERM EXIT
  exit ${1:-0}
}

# Set Base Variables
# ----------------------
scriptName=$(basename "$0")

# Set Flags
quiet=false;              printLog=false;             verbose=false;
force=false;              strict=false;               dryrun=false;
debug=false;              sourceOnly=false;           args=();

# Set Colors
bold=$(tput bold);        reset=$(tput sgr0);         purple=$(tput setaf 171);
red=$(tput setaf 1);      green=$(tput setaf 76);     tan=$(tput setaf 3);
blue=$(tput setaf 38);    underline=$(tput sgr 0 1);

# Set Temp Directory
tmpDir="/tmp/${scriptName}.$RANDOM.$RANDOM.$RANDOM.$$"
(umask 077 && mkdir "${tmpDir}") || {
  die "Could not create temporary directory! Exiting."
}

# Logging & Feedback
logFile="${HOME}/Library/Logs/${scriptName%.sh}.log"

_alert_() {
  # v1.0.0
  if [ "${1}" = "error" ]; then local color="${bold}${red}"; fi
  if [ "${1}" = "warning" ]; then local color="${red}"; fi
  if [ "${1}" = "success" ]; then local color="${green}"; fi
  if [ "${1}" = "debug" ]; then local color="${purple}"; fi
  if [ "${1}" = "header" ]; then local color="${bold}${tan}"; fi
  if [ "${1}" = "input" ]; then local color="${bold}"; fi
  if [ "${1}" = "dryrun" ]; then local color="${blue}"; fi
  if [ "${1}" = "info" ] || [ "${1}" = "notice" ]; then local color=""; fi
  # Don't use colors on pipes or non-recognized terminals
  if [[ "${TERM}" != "xterm"* ]] || [ -t 1 ]; then color=""; reset=""; fi

  # Print to console when script is not 'quiet'
  if ${quiet}; then tput cuu1 ; return; else # tput cuu1 moves cursor up one line
   echo -e "$(date +"%r") ${color}$(printf "[%7s]" "${1}") ${_message}${reset}";
  fi

  # Print to Logfile
  if ${printLog} && [ "${1}" != "input" ]; then
    color=""; reset="" # Don't use colors in logs
    echo -e "$(date +"%m-%d-%Y %r") $(printf "[%7s]" "${1}") ${_message}" >> "${logFile}";
  fi
}

function die ()       { local _message="${*} Exiting."; echo -e "$(_alert_ error)"; _safeExit_ "1";}
function error ()     { local _message="${*}"; echo -e "$(_alert_ error)"; }
function warning ()   { local _message="${*}"; echo -e "$(_alert_ warning)"; }
function notice ()    { local _message="${*}"; echo -e "$(_alert_ notice)"; }
function info ()      { local _message="${*}"; echo -e "$(_alert_ info)"; }
function debug ()     { local _message="${*}"; echo -e "$(_alert_ debug)"; }
function success ()   { local _message="${*}"; echo -e "$(_alert_ success)"; }
function dryrun()     { local _message="${*}"; echo -e "$(_alert_ dryrun)"; }
function input()      { local _message="${*}"; echo -n "$(_alert_ input)"; }
function header()     { local _message="== ${*} ==  "; echo -e "$(_alert_ header)"; }
function verbose()    { if ${verbose}; then debug "$@"; fi }

_seekConfirmation_() {
  # v1.0.1

  input "$@"
  if "${force}"; then
    verbose "Forcing confirmation with '--force' flag set"
    echo -e ""
    return 0
  else
    while true; do
      read -r -p " (y/n) " yn
      case $yn in
        [Yy]* ) return 0;;
        [Nn]* ) return 1;;
        * ) input "Please answer yes or no.";;
      esac
    done
  fi
}

_execute_() {
  # v1.0.1
  # _execute_ - wrap an external command in '_execute_' to push native output to /dev/null
  #           and have control over the display of the results.  In "dryrun" mode these
  #           commands are not executed at all. In Verbose mode, the commands are executed
  #           with results printed to stderr and stdin
  #
  # usage:
  #   _execute_ "cp -R \"~/dir/somefile.txt\" \"someNewFile.txt\"" "Optional message to print to user"
  local cmd="${1:?_execute_ needs a command}"
  local message="${2:-$1}"
  if ${dryrun}; then
    dryrun "${message}"
  else
    if $verbose; then
      eval "$cmd"
    else
      eval "$cmd" &> /dev/null
    fi
    if [ $? -eq 0 ]; then
      success "${message}"
    else
      error "${message}"
      #die "${message}"
    fi
  fi
}

_pauseScript_() {
  # v1.0.0
  # A simple function used to pause a script at any point and
  # only continue on user input
  if _seekConfirmation_ "Ready to continue?"; then
    notice "Continuing..."
  else
    warning "Exiting Script"
    _safeExit_
  fi
}

# Options and Usage
# -----------------------------------
_usage_() {
  echo -n "${scriptName} [OPTION]... [FILE]...

This is a script template.  Edit this description to print help to users.

 ${bold}Options:${reset}
  -u, --username    Username for script
  -p, --password    User password
  -n, --dryrun      Non-destructive. Makes no permanent changes.
  -q, --quiet       Quiet (no output)
  -l, --log         Print log to file
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
      for ((i=1; i < ${#1}; i++)); do
        c=${1:i:1}

        # Add current char to options
        options+=("-$c")

        # If option takes a required argument, and it's not the last char make
        # the rest of the string its argument
        if [[ $optstring = *"$c:"* && ${1:i+1} ]]; then
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
while [[ $1 = -?* ]]; do
  case $1 in
    -h|--help) _usage_ >&2; _safeExit_ ;;
    -u|--username) shift; username=${1} ;;
    -p|--password) shift; echo "Enter Pass: "; stty -echo; read -r PASS; stty echo;
      echo ;;
    -n|--dryrun) dryrun=true ;;
    -v|--verbose) verbose=true ;;
    -l|--log) printLog=true ;;
    -q|--quiet) quiet=true ;;
    -s|--strict) strict=true;;
    -d|--debug) debug=true;;
    --version) echo "$(basename $0) ${version}"; _safeExit_ ;;
    --source-only) sourceOnly=true;;
    --force) force=true ;;
    --endopts) shift; break ;;
    *) die "invalid option: '$1'." ;;
  esac
  shift
done

# Store the remaining part as arguments.
args+=("$@")

# Trap bad exits with your cleanup function
trap _trapCleanup_ EXIT INT TERM

# Set IFS to preferred implementation
IFS=$' \n\t'

# Exit on error. Append '||true' when you run the script if you expect an error.
# if using the 'execute' function this must be disabled for warnings to be shown if tasks fail
#set -o errexit

# Force pipelines to fail on the first non-zero status code.
set -o pipefail

# Run in debug mode, if set
if ${debug}; then set -x ; fi

# Exit on empty variable
if ${strict}; then set -o nounset ; fi

# Exit the script if a command fails
#set -e

# Run your script unless in 'source-only' mode
if ! ${sourceOnly}; then _mainScript_; fi

# Exit cleanly
if ! ${sourceOnly}; then _safeExit_; fi
