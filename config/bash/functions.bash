su() {
  # su: Do sudo to a command, or do sudo to the last typed command if no argument given
    if [[ $# == 0 ]]; then
        sudo "$(history -p '!!')"
    else
        sudo "$@"
    fi
}

escape() { echo "${@}" | sed 's/[]\.|$(){}?+*^]/\\&/g'; }

# Text Transformations :

htmldecode() {
  # Decode HTML characters with sed
  # Usage: htmlDecode <string>
  local sedLocation
  sedLocation="${HOME}/dotfiles/config/sed/htmlDecode.sed"
  if [ -f "$sedLocation" ]; then
    echo "${1}" | sed -f "$sedLocation"
  else
    echo "error. Could not find sed translation file"
  fi
}

htmlencode() {
  # Encode HTML characters with sed
  # Usage: htmlEncode <string>

  local sedLocation
  sedLocation="${HOME}/dotfiles/config/sed/htmlEncode.sed"
  if [ -f "$sedLocation" ]; then
    echo "${1}" | sed -f "$sedLocation"
  else
    echo "error. Could not find sed translation file"
  fi
}

# URL-encode strings
#alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);"'

urlencode() {
  # URL encoding/decoding from: https://gist.github.com/cdown/1163649
  # Usage: urlencode <string>

  local LANG=C
  local length="${#1}"
  for (( i = 0; i < length; i++ )); do
    local c="${1:i:1}"
    case $c in
      [a-zA-Z0-9.~_-]) printf "$c" ;;
      *) printf '%%%02X' "'$c" ;;
    esac
  done
}

alias urldecode='python -c "import sys, urllib as ul; print ul.unquote_plus(sys.argv[1])"'

lower() {
  # Convert stdin to lowercase.
  # usage:  text=$(lower <<<"$1")
  #         echo "MAKETHISLOWERCASE" | lower
  tr '[:upper:]' '[:lower:]'
}

upper() {
  # Convert stdin to uppercase.
  # usage:  text=$(upper <<<"$1")
  #         echo "MAKETHISUPPERCASE" | upper
  tr '[:lower:]' '[:upper:]'
}

ltrim() {
  # Removes all leading whitespace (from the left).
  local char=${1:-[:space:]}
    sed "s%^[${char//%/\\%}]*%%"
}

rtrim() {
  # Removes all trailing whitespace (from the right).
  local char=${1:-[:space:]}
  sed "s%[${char//%/\\%}]*$%%"
}

trim() {
  # Removes all leading/trailing whitespace
  # Usage examples:
  #     echo "  foo  bar baz " | trim  #==> "foo  bar baz"
  ltrim "$1" | rtrim "$1"
}

squeeze() {
  # Removes leading/trailing whitespace and condenses all other consecutive
  # whitespace into a single space.
  #
  # Usage examples:
  #     echo "  foo  bar   baz  " | squeeze  #==> "foo bar baz"

  local char=${1:-[[:space:]]}
  sed "s%\(${char//%/\\%}\)\+%\1%g" | trim "$char"
}

withBackoff() {
  # Retries a command a configurable number of times with backoff.
  # (http://stackoverflow.com/questions/8350942/how-to-re-run-the-curl-command-automatically-when-the-error-occurs/8351489#8351489)
  #
  # The retry count is given by ATTEMPTS (default 5), the initial backoff
  # timeout is given by TIMEOUT in seconds (default 1.)
  #
  # Successive backoffs double the timeout.
  #
  # Then use it in conjunction with any command that properly sets a failing exit code:
  #
  # with_backoff curl 'http://monkeyfeathers.example.com/'
  # #######################################################################
  local max_attempts=${ATTEMPTS-5}
  local timeout=${TIMEOUT-1}
  local attempt=0
  local exitCode=0

  while (( attempt < max_attempts ))
  do
    set +e
    "$@"
    exitCode=$?
    set -e

    if [[ ${exitCode} == 0 ]]
    then
      break
    fi

    echo "Failure! Retrying in ${timeout}.." 1>&2
    sleep "${timeout}"
    attempt=$(( attempt + 1 ))
    timeout=$(( timeout * 2 ))
  done

  if [[ ${exitCode} != 0 ]]
  then
    echo "You've failed me for the last time! ($*)" 1>&2
  fi
  return ${exitCode}
}

halp() {
  # A little helper for man/alias/function info
  # http://brettterpstra.com/2016/05/18/shell-tricks-halp-a-universal-help-tool/
  # Edited to run 'SCRIPT.sh -h' for my own personal scripts

  local apro=0 helpstring="Usage: halp COMMAND"

  OPTIND=1
  while getopts "kh" opt; do
    case $opt in
      k) apro=1 ;;
      h) echo -e "$helpstring"; return;;
      *) return 1;;
    esac
  done
  shift $((OPTIND-1))

  if [ $# -ne 1 ]; then
    echo -e "$helpstring"
    return 1
  fi

  local cmd
  local cmdtest
  cmd="$1"
  cmdtest=$(type -t "${cmd}")

  if [ -z "$cmdtest" ]; then
    echo -e "${YELLOW}'$cmd' is not a command${RESET}"
    if [[ "$apro" == 1 ]]; then
      man -k "$cmd"
    else
      return 1
    fi
  fi

  if [[ $cmdtest == "file" ]]; then
    location=$(which "$cmd")
    bindir="${HOME}/bin/${cmd}"
    if [[ "${location}" == "${bindir}" ]]; then
      echo -e "${YELLOW}${cmd} is a custom script:  ${RESET}\n"
      $cmd -h
    else
      man "$cmd"
    fi
  elif [[ $cmdtest == "alias" ]]; then
    echo -ne "${YELLOW}${cmd} is an alias:  ${RESET}"
    alias "${cmd}"|sed -E "s/alias $cmd='(.*)'/\1/"
  elif [[ $cmdtest == "builtin" ]]; then
    echo -ne "${YELLOW}${cmd} is a builtin command:  ${RESET}"
    man $cmd
  elif [[ $cmdtest == "function" ]]; then
    echo -e "${YELLOW}${cmd} is a function:  ${RESET}"
    type "$cmd" | tail -n +2
  fi
}

repeat() {
  # Repeat n times command.
  local i max
  max=$1; shift;
  for ((i=1; i <= max ; i++)); do
      eval "$@";
  done
}

explain () {
  # about 'explain any bash command via mankier.com manpage API'
  # example '$ explain                # interactive mode. Type commands to explain in REPL'
  # example '$ explain cmd -o | ... # one command to explain it.'

  if [ "$#" -eq 0 ]; then
    while read -r -p "Command: " cmd; do
      curl -Gs "https://www.mankier.com/api/explain/?cols=$(tput cols)" --data-urlencode "q=$cmd"
    done
    echo "Bye!"
  else
    curl -Gs "https://www.mankier.com/api/explain/?cols=$(tput cols)" --data-urlencode "q=$*"
  fi
}

hex2rgb() {
  # Convert hex string to rgb
  # @param 1 (String) 3 or 6 character hex string
  #   Case insensitive, leading # optional (01a, fff1b1, #ABB)
  # @param 2 (Float) optional float from 0 to 1
  #   If provided, outputs an rgba() string
  #
  # $ hex2rgb FA0133
  # rgb(250,1,51)
  # $ hex2rgb FA0133 .5
  # rgba(250,1,51,.5)
  local css=true
  local printstring
  local hex="$(tr '[:lower:]' '[:upper:]' <<< ${1#\#})"
  # Convert ABC to AABBCC
  if [[ $hex =~ ^[A-F0-9]{3}$ ]]; then
      hex=$(sed -e 's/\(.\)/\1\1/g' <<< $hex)
  fi

  # If the first param is a valid hex string, convert to rgb
  if [[ $hex =~ ^[A-F0-9]{6}$ ]]; then
      # If second param exists and is a float between 0 and 1, output rgba
      if [[ -n $2 && $2 =~ ^(0?\.[0-9]+|1(\.0)?)$ ]]; then
          [[ $css ]] && printstring="rgba(%d,%d,%d,%s)" || printstring="%d,%d,%d,%s"
          printf $printstring  0x${hex:0:2} 0x${hex:2:2} 0x${hex:4:2} $2
      else
          [[ $css ]] && printstring="rgb(%d,%d,%d)" || printstring="%d,%d,%d"
          printf $printstring 0x${hex:0:2} 0x${hex:2:2} 0x${hex:4:2}
      fi
  # If it's not valid hex, return the original string
  else
      echo -n "$@"
  fi
}

lips() {
    local ip=$(ifconfig en0 | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}')
    local locip extip

    [ "$ip" != "" ] && locip=$ip || locip="inactive"

    ip=$(dig +short myip.opendns.com @resolver1.opendns.com)
    [ "$ip" != "" ] && extip=$ip || extip="inactive"

    printf '%11s: %s\n%11s: %s\n' "Local IP" $locip "External IP" $extip
}