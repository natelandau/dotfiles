if [[ ${OSTYPE} == "darwin"* ]]; then

    ## ALIASES ##
    alias cpwd='pwd | tr -d "\n" | pbcopy'                        # Copy the working path to clipboard
    alias cl="fc -e -|pbcopy"                                     # Copy output of last command to clipboard
    alias caff="caffeinate -ism"                                  # Run command without letting mac sleep
    alias cleanDS="find . -type f -name '*.DS_Store' -ls -delete" # Delete .DS_Store files on Macs
    alias finderShowHidden='defaults write com.apple.finder AppleShowAllFiles TRUE'
    alias finderHideHidden='defaults write com.apple.finder AppleShowAllFiles FALSE'

    # Open the finder to a specified path or to current directory.
    f() {
        # DESC:		Opens the Finder to specified directory. (Default is current oath)
        # ARGS:		$1 (optional): Path to open in finder
        # REQS:		MacOS
        # USAGE:  f [path]
        open -a "Finder" "${1:-.}"
    }

    ql() {
        # DESC:   Opens files in MacOS Quicklook
        # ARGS:		$1 (optional): File to open in Quicklook
        # OUTS:		None
        # REQS:   macOS
        # USAGE: ql [file1] [file2]
        qlmanage -p "${*}" &>/dev/null
    }

    alias cleanupLS="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder" # Clean up LaunchServices to remove duplicates in the "Open With" menu

    unquarantine() {
        # DESC:		Manually remove a downloaded app or file from the MacOS quarantine
        # ARGS:		$1 (required): Path to file or app
        # OUTS:		None
        # REQS:   macOS
        # NOTE:
        # USAGE:  unquarantine [file]

        local attribute
        # unquarantine:
        for attribute in com.apple.metadata:kMDItemDownloadedDate com.apple.metadata:kMDItemWhereFroms com.apple.quarantine; do
            xattr -r -d "${attribute}" "$@"
        done
    }

    browser() {
        # DESC:		Pipe HTML to a Safari browser window
        # ARGS:		None
        # OUTS:		None
        # REQS:   macOS
        # NOTE:
        # USAGE: echo "<h1>hi mom!</h1>" | browser'

        local FILE
        FILE=$(mktemp -t browser.XXXXXX.html)
        cat /dev/stdin >|"${FILE}"
        open -a Safari "${FILE}"
    }

    finderpath() {
        # DESC:		Echoes the path of the frontmost window in the finder
        # ARGS:		None
        # OUTS:		None
        # REQS:   MACOS
        # NOTE:
        # USAGE:  cd $(finderpath)
        # Gets the frontmost path from the Finder
        #
        # credit: https://github.com/herrbischoff/awesome-osx-command-line/blob/master/functions.md

        local FINDER_PATH

        FINDER_PATH=$(
            osascript -e 'tell application "Finder"' \
                -e "if (${1-1} <= (count Finder windows)) then" \
                -e "get POSIX path of (target of window ${1-1} as alias)" \
                -e 'else' \
                -e 'get POSIX path of (desktop as alias)' \
                -e 'end if' \
                -e 'end tell' 2>/dev/null
        )

        echo "${FINDER_PATH}"
    }

    ## SPOTLIGHT MAINTENANCE ##
    alias spot-off="sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist"
    alias spot-on="sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist"

    # If the 'mds' process is eating tons of memory it is likely getting hung on a file.
    # This will tell you which file that is.
    alias spot-file="lsof -c '/mds$/'"

    # Search for a file using MacOS Spotlight's metadata
    spotlight() { mdfind "kMDItemDisplayName == '${1}'wc"; }
fi
