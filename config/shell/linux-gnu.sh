if [[ "$OSTYPE" == "linux-gnu"* ]]; then

  alias sag='sudo apt-get'
  aup() {
    sudo apt-get update
    sudo apt-get upgrade -y
  }

[ -e "/usr/bin/snap" ] \
  && PATH="/snap/bin:${PATH}"

fi
