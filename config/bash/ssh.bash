# SSH auto-completion based on entries in known_hosts.
if [[ -e ~/.ssh/known_hosts ]]; then
  complete -o default -W "$(cat ${HOME}/.ssh/known_hosts | sed 's/[, ].*//' | sort | uniq | grep -v '[0-9]')" ssh scp sftp
fi

alias sshCopy='pbcopy < ~/.ssh/id_rsa.pub'  # Clipboards id_rsa.pub

function add_ssh() {
  # about 'add entry to ssh config'
  # param '1: host'
  # param '2: hostname'
  # param '3: user'

  echo -en "\n\nHost $1\n  HostName $2\n  User $3\n  ServerAliveInterval 30\n  ServerAliveCountMax 120" >> ~/.ssh/config
}

function sshlist() {
  # about 'list hosts defined in ssh config'
  awk '$1 ~ /Host$/ {for (i=2; i<=NF; i++) print $i}' ~/.ssh/config
}