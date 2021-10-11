if [[ $OSTYPE == "linux-gnu"* ]]; then

    alias sag='sudo apt-get'
    aup() {
        # DESC:		List available updated from apt-get
        # ARGS:		None
        # OUTS:		None
        # USAGE:

        sudo apt update
        apt list --upgradable
    }

    [ -e "/usr/bin/snap" ] \
        && PATH="/snap/bin:${PATH}"

fi
