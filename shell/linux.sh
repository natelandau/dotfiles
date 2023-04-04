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

    ntpup() {
        # DESC:		Confirm that ntp is running
        # ARGS:		None
        # OUTS:		None
        # USAGE:

        if ! sudo service ntp status &>/dev/null; then
            sudo service ntp start
        fi

        sudo service ntp status
    }

fi
