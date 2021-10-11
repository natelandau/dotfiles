alias netCons='lsof -i'                           # Show all open TCP/IP sockets
alias flushDNS='dscacheutil -flushcache'          # linux: Flush out the DNS Cache
alias lsock='sudo /usr/sbin/lsof -i -P'           # Display open sockets
alias lsockU='sudo /usr/sbin/lsof -nP | grep UDP' # Display only open UDP sockets
alias lsockT='sudo /usr/sbin/lsof -nP | grep TCP' # Display only open TCP sockets
alias ipInfo0='ipconfig getpacket en0'            # Get info on connections for en0
alias ipInfo1='ipconfig getpacket en1'            # Get info on connections for en1
alias openPorts='sudo lsof -i | grep LISTEN'      # All listening connections
alias showBlocked='sudo ipfw list'                # All ipfw rules inc/ blocked IPs
alias newDHCP='sudo ipconfig set en0 DHCP'        # Renews DHCP lease for en0
if ! command -v dig &>/dev/null; then
    if command -v drill &>/dev/null; then
        alias dig='drill'
    fi
fi

newMAC() {
    # DESC:   Changes MAC address of en0 to get around public wifi limitations
    # ARGS:		None
    # OUTS:		None
    # REQS:   Linux
    # NOTE:   https://github.com/stefanjudis/.dotfiles
    # USAGE:

    NEW_MAC_ADDRESS=$(openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//')
    echo "${NEW_MAC_ADDRESS}"
    sudo ifconfig en0 ether "$NEW_MAC_ADDRESS"
    echo "New MAC Address set"
}

lips() {
    # DESC:		Prints local and external IP addresses
    # ARGS:		$1 (optional): Interface name (Defaults to en0)
    # OUTS:		None

    local IP_TMP LOCAL_IP EXTERNAL_IP LIPS_INTERFACE
    LIPS_INTERFACE=${1:-en0}

    IP_TMP=$(ifconfig ${LIPS_INTERFACE} | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}')
    [ "${IP_TMP}" != "" ] && LOCAL_IP="${IP_TMP}" || LOCAL_IP="inactive"

    IP_TMP=$(curl -s https://icanhazip.com)
    [ "${IP_TMP}" != "" ] && EXTERNAL_IP=${IP_TMP} || EXTERNAL_IP="inactive"

    printf "${white}${bold}%-11s${reset} %s\n" "Local IP:" "${LOCAL_IP}"
    printf "${white}${bold}%-11s${reset} %s\n" "External IP:" "${EXTERNAL_IP}"

}

if [[ ${OSTYPE} == "darwin"* ]]; then
    clearDNS() {
        # DESC:		Clears the DNS cache to help fix networking errors
        # ARGS:		None
        # OUTS:		None
        # REQS:		MacOS

        sudo dscacheutil -flushcache \
            && sudo killall -HUP mDNSResponder
    }
fi
