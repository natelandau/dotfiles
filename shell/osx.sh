if [[ ${OSTYPE} == "darwin"* ]]; then

    # Favor gnu tools when available from homebrew
    if [ -d "/usr/local/opt/findutils/libexec/gnubin" ]; then
        PATH="/usr/local/opt/findutils/libexec/gnubin:${PATH}"
    fi
    if [ -d "/usr/local/opt/gnu-sed/libexec/gnubin" ]; then
        PATH="/usr/local/opt/gnu-sed/libexec/gnubin:${PATH}"
    fi
    if [ -d "/usr/local/opt/grep/libexec/gnubin" ]; then
        PATH="/usr/local/opt/grep/libexec/gnubin:${PATH}"
    fi
    if [ -d "/usr/local/opt/coreutils/libexec/gnubin" ]; then
        PATH="/usr/local/opt/coreutils/libexec/gnubin:${PATH}"
    fi
    if [ -d "/usr/local/opt/gnu-tar/libexec/gnubin" ]; then
        PATH="/usr/local/opt/gnu-tar/libexec/gnubin:${PATH}"
    fi
    if [ -d "/usr/local/opt/gnu-getopt/bin" ]; then
        PATH="/usr/local/opt/gnu-getopt/bin:${PATH}"
    fi

    if [ -e "/Applications/iTerm.app" ]; then
        if [[ -n ${BASH} ]]; then
            if [[ -f ~/.iterm2_shell_integration.bash ]]; then
                source ~/.iterm2_shell_integration.bash
            else
                curl -L https://iterm2.com/shell_integration/bash \
                    -o ~/.iterm2_shell_integration.bash &>/dev/null
            fi
        elif [[ -n ${ZSH_NAME} ]]; then
            if [[ -f ~/.iterm2_shell_integration.zsh ]]; then
                # export ITERM2_SQUELCH_MARK=1
                source ~/.iterm2_shell_integration.zsh
            else
                curl -L https://iterm2.com/shell_integration/zsh \
                    -o ~/.iterm2_shell_integration.zsh &>/dev/null
            fi
        fi
    fi

    ## ALIASES ##
    alias cpwd='pwd | tr -d "\n" | pbcopy'                        # Copy the working path to clipboard
    alias cl="fc -e -|pbcopy"                                     # Copy output of last command to clipboard
    alias caff="caffeinate -ism"                                  # Run command without letting mac sleep
    alias cleanDS="find . -type f -name '*.DS_Store' -ls -delete" # Delete .DS_Store files on Macs
    alias finderShowHidden='defaults write com.apple.finder AppleShowAllFiles TRUE'
    alias finderHideHidden='defaults write com.apple.finder AppleShowAllFiles FALSE'

    f() { open -a "Finder" "${1:-.}"; }      # Open the finder to a specified path or to current directory.
    ql() { qlmanage -p "${*}" &>/dev/null; } # Opens any file in MacOS Quicklook Preview

    alias cleanupLS="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder" # Clean up LaunchServices to remove duplicates in the "Open With" menu

    unmountDrive() {
        # unmountDrive - If an AFP drive is mounted, this will unmount the volume.
        if [ -d "${1}" ]; then
            diskutil unmount "${1}"
        fi
    }

    unquarantine() {
        local attribute
        # unquarantine: Manually remove a downloaded app or file from the quarantine
        for attribute in com.apple.metadata:kMDItemDownloadedDate com.apple.metadata:kMDItemWhereFroms com.apple.quarantine; do
            xattr -r -d "${attribute}" "$@"
        done
    }

    browser() {
        # Pipe html to a web browser
        # example '$ echo "<h1>hi mom!</h1>" | browser'
        # example '$ ron -5 man/rip.5.ron | browser'
        local f
        f=$(mktemp -t browser.XXXXXX.html)
        cat /dev/stdin >|"${f}"
        open -a Safari "${f}"
    }

    lst() {
        # lst:  Search for files based on OSX native tags
        #       More info:  http://brettterpstra.com/2013/10/28/mavericks-tags-spotlight-and-terminal/
        local query bool
        # if the first argument is "all" (case insensitive),
        # a boolean AND search will be used. Defaults to OR.
        bool="OR"
        [[ ${1} =~ "all" ]] && bool="AND" && shift

        # if there's no argument or the argument is "+"
        # list all files with any tags
        if [[ -z ${1} || ${1} == "+" ]]; then
            query="kMDItemUserTags == '*'"
            # if the first argument is "-"
            # list only files without tags
        elif [[ ${1} == "-" ]]; then
            query="kMDItemUserTags != '*'"
            # Otherwise, build a Spotlight syntax query string
        else
            query="tag:${1}"
            shift
            for tag in "$@"; do
                query="${query} ${bool} tag:${tag}"
            done
        fi

        while IFS= read -r -d $'\0' line; do
            echo "${line#$(pwd)/}"
        done < <(mdfind -onlyin . -0 "${query}")
    }

    finderPath() {
        # Gets the frontmost path from the Finder
        #
        # credit: https://github.com/herrbischoff/awesome-osx-command-line/blob/master/functions.md

        local finderPath

        finderPath=$(osascript -e 'tell application "Finder"' \
            -e "if (${1-1} <= (count Finder windows)) then" \
            -e "get POSIX path of (target of window ${1-1} as alias)" \
            -e 'else' \
            -e 'get POSIX path of (desktop as alias)' \
            -e 'end if' \
            -e 'end tell')

        echo "${finderPath}"
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
