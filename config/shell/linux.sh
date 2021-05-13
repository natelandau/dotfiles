if [[ "$OSTYPE" == "linux-gnu"* ]]; then

  alias sag='sudo apt-get'
  aup() {
    sudo apt update
    apt list --upgradable
  }

[ -e "/usr/bin/snap" ] \
  && PATH="/snap/bin:${PATH}"

fi
