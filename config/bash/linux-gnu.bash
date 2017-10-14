if [[ "$OSTYPE" == "linux-gnu"* ]]; then

  alias sag='sudo apt-get'
  aup () { sudo apt-get update; sudo apt-get upgrade -y; }

fi

