
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

clearDNS() {
  # clearDNS:   Clears the DNS cache to help fix networking errors
  sudo dscacheutil -flushcache && \
  sudo killall -HUP mDNSResponder
}

down4me() {
  # down4me:  checks whether a website is down for you, or everybody
  #           example '$ down4me http://www.google.com'
    curl -s "http://www.downforeveryoneorjustme.com/$1" | sed '/just you/!d;s/<[^>]*>//g'
}

myip() {
  # myip:  displays your ip address, as seen by the Internet
  res=$(curl -s checkip.dyndns.org | grep -Eo --color=never '[0-9\.]+')
  echo -e "Your public IP is: ${BOLD}${YELLOW} $res ${RESET}"
}

createTunnel() {
  # createTunnel:  Create a ssh tunnel with arguments or querying for it.
  if [ $# -eq 3 ]
  then
    user=$1
    host=$2
    localPort=$3
    remotePort=$3
  else
    if [ $# -eq 4 ]
    then
      user=$1
      host=$2
      localPort=$3
      remotePort=$4
    else
      echo -n "User: "; read -r user
      echo -n "host: "; read -r host
      echo -n "Distant host: "; read -r remotePort
      echo -n "Local port: "; read -r localPort
    fi
  fi
  ssh -N -f $user@$host -L ${localPort}:${host}:${remotePort}
}


lips() {
  # Show local and external IP Address
  local ip locip extip
  ip=$(ifconfig en0 | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}')

  [ "$ip" != "" ] && locip=$ip || locip="inactive"

  ip=$(dig +short myip.opendns.com @resolver1.opendns.com)
  [ "$ip" != "" ] && extip=$ip || extip="inactive"

  printf '%11s: %s\n%11s: %s\n' "Local IP" $locip "External IP" $extip
}