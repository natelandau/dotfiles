if command -v less &>/dev/null; then
    [ -e "${HOME}/repos/dotfiles/bin/lessfilter.sh" ] && export LESSOPEN="|${HOME}/repos/dotfiles/bin/lessfilter.sh %s"
    alias less='less -RXqeF'
    alias more='less -RXqeNF'
fi

[[ "$(command -v most)" ]] && alias less="most"

[[ "$(command -v micro)" ]] && alias nano="micro"

# shellcheck disable=SC2016
escape() {
    # DESC:		Escape special characters in a string
    # ARGS:		None
    # OUTS:		None
    # USAGE:
    # NOTE:
    printf "%s" "${@}" | sed 's/[]\.|$(){}?+*^]/\\&/g'
}

domainSort() {
    # DESC:		Take a list of URLS and sort it into a list of unique top-level domains
    # ARGS:		None
    # OUTS:		None
    # REQS:
    # NOTE:
    # USAGE:  domainSort [URL] [URL] [URL] ...

    local tmp opt helpstring list thirdLvlSubs
    local count=false
    local noSubs=false
    helpstring="Takes a list of URLs and sorts it into a list of unique top-level domains.\n \nOptions:\n\t-c:\t Add a count of the occurrences of each unique domain.\n \t-s:\t Remove subdomains"

    local OPTIND=1
    while getopts "hcs" opt; do
        case ${opt} in
            c) count=true ;;
            s) noSubs=true ;;
            h)
                echo -e "${helpstring}"
                return
                ;;
            *) return 1 ;;
        esac
    done
    shift $((OPTIND - 1))

    list="$1"
    thirdLvlSubs="^co$|^com$|^ny$|^ac$|^gov$|^org$|^ca$|^blogspot$"
    tmp="$(mktemp "/tmp/XXXXXXXXXXXX")"

    [ ! -f "$list" ] \
        && {
            echo "Error: can not find '${list}'"
            return 1
        }

    # Remove protocol and file paths
    sed 's/https?:\/\///;s|\/.*||' "${list}" >|"${tmp}"

    # Generate output
    if "${noSubs}"; then
        if "${count}"; then
            awk -v env_var="$thirdLvlSubs" -F. \
                '/^\.$|^com$/ {next} {if ($(NF-1) ~ env_var) printf $(NF-2)"."; printf $(NF-1)"."$(NF)"\n"; }' "${tmp}" \
                | sort \
                | awk ' { tot[$0]++ } END { for (i in tot) print ""tot[i]" -",i } ' \
                | sort -rn -k1,1 -k2,2
        else
            awk -v env_var="$thirdLvlSubs" -F. \
                '{if ($(NF-1) ~ env_var) printf $(NF-2)"."; printf $(NF-1)"."$(NF)"\n"; }' "${tmp}" \
                | sort -u
        fi
    else
        if "${count}"; then
            awk ' { tot[$0]++ } END { for (i in tot) print ""tot[i]" -",i } ' "${tmp}" \
                | sort -rn -k1,1 -k2,2
        else
            sort -u "${tmp}"
        fi
    fi

    # Cleanup temporary file
    [ -f "$tmp" ] \
        && command rm "$tmp"
}

htmldecode() {
    # DESC:		Decode HTML entities in a string
    # ARGS:		None
    # OUTS:		None
    # USAGE:	htmlDecode <string>
    # NOTE:

    local sedLocation
    sedLocation="${HOME}/.sed/htmlDecode.sed"
    if [ -f "${sedLocation}" ]; then
        echo "${1}" | sed -f "${sedLocation}"
    else
        echo "error. Could not find sed translation file"
    fi
}

htmlencode() {
    # DESC:		Encode characters in a string to HTML
    # ARGS:		None
    # OUTS:		None
    # USAGE:	htmlEncode <string>

    local sedLocation
    sedLocation="${HOME}/.sed/htmlEncode.sed"
    if [ -f "${sedLocation}" ]; then
        echo "${1}" | sed -f "${sedLocation}"
    else
        echo "error. Could not find sed translation file"
    fi
}

# URL-encode strings
#alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);"'

urlencode() {
    # DESC:		Encode a URL
    #         from: https://gist.github.com/cdown/1163649
    # ARGS:		None
    # OUTS:		None
    # USAGE:	urlencode <string>

    local i
    local LANG=C
    local length="${#1}"
    for ((i = 0; i < length; i++)); do
        local c="${1:i:1}"
        case ${c} in
            [a-zA-Z0-9.~_-]) printf "%s" "${c}" ;;
            *) printf '%%%02X' "'${c}" ;;
        esac
    done
}

alias urldecode='python -c "import sys, urllib as ul; print ul.unquote_plus(sys.argv[1])"' # dev: Decode a URL [ULR]

lower() {
    # DESC:		Convert stdin to lowercase.
    # ARGS:		None
    # OUTS:		None
    # USAGE:	 echo "MAKETHISLOWERCASE" | lower
    # NOTE:

    tr '[:upper:]' '[:lower:]'
}

upper() {
    # DESC:		Convert stdin to uppercase.
    # ARGS:		None
    # OUTS:		None
    # USAGE:	echo "makethisuppercase" | upper
    # NOTE:

    tr '[:lower:]' '[:upper:]'
}

ltrim() {
    # DESC:		Removes all leading whitespace (from the left).
    local char=${1:-[:space:]}
    sed "s%^[${char//%/\\%}]*%%"
}

rtrim() {
    # DESC:		Removes all trailing whitespace (from the right).
    local char=${1:-[:space:]}
    sed "s%[${char//%/\\%}]*$%%"
}

trim() {
    # DESC:		Removes all leading/trailing whitespace
    # USAGE:  echo "  foo  bar baz " | trim
    ltrim "$1" | rtrim "$1"
}

squeeze() {
    # DESC:		Removes leading/trailing whitespace and condenses all other consecutive whitespace into a single space.
    #
    # USAGE: echo "  foo  bar baz " | squeeze

    local char=${1:-[[:space:]]}
    sed "s%\(${char//%/\\%}\)\+%\1%g" | trim "$char"
}
