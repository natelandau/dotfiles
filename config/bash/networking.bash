alias netCons='lsof -i'                           # netCons:   Show all open TCP/IP sockets
alias flushDNS='dscacheutil -flushcache'          # flushDNS:  Flush out the DNS Cache
alias lsock='sudo /usr/sbin/lsof -i -P'           # lsock:     Display open sockets
alias lsockU='sudo /usr/sbin/lsof -nP | grep UDP' # lsockU:    Display only open UDP sockets
alias lsockT='sudo /usr/sbin/lsof -nP | grep TCP' # lsockT:    Display only open TCP sockets
alias ipInfo0='ipconfig getpacket en0'            # ipInfo0:   Get info on connections for en0
alias ipInfo1='ipconfig getpacket en1'            # ipInfo1:   Get info on connections for en1
alias openPorts='sudo lsof -i | grep LISTEN'      # openPorts: All listening connections
alias showBlocked='sudo ipfw list'                # showBlocked:  All ipfw rules inc/ blocked IPs
alias newDHCP='sudo ipconfig set en0 DHCP'        # newDHCP:    Renews DHCP lease

lips() {
  local ip locip extip
  
  ip=$(ifconfig en0 | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}')
  [ "$ip" != "" ] && locip="${ip}" || locip="inactive"

  ip=$(dig +short myip.opendns.com @resolver1.opendns.com)
  [ "$ip" != "" ] && extip=${ip} || extip="inactive"
  
  printf '%11s: %s\n%11s: %s\n' "Local IP" ${locip} "External IP" ${extip}
}


clearDNS() {
  # clearDNS:   Clears the DNS cache to help fix networking errors
  sudo dscacheutil -flushcache \
    && sudo killall -HUP mDNSResponder
}

down4me() {
  # down4me:  checks whether a website is down for you, or everybody
  #           example '$ down4me http://www.google.com'
  curl -s "http://www.downforeveryoneorjustme.com/$1" | sed '/just you/!d;s/<[^>]*>//g'
}