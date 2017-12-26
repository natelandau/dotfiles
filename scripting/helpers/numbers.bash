_convertSecs_() {
  # v1.0.0
  # Pass a number (seconds) into the function as this:
  # _convertSecs_ $TOTALTIME
  #
  # To compute the time it takes a script to run:
  #   STARTTIME=$(date +"%s")
  #   ENDTIME=$(date +"%s")
  #   TOTALTIME=$(($ENDTIME-$STARTTIME)) # human readable time

  ((h = ${1} / 3600))
  ((m = (${1} % 3600) / 60))
  ((s = ${1} % 60))
  printf "%02d:%02d:%02d\n" $h $m $s
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
