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

    # Fix potential locale issues
    export LC_ALL=C

    if [ -e "/usr/bin/snap" ]; then
        PATH="/snap/bin:${PATH}"
    fi

fi
