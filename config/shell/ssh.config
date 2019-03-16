
alias pubkey="more ~/.ssh/id_rsa.pub | pbcopy | echo '=> Public key copied to pasteboard.'"

add_ssh() {
  # about 'add entry to ssh config'
  # param '1: host'
  # param '2: hostname'
  # param '3: user'

  echo -en "\n\nHost $1\n  HostName $2\n  User $3\n  ServerAliveInterval 30\n  ServerAliveCountMax 120" >>~/.ssh/config
}

sshlist() {
  # about 'list hosts defined in ssh config'
  awk '$1 ~ /Host$/ {for (i=2; i<=NF; i++) print $i}' ~/.ssh/config
}

createTunnel() {
  # createTunnel:  Create a ssh tunnel with arguments or querying for it.
  if [ $# -eq 3 ]; then
    user=$1
    host=$2
    localPort=$3
    remotePort=$3
  else
    if [ $# -eq 4 ]; then
      user=$1
      host=$2
      localPort=$3
      remotePort=$4
    else
      echo -n "User: "
      read -r user
      echo -n "host: "
      read -r host
      echo -n "Distant host: "
      read -r remotePort
      echo -n "Local port: "
      read -r localPort
    fi
  fi
  ssh -N -f $user@$host -L ${localPort}:${host}:${remotePort}
}