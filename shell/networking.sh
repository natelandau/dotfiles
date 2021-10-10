alias netCons='lsof -i'                           # Show all open TCP/IP sockets
alias flushDNS='dscacheutil -flushcache'          # Flush out the DNS Cache
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
    # DESC:   Changes MAC address to get around public wifi limitations
    #         Copied from:  https://github.com/stefanjudis/.dotfiles
    NEW_MAC_ADDRESS=$(openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//')
    echo "${NEW_MAC_ADDRESS}"
    sudo ifconfig en0 ether "$NEW_MAC_ADDRESS"
    echo "New MAC Address set"
}

lips() {
    # DESC:   Prints local and external IP addresses
    local ip locip extip

    ip=$(ifconfig en0 | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}')
    [ "$ip" != "" ] && locip="${ip}" || locip="inactive"

    ip=$(dig +short myip.opendns.com @resolver1.opendns.com)
    [ "$ip" != "" ] && extip=${ip} || extip="inactive"

    printf '%11s: %s\n%11s: %s\n' "Local IP" ${locip} "External IP" ${extip}
}

clearDNS() {
    # DESC:   Clears the DNS cache to help fix networking errors
    sudo dscacheutil -flushcache \
        && sudo killall -HUP mDNSResponder
}
