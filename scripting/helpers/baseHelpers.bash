### VARIABLES ###

now=$(LC_ALL=C date +"%m-%d-%Y %r")                     # Returns: 06-14-2015 10:34:40 PM
datestamp=$(LC_ALL=C date +%Y-%m-%d)                    # Returns: 2015-06-14
hourstamp=$(LC_ALL=C date +%r)                          # Returns: 10:34:40 PM
timestamp=$(LC_ALL=C date +%Y%m%d_%H%M%S)               # Returns: 20150614_223440
today=$(LC_ALL=C date +"%m-%d-%Y")                      # Returns: 06-14-2015
longdate=$(LC_ALL=C date +"%a, %d %b %Y %H:%M:%S %z")   # Returns: Sun, 10 Jan 2016 20:47:53 -0500
gmtdate=$(LC_ALL=C date -u -R | sed 's/\+0000/GMT/')    # Returns: Wed, 13 Jan 2016 15:55:29 GMT

bold=$(tput bold);        reset=$(tput sgr0);         purple=$(tput setaf 171);
red=$(tput setaf 1);      green=$(tput setaf 76);     tan=$(tput setaf 3);
blue=$(tput setaf 38);    underline=$(tput sgr 0 1);

### ALERTS AND LOGGING ###

_alert_() {
  # v1.1.0

  local scriptName logLocation logName logFile function_name

  scriptName=$(basename "$0")
  logLocation="${HOME}/logs"
  logName="${scriptName%.sh}.log"
  logFile="${logLocation}/${logName}"
  function_name=$(IFS="\\"; echo "${FUNCNAME[*]:3}")

  if [[ "$1" =~ ^(fatal|error|warning|debug) ]]; then
    _message="$_message ($function_name)"
  fi

  if [ "${1}" = "error" ]; then local color="${bold}${red}"; fi
  if [ "${1}" = "fatal" ]; then local color="${bold}${red}"; fi
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
  _writeToScreen_() {
    ( "$quiet" ) \
      && { tput cuu1; return; }  # tput cuu1 moves cursor up one line

     echo -e "$(date +"%r") ${color}$(printf "[%7s]" "${1}") ${_message}${reset}";
  }
  _writeToScreen_ "$1"

  # Print to Logfile
  if ${printLog}; then
    [[ "$1" =~ ^(input|dryrun|header|debug) ]] && return
    [ ! -d "$logLocation" ] && mkdir -p "$logLocation"
    [ ! -f "$logFile" ] && touch "$logFile"
    color=""; reset="" # Don't use colors in logs
    echo -e "$(date +"%b %d %R:%S") $(printf "[%7s]" "${1}") ${_message}" >> "${logFile}";
  fi
}

die ()       { local _message="${*}"; echo -e "$(_alert_ fatal)"; _safeExit_ "1";}
fatal ()     { local _message="${*}"; echo -e "$(_alert_ fatal)"; _safeExit_ "1";}
error ()     { local _message="${*}"; echo -e "$(_alert_ error)"; }
warning ()   { local _message="${*}"; echo -e "$(_alert_ warning)"; }
notice ()    { local _message="${*}"; echo -e "$(_alert_ notice)"; }
info ()      { local _message="${*}"; echo -e "$(_alert_ info)"; }
debug ()     { local _message="${*}"; echo -e "$(_alert_ debug)"; }
success ()   { local _message="${*}"; echo -e "$(_alert_ success)"; }
dryrun()     { local _message="${*}"; echo -e "$(_alert_ dryrun)"; }
input()      { local _message="${*}"; echo -n "$(_alert_ input)"; }
header()     { local _message="== ${*} ==  "; echo -e "$(_alert_ header)"; }
verbose()    { if ${verbose}; then debug "$@"; fi }

### FUNCTIONS ###

_execute_() {
  # v1.0.2
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
      return 0
    else
      error "${message}"
      return 1
      #die "${message}"
    fi
  fi
}

_findBaseDir_() {
  #v1.0.0
  # fincBaseDir locates the real directory of the script being run. similar to GNU readlink -n
  # usage :  baseDir="$(_findBaseDir_)"
  local SOURCE
  local DIR
  SOURCE="${BASH_SOURCE[0]}"
  while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="${DIR}/${SOURCE}" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  done
  echo "$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
}

_haveFunction_() {
  # v1.0.0
  # Tests if a function exists.  Returns 0 if yes, 1 if no
  # usage: _haveFunction "_someFunction_"
  local f
  f="$1"

  if declare -f "$f" &> /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

_pauseScript_() {
  # v1.0.0
  # A simple function used to pause a script at any point and
  # only continue on user input
  if _seekConfirmation_ "Ready to continue?"; then
    info "Continuing..."
  else
    notice "Exiting Script"
    _safeExit_
  fi
}

_progressBar_() {
  # v1.0.0
  # Prints a progress bar within a for/while loop.
  # To use this function you must pass the total number of
  # times the loop will run to the function.
  #
  # Takes two inputs:
  #   $1 - The total number of items counted
  #   $2 - The optional title of the progress bar
  #
  # usage:
  #   for number in $(seq 0 100); do
  #     sleep 1
  #     _progressBar_ "100" "Counting numbers"
  #   done
  # -----------------------------------

  ( $quiet ) && return
  ( $verbose ) && return
  [ ! -t 1 ] && return  # Do nothing if the output is not a terminal

  local width bar_char perc num bar progressBarLine barTitle n

  n="${1:?_progressBar_ needs input}" ; (( n = n - 1 )) ;
  barTitle="${2:-Running Process}"
  width=30
  bar_char="#"

  # Reset the count
  [ -z "${progressBarProgress}" ] && progressBarProgress=0
  tput civis   # Hide the cursor
  trap 'tput cnorm; exit 1' SIGINT

  if [ ! "${progressBarProgress}" -eq $n ]; then
    #echo "progressBarProgress: $progressBarProgress"
    # Compute the percentage.
    perc=$(( progressBarProgress * 100 / $1 ))
    # Compute the number of blocks to represent the percentage.
    num=$(( progressBarProgress * width / $1 ))
    # Create the progress bar string.
    bar=""
    if [ ${num} -gt 0 ]; then
      bar=$(printf "%0.s${bar_char}" $(seq 1 ${num}))
    fi
    # Print the progress bar.
    progressBarLine=$(printf "%s [%-${width}s] (%d%%)" "  ${barTitle}" "${bar}" "${perc}")
    echo -ne "${progressBarLine}\r"
    progressBarProgress=$(( progressBarProgress + 1 ))
  else
    # Clear the progress bar when complete
    # echo -ne "\033[0K\r"
    tput el   # Clear the line

    unset progressBarProgress
  fi

  tput cnorm
}

_safeExit_() {
  # Delete temp files, if any
  [ -d "${tmpDir}" ] && rm -r "${tmpDir}"
  trap - INT TERM EXIT
  exit ${1:-0}
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
        [Yy]* ) return 0;;
        [Nn]* ) return 1;;
        * ) input "Please answer yes or no.";;
      esac
    done
  fi
}

_setPATH_() {
  #v1.0.0
  # setPATH() Add specified directories to $PATH so the script can find executables
  local PATHS NEWPATH

  PATHS=(
    /usr/local/bin
    ${HOME}/bin
    )
  for NEWPATH in "${PATHS[@]}"; do
    if ! echo "$PATH" | grep -Eq "(^|:)${NEWPATH}($|:)" ; then
      PATH="${NEWPATH}:${PATH}"
   fi
 done
}

_trapCleanup_() {
  echo ""
  # Delete temp files, if any
  [ -d "${tmpDir}" ] && rm -r "${tmpDir}"
  fatal "Exit trapped. Function: '${FUNCNAME[*]:1}'"
}