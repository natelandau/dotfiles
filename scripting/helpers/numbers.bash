_fromSeconds_() {
  # v1.0.0
  # Pass a number (seconds) into the function to convert it to HH:MM:SS
  #
  #   Usage:  _convertSecs_ "SECONDS"
  #
  # Sample usage:
  #   To compute the time it takes a script to run:
  #     STARTTIME=$(date +"%s")
  #     ENDTIME=$(date +"%s")
  #     TOTALTIME=$(($ENDTIME-$STARTTIME)) # human readable time

  ((h = ${1} / 3600))
  ((m = (${1} % 3600) / 60))
  ((s = ${1} % 60))
  printf "%02d:%02d:%02d\n" $h $m $s
}

_toSeconds_() {
  # v1.0.0
  #
  # Takes an input of HOURS MINUTES SECONDS and converts it to
  # a total number of seconds. Takes an input in a number of formats.
  #
  # Usage:  '_toSeconds_ 01:00:00' would return '3600'
  #
  # Acceptable Input Formats
  #   24 12 09
  #   12,12,09
  #   12;12;09
  #   12:12:09
  #   12-12-09
  #   12H12M09S
  #   12h12m09s
  local saveIFS

  if [[ "$1" =~ [0-9]{1,2}(:|,|-|_|,| |[hHmMsS])[0-9]{1,2}(:|,|-|_|,| |[hHmMsS])[0-9]{1,2} ]]; then
    saveIFS="$IFS"
    IFS=":,;-_, HhMmSs" read -r h m s <<< "$1"
    IFS="$saveIFS"
  else
    h="$1"
    m="$2"
    s="$3"
  fi

  echo $(( 10#$h * 3600 + 10#$m * 60 + 10#$s ))
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
  #   $ _countdown_ 10 1 "Waiting for cache to invalidate"
  local i ii t
  local n=${1:-10}
  local stime=${2:-1}
  local message="${3:-...}"
  ((t = n + 1))

  for ((i = 1; i <= n; i++)); do
    ((ii = t - i))
    if declare -f "info" &>/dev/null 2>&1; then
      info "${message} ${ii}"
    else
      echo "${message} ${ii}"
    fi
    sleep $stime
  done
}