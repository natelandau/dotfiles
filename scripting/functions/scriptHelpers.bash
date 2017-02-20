### Variables ###

now=$(LC_ALL=C date +"%m-%d-%Y %r")        # Returns: 06-14-2015 10:34:40 PM
datestamp=$(LC_ALL=C date +%Y-%m-%d)       # Returns: 2015-06-14
hourstamp=$(LC_ALL=C date +%r)             # Returns: 10:34:40 PM
timestamp=$(LC_ALL=C date +%Y%m%d_%H%M%S)  # Returns: 20150614_223440
today=$(LC_ALL=C date +"%m-%d-%Y")         # Returns: 06-14-2015
longdate=$(LC_ALL=C date +"%a, %d %b %Y %H:%M:%S %z")  # Returns: Sun, 10 Jan 2016 20:47:53 -0500
gmtdate=$(LC_ALL=C date -u -R | sed 's/\+0000/GMT/') # Returns: Wed, 13 Jan 2016 15:55:29 GMT

### Functions ###

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

_pauseScript_() {
  # A simple function used to pause a script at any point and
  # only continue on user input
  if seek_confirmation "Ready to continue?"; then
    notice "Continuing..."
  else
    warning "Exiting Script."
    _safeExit_
  fi
}

_progressBar_() {
  # Prints a progress bar within a for/while loop.
  # To use this function you must pass the total number of
  # times the loop will run to the function.
  #
  # usage:
  #   for number in $(seq 0 100); do
  #     sleep 1
  #     _progressBar_ 100
  #   done
  # -----------------------------------

  # shellcheck disable=2154
  if "${quiet}"; then return; fi # Do nothing in quiet mode
  # shellcheck disable=2154
  if "${verbose}"; then return; fi # Do nothing in verbose mode
  if [ ! -t 1 ]; then return; fi # Do nothing if the output is not a terminal

  local width
  local bar_char
  local perc
  local num
  local bar
  local progressBarLine
  local progressBarProgress

  width=30
  bar_char="#"

  # Reset the count
  if [ -z "${progressBarProgress}" ]; then
    progressBarProgress=0
  fi

  # Hide the cursor
  tput civis
  trap 'tput cnorm; exit 1' SIGINT

  if [ ! "${progressBarProgress}" -eq $(( $1 - 1 )) ]; then
    # Compute the percentage.
    perc=$(( progressBarProgress * 100 / $1 ))
    # Compute the number of blocks to represent the percentage.
    num=$(( progressBarProgress * width / $1 ))
    # Create the progress bar string.
    bar=
    if [ ${num} -gt 0 ]; then
        bar=$(printf "%0.s${bar_char}" $(seq 1 ${num}))
    fi
    # Print the progress bar.
    progressBarLine=$(printf "%s [%-${width}s] (%d%%)" "Running Process" "${bar}" "${perc}")
    echo -en "${progressBarLine}\r"
    progressBarProgress=$(( progressBarProgress + 1 ))
  else
    # Clear the progress bar when complete
    echo -ne "${width}%\033[0K\r"
    unset progressBarProgress
  fi

  tput cnorm
}

_parseYAML_() {
  # Function to parse YAML files and add values to variables. Send it to a temp file and source it
  # https://gist.github.com/DinoChiesa/3e3c3866b51290f31243 which is derived from
  # https://gist.github.com/epiloque/8cf512c6d64641bde388
  #
  # Usage:
  #     $ _parseYAML_ sample.yml > /some/tempfile
  #     $ source /some/tempfile
  #
  # _parseYAML_ accepts a prefix argument so that imported settings all have a common prefix
  # (which will reduce the risk of name-space collisions).
  #
  #     $ _parseYAML_ sample.yml "CONF_"

    local prefix=$2
    local s
    local w
    local fs
    s='[[:space:]]*'
    w='[a-zA-Z0-9_]*'
    fs="$(echo @|tr @ '\034')"
    sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$1" |
    awk -F"$fs" '{
      indent = length($1)/2;
      if (length($2) == 0) { conj[indent]="+";} else {conj[indent]="";}
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
              vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
              printf("%s%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, conj[indent-1],$3);
      }
    }' | sed 's/_=/+=/g'
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
    if seek_confirmation "${csvFile} already exists. Overwrite?"; then
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
  # -----------------------------------
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
  #         Example: $ _httpStatus_ www.google.com 100 -c
  #                  200
  #
  # -----------------------------------
  local curlops
  local arg4
  local arg5
  local arg6
  local arg7
  local flag
  local timeout
  local url

  saveIFS=${IFS}
  IFS=$' \n\t'

  url=${1}
  timeout=${2:-'3'}
  #            ^in seconds
  flag=${3:-'--status'}
  #    curl options, e.g. -L to follow redirects
  arg4=${4:-''}
  arg5=${5:-''}
  arg6=${6:-''}
  arg7=${7:-''}
  curlops="${arg4} ${arg5} ${arg6} ${arg7}"

  #      __________ get the CODE which is numeric:
  code=$(echo "$(curl --write-out %{http_code} --silent --connect-timeout ${timeout} \
                    --no-keepalive ${curlops} --output /dev/null  ${url})")

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
       *)   echo " !!  httpstatus: status not defined." && _safeExit_ ;;
  esac


  # _______________ MAIN
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

_encryptFile_() {
  # Takes a file as argument $1 and encodes it using openSSL
  # Argument $2 is the output name. if $2 is not specified, the
  # output will be '$1.enc'
  #
  # If a variable '$PASS' has a value, we will use that as the password
  # for the encrypted file. Otherwise we will ask.
  #
  # usage:  _encryptFile_ "somefile.txt" "encrypted_somefile.txt"

  [ -z "$1" ] && die "_encodeFile_() needs an argument"
  [ -f "${1}" ] || die "'${1}': Does not exist or is not a file"

  local fileToEncrypt encryptedFile
  fileToEncrypt="$1"
  encryptedFile="${2:-$1.enc}"

  if [ -z $PASS ]; then
    _execute_ "openssl enc -aes-256-cbc -salt -in ${fileToEncrypt} -out ${encryptedFile}" "Encrypt ${fileToEncrypt}"
  else
    _execute_ "openssl enc -aes-256-cbc -salt -in ${fileToEncrypt} -out ${encryptedFile} -k ${PASS}" "Encrypt ${fileToEncrypt}"
  fi
}

_decryptFile_() {
  # Takes a file as argument $1 and decrypts it using openSSL.
  # Argument $2 is the output name. If $2 is not specified, the
  # output will be '$1.decrypt'
  #
  # If a variable '$PASS' has a value, we will use that as the password
  # to decrypt the file. Otherwise we will ask
  #
  # usage:  _decryptFile_ "somefile.txt.enc" "decrypted_somefile.txt"

  [ -z "$1" ] && die "_decryptFile_() needs an argument"
  [ -f "${1}" ] || die "'${1}': Does not exist or is not a file"

  local fileToDecrypt decryptedFile
  fileToDecrypt="${1}"
  decryptedFile="${2:-$1.decrypt}"

  if [ -z $PASS ]; then
    _execute_ "openssl enc -aes-256-cbc -d -in ${fileToDecrypt} -out ${decryptedFile}" "Decrypt ${fileToEncrypt}"
  else
    _execute_ "openssl enc -aes-256-cbc -d -in ${fileToDecrypt} -out ${decryptedFile} -k ${PASS}" "Decrypt ${fileToEncrypt}"
  fi
}