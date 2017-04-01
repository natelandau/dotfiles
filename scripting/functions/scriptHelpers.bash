### Variables ###

now=$(LC_ALL=C date +"%m-%d-%Y %r")        # Returns: 06-14-2015 10:34:40 PM
datestamp=$(LC_ALL=C date +%Y-%m-%d)       # Returns: 2015-06-14
hourstamp=$(LC_ALL=C date +%r)             # Returns: 10:34:40 PM
timestamp=$(LC_ALL=C date +%Y%m%d_%H%M%S)  # Returns: 20150614_223440
today=$(LC_ALL=C date +"%m-%d-%Y")         # Returns: 06-14-2015
longdate=$(LC_ALL=C date +"%a, %d %b %Y %H:%M:%S %z")  # Returns: Sun, 10 Jan 2016 20:47:53 -0500
gmtdate=$(LC_ALL=C date -u -R | sed 's/\+0000/GMT/') # Returns: Wed, 13 Jan 2016 15:55:29 GMT

bold=$(tput bold);        reset=$(tput sgr0);         purple=$(tput setaf 171);
red=$(tput setaf 1);      green=$(tput setaf 76);     tan=$(tput setaf 3);
blue=$(tput setaf 38);    underline=$(tput sgr 0 1);

### Functions ###

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

die()        { local _message="${*} Exiting."; echo -e "$(_alert_ error)"; _safeExit_ "1";}
error()      { local _message="${*}"; echo -e "$(_alert_ error)"; }
warning()    { local _message="${*}"; echo -e "$(_alert_ warning)"; }
notice()     { local _message="${*}"; echo -e "$(_alert_ notice)"; }
info()       { local _message="${*}"; echo -e "$(_alert_ info)"; }
debug()      { local _message="${*}"; echo -e "$(_alert_ debug)"; }
success()    { local _message="${*}"; echo -e "$(_alert_ success)"; }
dryrun()     { local _message="${*}"; echo -e "$(_alert_ dryrun)"; }
input()      { local _message="${*}"; echo -n "$(_alert_ input)"; }
header()     { local _message="== ${*} ==  "; echo -e "$(_alert_ header)"; }
verbose()    { if ${verbose}; then debug "$@"; fi }

_seekConfirmation_() {
  # v1.0.0
  # Seeks a Yes or No answer to a question.  Usage:
  #   if _seekConfirmation_ "Answer this question"; then
  #     something
  #   fi

  input "$@"
  if "${force}"; then
    verbose "Forcing confirmation with '--force' flag set"
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

_setPATH_() {
  # setPATH() Add homebrew and ~/bin to $PATH so the script can find executables
  PATHS=(/usr/local/bin $HOME/bin);
  for newPath in "${PATHS[@]}"; do
    if ! echo "$PATH" | grep -Eq "(^|:)${newPath}($|:)" ; then
      PATH="$newPath:$PATH"
   fi
 done
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
  echo "$( cd -P "$( dirname "$SOURCE" )" && pwd )"
}

_pushover_() {
  # Sends notifications view Pushover
  # IMPORTANT: The API Keys must be filled in
  #
  # Usage: _pushover_ "Title Goes Here" "Message Goes Here"
  #
  # Credit: http://ryonsherman.blogspot.com/2012/10/shell-script-to-send-pushover.html
  # ------------------------------------------------------

  local PUSHOVERURL
  local API_KEY
  local USER_KEY
  local DEVICE
  local TITLE
  local MESSAGE

  PUSHOVERURL="https://api.pushover.net/1/messages.json"
  API_KEY="${PUSHOVER_API_KEY}"
  USER_KEY="${PUSHOVER_USER_KEY}"
  DEVICE=""
  TITLE="${1}"
  MESSAGE="${2}"
  curl \
  -F "token=${API_KEY}" \
  -F "user=${USER_KEY}" \
  -F "device=${DEVICE}" \
  -F "title=${TITLE}" \
  -F "message=${MESSAGE}" \
  "${PUSHOVERURL}" > /dev/null 2>&1
}

_countdown_() {
  # v1.0.0
  # Used to count down in increments of 1 from a specified number.
  # Default is counting down from 10 in 1 second increments
  # Usage:
  #
  #   _countdown_ "starting number" "sleep time (seconds)" "message "
  #
  # Example:
  #   $ _countdown 10 1 "Waiting for cache to invalidate"

  local n=${1:-10}
  local stime=${2:-1}
  local message="${3:-...}"
  ((t=n+1))

  for (( i=1; i<=n; i++ )); do
    ((ii=t-i))
    info "${message} ${ii}"
    sleep $stime
  done
}

_pauseScript_() {
  # A simple function used to pause a script at any point and
  # only continue on user input
  if _seekConfirmation_ "Ready to continue?"; then
    notice "Continuing..."
  else
    warning "Exiting Script."
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

_makeCSV_() {
  # Creates a new CSV file if one does not already exist.
  # Takes passed arguments and writes them as a header line to the CSV
  # Usage '_makeCSV_ column1 column2 column3'

  # Set the location and name of the CSV File
  if [ -z "${csvLocation}" ]; then
    csvLocation="${HOME}/Desktop"
  fi
  if [ -z "${csvName}" ]; then
    csvName="$(LC_ALL=C date +%Y-%m-%d)-${FUNCNAME[1]}.csv"
  fi
  csvFile="${csvLocation}/${csvName}"

  # Overwrite existing file? If not overwritten, new content is added
  # to the bottom of the existing file
  if [ -f "${csvFile}" ]; then
    if _seekConfirmation_ "${csvFile} already exists. Overwrite?"; then
      rm "${csvFile}"
    fi
  fi
  _writeCSV_ "$@"
}

_writeCSV_() {
  # Takes passed arguments and writes them as a comma separated line
  # Usage '_writeCSV_ column1 column2 column3'

  csvInput=($@)
  saveIFS=$IFS
  IFS=','
  echo "${csvInput[*]}" >> "${csvFile}"
  IFS=$saveIFS
}

_convertSecs_() {
  # v1.0.0
  # Pass a number (seconds) into the function as this:
  # _convertSecs_ $TOTALTIME
  #
  # To compute the time it takes a script to run:
  #   STARTTIME=$(date +"%s")
  #   ENDTIME=$(date +"%s")
  #   TOTALTIME=$(($ENDTIME-$STARTTIME)) # human readable time

  ((h=${1}/3600))
  ((m=(${1}%3600)/60))
  ((s=${1}%60))
  printf "%02d:%02d:%02d\n" $h $m $s
}

_httpStatus_() {
  # v1.0.0
  # Shamelessly taken from: https://gist.github.com/rsvp/1171304
  #
  # Usage:  _httpStatus_ URL [timeout] [--code or --status] [see 4.]
  #                                             ^message with code (default)
  #                                     ^code (numeric only)
  #                           ^in secs (default: 3)
  #                   ^URL without "http://" prefix works fine.
  #
  #  4. curl options: e.g. use -L to follow redirects.
  #
  #  Dependencies: curl
  #
  #         Example:  $ _httpStatus_ bit.ly
  #                   301 Redirection: Moved Permanently
  #
  #         Example: $ _httpStatus_ www.google.com 100 -c 200
  local code
  local status

  local saveIFS=${IFS}
  IFS=$' \n\t'

  local url=${1}
  local timeout=${2:-'3'}
  #            ^in seconds
  local flag=${3:-'--status'}
  #    curl options, e.g. -L to follow redirects
  local arg4=${4:-''}
  local arg5=${5:-''}
  local arg6=${6:-''}
  local arg7=${7:-''}
  local curlops="${arg4} ${arg5} ${arg6} ${arg7}"

  #      __________ get the CODE which is numeric:
  code=$(echo "$(curl --write-out %{http_code} --silent --connect-timeout ${timeout} \
                    --no-keepalive ${curlops} --output /dev/null ${url})")

  #      __________ get the STATUS (from code) which is human interpretable:
  case $code in
    000) status="Not responding within ${timeout} seconds" ;;
    100) status="Informational: Continue" ;;
    101) status="Informational: Switching Protocols" ;;
    200) status="Successful: OK within ${timeout} seconds" ;;
    201) status="Successful: Created" ;;
    202) status="Successful: Accepted" ;;
    203) status="Successful: Non-Authoritative Information" ;;
    204) status="Successful: No Content" ;;
    205) status="Successful: Reset Content" ;;
    206) status="Successful: Partial Content" ;;
    300) status="Redirection: Multiple Choices" ;;
    301) status="Redirection: Moved Permanently" ;;
    302) status="Redirection: Found residing temporarily under different URI" ;;
    303) status="Redirection: See Other" ;;
    304) status="Redirection: Not Modified" ;;
    305) status="Redirection: Use Proxy" ;;
    306) status="Redirection: status not defined" ;;
    307) status="Redirection: Temporary Redirect" ;;
    400) status="Client Error: Bad Request" ;;
    401) status="Client Error: Unauthorized" ;;
    402) status="Client Error: Payment Required" ;;
    403) status="Client Error: Forbidden" ;;
    404) status="Client Error: Not Found" ;;
    405) status="Client Error: Method Not Allowed" ;;
    406) status="Client Error: Not Acceptable" ;;
    407) status="Client Error: Proxy Authentication Required" ;;
    408) status="Client Error: Request Timeout within ${timeout} seconds" ;;
    409) status="Client Error: Conflict" ;;
    410) status="Client Error: Gone" ;;
    411) status="Client Error: Length Required" ;;
    412) status="Client Error: Precondition Failed" ;;
    413) status="Client Error: Request Entity Too Large" ;;
    414) status="Client Error: Request-URI Too Long" ;;
    415) status="Client Error: Unsupported Media Type" ;;
    416) status="Client Error: Requested Range Not Satisfiable" ;;
    417) status="Client Error: Expectation Failed" ;;
    500) status="Server Error: Internal Server Error" ;;
    501) status="Server Error: Not Implemented" ;;
    502) status="Server Error: Bad Gateway" ;;
    503) status="Server Error: Service Unavailable" ;;
    504) status="Server Error: Gateway Timeout within ${timeout} seconds" ;;
    505) status="Server Error: HTTP Version Not Supported" ;;
    *)   die " !!  httpstatus: status not defined." ;;
  esac

  case ${flag} in
    --status) echo "${code} ${status}" ;;
    -s)       echo "${code} ${status}" ;;
    --code)   echo "${code}"         ;;
    -c)       echo "${code}"         ;;
    *)        echo " !!  httpstatus: bad flag" && _safeExit_;;
  esac

  IFS="${saveIFS}"
}

_guiInput_() {
  # Ask for user input using a Mac dialog box.
  # Defaults to use the prompt: "Password". Pass an option to change that text.
  #
  # Credit: https://github.com/herrbischoff/awesome-osx-command-line/blob/master/functions.md
  guiPrompt="${1:-Password:}"
  guiInput=$(osascript &> /dev/null <<EOF
    tell application "System Events"
        activate
        text returned of (display dialog "${guiPrompt}" default answer "" with hidden answer)
    end tell
EOF
  )
  echo -n "${guiInput}"
}