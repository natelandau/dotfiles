# shellcheck disable=SC2154

alias netCons='lsof -i'                           # Show all open TCP/IP sockets
alias lsock='sudo /usr/sbin/lsof -i -P'           # Display open sockets
alias lsockU='sudo /usr/sbin/lsof -nP | grep UDP' # Display only open UDP sockets
alias lsockT='sudo /usr/sbin/lsof -nP | grep TCP' # Display only open TCP sockets
alias ipinfo0='ipconfig getpacket en0'            # Get info on connections for en0
alias ipinfo1='ipconfig getpacket en1'            # Get info on connections for en1
alias openports='sudo lsof -i | grep LISTEN'      # All listening connections

myip() {
    # DESC:   Checks external IP address and displays it.  A menu is shown to select a source.
    # ARGS:   None
    # USAGE:  myip

    PS3="Enter a number: "
    COLUMNS=12
    select REPLY in "icanhazip (Default gateway)" "AWS (Default gateway)" "ipify (VPN)" "ipecho (Bypass VPN)" Quit; do
        case $REPLY in
            "icanhazip (Default gateway)")
                printf "%s\n" "$(curl -s icanhazip.com)"
                ;;
            "AWS (Default gateway)")
                printf "%s\n" "$(curl -s checkip.amazonaws.com)"
                ;;
            "ipify (VPN)")
                printf "%s\n" "$(curl -s api.ipify.org)"
                ;;
            "ipecho (Bypass VPN)")
                printf "%s\n" "$(curl -s ipecho.net/plain)"
                ;;
            Quit)
                break
                ;;
            *)
                printf "Invalid option %s" "${REPLY}"
                ;;
        esac
    done

}

if command -v ipfw &>/dev/null; then
    alias showblocked='sudo ipfw list' # linux: All ipfw rules inc/ blocked IPs
fi

if ! command -v dig &>/dev/null; then
    if command -v drill &>/dev/null; then
        alias dig='drill'
    fi
fi

newMAC() {
    # DESC:   Changes MAC Address to get around public wifi limitations
    # ARGS:		1 (optional): Interface name
    # OUTS:		None
    # REQS:   Linux
    # NOTE:   https://github.com/stefanjudis/.dotfiles
    # USAGE:  newMAC [interface]

    local TEST_INTERFACE
    local NEW_MAC_ADDRESS
    local INTERFACE=${1:-unknown}

    if command -v ip &>/dev/null; then
        local IP_COMMAND="ip address show"
    elif command -v ifconfig &>/dev/null; then
        local IP_COMMAND="ifconfig"
    else
        echo "ERROR: Neither 'ip' nor 'ifconfig' found"
        return 1
    fi

    if [[ ${INTERFACE} == "unknown" ]]; then
        for TEST_INTERFACE in en0 en1 eth0 eth1; do
            IP_TMP=$(${IP_COMMAND} ${TEST_INTERFACE} | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}')
            if [[ ${IP_TMP} =~ [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ]]; then
                INTERFACE=${TEST_INTERFACE}
                break
            fi
        done
    fi
    if [[ ${INTERFACE} == "unknown" ]]; then
        echo "ERROR: No interface found with a valid IP address"
        return 1
    fi

    NEW_MAC_ADDRESS=$(openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//')
    echo "${NEW_MAC_ADDRESS}"
    sudo ifconfig ${INTERFACE} ether "${NEW_MAC_ADDRESS}"
    echo "New MAC Address set"
}

lips() {
    # DESC:		Prints local and external IP addresses
    # ARGS:		$1 (optional): Interface name (Defaults to en0)
    # USAGE:  lips [interface]
    # OUTS:		None

    local IP_TMP LOCAL_IP EXTERNAL_IP LIPS_INTERFACE
    LIPS_INTERFACE=${1:-unknown}

    if command -v ip &>/dev/null; then
        local IP_COMMAND="ip address show"
    elif command -v ifconfig &>/dev/null; then
        local IP_COMMAND="ifconfig"
    else
        echo "ERROR: Neither 'ip' nor 'ifconfig' found"
        return 1
    fi

    if [[ ${LIPS_INTERFACE} == "unknown" ]]; then
        for TEST_INTERFACE in en0 en1 eth0 eth1; do
            IP_TMP=$(${IP_COMMAND} ${TEST_INTERFACE} | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}')
            if [[ ${IP_TMP} =~ [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ]]; then
                break
            fi
        done
    else
        IP_TMP=$("${IP_COMMAND}" "${LIPS_INTERFACE}" | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}')
    fi

    [ "${IP_TMP}" != "" ] && LOCAL_IP="${IP_TMP}" || LOCAL_IP="${LIPS_INTERFACE} inactive"

    IP_TMP=$(curl -s https://icanhazip.com)
    [ "${IP_TMP}" != "" ] && EXTERNAL_IP=${IP_TMP} || EXTERNAL_IP="inactive"

    printf "${white}${bold}%-11s${reset} %s\n" "Local IP:" "${LOCAL_IP}"
    printf "${white}${bold}%-11s${reset} %s\n" "External IP:" "${EXTERNAL_IP}"

}

if [[ ${OSTYPE} == "darwin"* ]]; then
    flushdns() {
        # DESC:		Clears the DNS cache to help fix networking errors
        # ARGS:		None
        # OUTS:		None
        # REQS:		MacOS

        sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder
    }
fi
