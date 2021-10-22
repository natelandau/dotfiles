su() {
    # su: Do sudo to a command, or do sudo to the last typed command if no argument given
    if [[ $# == 0 ]]; then
        sudo "$(history -p '!!')"
    else
        sudo "$@"
    fi
}

withBackoff() {
    # DESC: Retries a command a configurable number of times with backoff.
    # http://stackoverflow.com/questions/8350942/how-to-re-run-the-curl-command-automatically-when-the-error-occurs/8351489#8351489
    # ARGS:		None
    # OUTS:		None
    # USAGE:  with_backoff curl 'http://monkeyfeathers.example.com/'
    # NOTE: The retry count is given by ATTEMPTS (default 5), the initial backoff timeout is given by TIMEOUT in seconds (default 1.) Successive backoffs double the timeout. Then use it in conjunction with any command that properly sets a failing exit code:

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

if ! command -v help &>/dev/null; then
    help() {
        # DESC:		A little helper for man/alias/function info
        # ARGS:		$1 - Command
        # OUTS:		None
        # REQS:
        # NOTE:	  http://brettterpstra.com/2016/05/18/shell-tricks-halp-a-universal-help-tool/
        # USAGE:

        local apro=0
        local helpstring="Use: help COMMAND"
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
        [[ ${SHELL##*/} == "zsh" ]] && local cmdtest="$(type -w "${cmd}" | awk -F': ' '{print $2}')"
        [[ ${SHELL##*/} == "bash" ]] && local cmdtest=$(type -t "${cmd}")

        if [ -z "${cmdtest}" ]; then
            echo -e "${yellow}'${cmd}' is not a known command${reset}"
            if [[ ${apro} == 1 ]]; then
                man -k "${cmd}"
            else
                return 1
            fi
        fi

        if [[ ${cmdtest} == "command" || ${cmdtest} == "file" ]]; then
            local location=$(command -v "${cmd}")
            local bindir="${HOME}/bin/${cmd}"
            if [[ ${location} == "${bindir}" ]]; then
                echo -e "${yellow}${cmd} is a custom script${reset}\n"
                "${bindir}" -h
            else
                if tldr "${cmd}" &>/dev/null; then
                    tldr "${cmd}"
                else
                    man "${cmd}"
                fi
            fi
        elif [[ ${cmdtest} == "alias" ]]; then
            echo -ne "${yellow}${cmd} is an alias:  ${reset}"
            alias "${cmd}" | sed -E "s/alias $cmd='(.*)'/\1/"
        elif [[ ${cmdtest} == "builtin" ]]; then
            echo -ne "${yellow}${cmd} is a builtin command${reset}"
            if tldr "${cmd}" &>/dev/null; then
                tldr "${cmd}"
            else
                man "${cmd}"
            fi
        elif [[ ${cmdtest} == "function" ]]; then
            echo -e "${yellow}${cmd} is a function${reset}"
            [[ ${SHELL##*/} == "zsh" ]] && type -f "${cmd}" | tail -n +1
            [[ ${SHELL##*/} == "bash" ]] && type "${cmd}" | tail -n +2
        fi
    }
fi

explain() {
    # DESC:		Explain any bash command with options via mankier.com manpage API
    # ARGS:		$1: Command to explain
    # OUTS:		None
    # REQS:
    # NOTE:
    # USAGE:	explain ls -al

    if [ "$#" -eq 0 ]; then
        while read -r -p "Command: " cmd; do
            curl -Gs "https://www.mankier.com/api/explain/?cols=$(tput cols)" --data-urlencode "q=${cmd}"
        done
        echo "Bye!"
    else
        curl -Gs "https://www.mankier.com/api/explain/?cols=$(tput cols)" --data-urlencode "q=$*"
    fi
}
