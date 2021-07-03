su() {
  # su: Do sudo to a command, or do sudo to the last typed command if no argument given
  if [[ $# == 0 ]]; then
    sudo "$(history -p '!!')"
  else
    sudo "$@"
  fi
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

  while ((attempt < max_attempts)); do
    set +e
    "$@"
    exitCode=$?
    set -e

    if [[ ${exitCode} == 0 ]]; then
      break
    fi

    echo "Failure! Retrying in ${timeout}.." 1>&2
    sleep "${timeout}"
    attempt=$((attempt + 1))
    timeout=$((timeout * 2))
  done

  if [[ ${exitCode} != 0 ]]; then
    echo "You've failed me for the last time! ($*)" 1>&2
  fi
  return ${exitCode}
}

halp() {
  # A little helper for man/alias/function info
  # http://brettterpstra.com/2016/05/18/shell-tricks-halp-a-universal-help-tool/
  # Edited to run 'SCRIPT.sh -h' for my own personal scripts

  local apro=0
  local helpstring="Usage: halp COMMAND

  ${bold}Commonly forgotten commands:${reset}
    cleanDS             Remove .DS_Store files
    finderPath          Gets the frontmost path from the Finder
    lips                Prints local and external IP addresses
    ql                  Opens any file in MacOS Quicklook Preview
    "
  local opt OPTIND

  OPTIND=1
  while getopts "kh" opt; do
    case ${opt} in
      k) apro=1 ;;
      h)
        echo -e "${helpstring}"
        return
        ;;
      *) return 1 ;;
    esac
  done
  shift $((OPTIND - 1))

  if [ $# -ne 1 ]; then
    echo -e "${helpstring}"
    return 1
  fi

  local cmd="${1}"
  [[ "${SHELL##*/}" == "zsh" ]] && local cmdtest="$(type -w "${cmd}" | awk -F': ' '{print $2}')"
  [[ "${SHELL##*/}" == "bash" ]] && local cmdtest=$(type -t "${cmd}")

  if [ -z "${cmdtest}" ]; then
    echo -e "${YELLOW}'${cmd}' is not a known command${RESET}"
    if [[ "${apro}" == 1 ]]; then
      man -k "${cmd}"
    else
      return 1
    fi
  fi

  if [[ "${cmdtest}" == "command" || "${cmdtest}" == "file" ]]; then
    local location=$(command -v "${cmd}")
    local bindir="${HOME}/bin/${cmd}"
    if [[ "${location}" == "${bindir}" ]]; then
      echo -e "${YELLOW}${cmd} is a custom script${RESET}\n"
      "${bindir}" -h
    else
      if tldr "${cmd}" &>/dev/null ; then
        tldr "${cmd}"
      else
        man "${cmd}"
      fi
    fi
  elif [[ "${cmdtest}" == "alias" ]]; then
    echo -ne "${YELLOW}${cmd} is an alias:  ${RESET}"
    alias "${cmd}" | sed -E "s/alias $cmd='(.*)'/\1/"
  elif [[ "${cmdtest}" == "builtin" ]]; then
    echo -ne "${YELLOW}${cmd} is a builtin command${RESET}"
    if tldr "${cmd}" &>/dev/null ; then
      tldr "${cmd}"
    else
      man "${cmd}"
    fi
  elif [[ "${cmdtest}" == "function" ]]; then
    echo -e "${YELLOW}${cmd} is a function${RESET}"
    [[ "${SHELL##*/}" == "zsh" ]] && type -f "${cmd}" | tail -n +1
    [[ "${SHELL##*/}" == "bash" ]] && type "${cmd}" | tail -n +2
  fi
}

explain() {
  # about 'explain any bash command via mankier.com manpage API'
  # example '$ explain                # interactive mode. Type commands to explain in REPL'
  # example '$ explain cmd -o | ... # one command to explain it.'

  if [ "$#" -eq 0 ]; then
    while read -r -p "Command: " cmd; do
      curl -Gs "https://www.mankier.com/api/explain/?cols=$(tput cols)" --data-urlencode "q=${cmd}"
    done
    echo "Bye!"
  else
    curl -Gs "https://www.mankier.com/api/explain/?cols=$(tput cols)" --data-urlencode "q=$*"
  fi
}
