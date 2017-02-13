# Transform text using these functions.
# Some were adapted from https://github.com/jmcantrell/bashful

_lower_() {
  # Convert stdin to lowercase.
  # usage:  text=$(lower <<<"$1")
  #         echo "MAKETHISLOWERCASE" | _lower_
  tr '[:upper:]' '[:lower:]'
}

_upper_() {
  # Convert stdin to uppercase.
  # usage:  text=$(upper <<<"$1")
  #         echo "MAKETHISUPPERCASE" | _upper_
  tr '[:lower:]' '[:upper:]'
}

_ltrim_() {
  # Removes all leading whitespace (from the left).
  local char=${1:-[:space:]}
    sed "s%^[${char//%/\\%}]*%%"
}

_rtrim_() {
  # Removes all trailing whitespace (from the right).
  local char=${1:-[:space:]}
  sed "s%[${char//%/\\%}]*$%%"
}

_trim_() {
  # Removes all leading/trailing whitespace
  # Usage examples:
  #     echo "  foo  bar baz " | _trim_  #==> "foo  bar baz"
  _ltrim_ "$1" | _rtrim_ "$1"
}

_squeeze_() {
  # Removes leading/trailing whitespace and condenses all other consecutive
  # whitespace into a single space.
  #
  # Usage examples:
  #     echo "  foo  bar   baz  " | _squeeze_  #==> "foo bar baz"

  local char=${1:-[[:space:]]}
  sed "s%\(${char//%/\\%}\)\+%\1%g" | _trim_ "$char"
}

_escape_() {
  # Escapes a string by adding \ before special chars
  # usage: _escape_ "Some text here"

  # shellcheck disable=2001
  echo "${@}" | sed 's/[]\.|$[ (){}?+*^]/\\&/g' ;
}

_htmlDecode_() {
  # Decode HTML characters with sed
  # Usage: _htmlDecode_ <string>

  local sedFile
  sedFile="$HOME/.sed/htmlDecode.sed"

  [ -f "${sedFile}" ] && echo "${1}" | sed -f "${sedFile}" || return 1
}

_htmlEncode_() {
  # Encode HTML characters with sed
  # Usage: _htmlEncode_ <string>

  local sedFile
  sedFile="$HOME/.sed/htmlEncode.sed"

  [ -f "${sedFile}" ] && echo "${1}" | sed -f "${sedFile}" || return 1
}

_urlencode_() {
  # URL encoding/decoding from: https://gist.github.com/cdown/1163649
  # Usage: _urlencode_ <string>

  local length="${#1}"
  for (( i = 0; i < length; i++ )); do
    local c="${1:i:1}"
    case $c in
      [a-zA-Z0-9.~_-]) printf "%s" "$c" ;;
      *) printf '%%%02X' "'$c"
      esac
  done
}

_urldecode_() {
  # Usage: _urldecode_ <string>

  local url_encoded="${1//+/ }"
  printf '%b' "${url_encoded//%/\x}"
}