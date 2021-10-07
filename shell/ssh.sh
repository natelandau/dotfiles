alias pubkey="more ~/.ssh/id_rsa.pub | pbcopy | echo '=> Public key copied to pasteboard.'"

createTunnel() {
    # createTunnel:  Create a ssh tunnel with arguments or querying for it.
    if [ $# -eq 3 ]; then
        local user=$1
        local host=$2
        local localPort=$3
        local remotePort=$3
    else
        if [ $# -eq 4 ]; then
            local user=$1
            local host=$2
            local localPort=$3
            local remotePort=$4
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
    ssh -N -f ${user}@${host} -L ${localPort}:${host}:${remotePort}
}
