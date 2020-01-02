if command -v less &>/dev/null; then
  [ -e ${HOME}/bin/lessfilter.sh ] && export LESSOPEN='|~/bin/lessfilter.sh %s'
  alias less='less -RXcqeF'
  alias more='less -RXcqeNF'
fi

escape() { echo "${@}" | sed 's/[]\.|$(){}?+*^]/\\&/g'; }

domainSort() {
  # Take a list of URLS and sort it into a list of unique top-level domains
  local domain tmp opt helpstring list thirdLvlSubs
  local count=false
  local noSubs=false
  helpstring="Takes a list of URLs and sorts it into a list of unique top-level domains.\n \nOptions:\n\t-c:\t Add a count of the occurrences of each unique domain.\n \t-s:\t Remove subdomains"

  local OPTIND=1
  while getopts "hcs" opt; do
    case $opt in
      c) count=true ;;
      s) noSubs=true ;;
      h)
        echo -e "$helpstring"
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
  cat "$list" | sed 's/https?:\/\///;s|\/.*||' >|"$tmp"

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
  # Decode HTML characters with sed
  # Usage: htmlDecode <string>
  local sedLocation
  sedLocation="${HOME}/dotfiles/config/sed/htmlDecode.sed"
  if [ -f "$sedLocation" ]; then
    echo "${1}" | sed -f "$sedLocation"
  else
    echo "error. Could not find sed translation file"
  fi
}

htmlencode() {
  # Encode HTML characters with sed
  # Usage: htmlEncode <string>

  local sedLocation
  sedLocation="${HOME}/dotfiles/config/sed/htmlEncode.sed"
  if [ -f "$sedLocation" ]; then
    echo "${1}" | sed -f "$sedLocation"
  else
    echo "error. Could not find sed translation file"
  fi
}

# URL-encode strings
#alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);"'

urlencode() {
  # URL encoding/decoding from: https://gist.github.com/cdown/1163649
  # Usage: urlencode <string>

  local LANG=C
  local length="${#1}"
  for ((i = 0; i < length; i++)); do
    local c="${1:i:1}"
    case $c in
      [a-zA-Z0-9.~_-]) printf "$c" ;;
      *) printf '%%%02X' "'$c" ;;
    esac
  done
}

alias urldecode='python -c "import sys, urllib as ul; print ul.unquote_plus(sys.argv[1])"'

lower() {
  # Convert stdin to lowercase.
  # usage:  text=$(lower <<<"$1")
  #         echo "MAKETHISLOWERCASE" | lower
  tr '[:upper:]' '[:lower:]'
}

upper() {
  # Convert stdin to uppercase.
  # usage:  text=$(upper <<<"$1")
  #         echo "MAKETHISUPPERCASE" | upper
  tr '[:lower:]' '[:upper:]'
}

ltrim() {
  # Removes all leading whitespace (from the left).
  local char=${1:-[:space:]}
  sed "s%^[${char//%/\\%}]*%%"
}

rtrim() {
  # Removes all trailing whitespace (from the right).
  local char=${1:-[:space:]}
  sed "s%[${char//%/\\%}]*$%%"
}

trim() {
  # Removes all leading/trailing whitespace
  # Usage examples:
  #     echo "  foo  bar baz " | trim  #==> "foo  bar baz"
  ltrim "$1" | rtrim "$1"
}

squeeze() {
  # Removes leading/trailing whitespace and condenses all other consecutive
  # whitespace into a single space.
  #
  # Usage examples:
  #     echo "  foo  bar   baz  " | squeeze  #==> "foo bar baz"

  local char=${1:-[[:space:]]}
  sed "s%\(${char//%/\\%}\)\+%\1%g" | trim "$char"
}
