# Transform text using these functions.
# Some were adapted from https://github.com/jmcantrell/bashful

_escape_() {
  # v1.0.0
  # Escapes a string by adding \ before special chars
  # usage: _escape_ "Some text here"

  # shellcheck disable=2001
  echo "${@}" | sed 's/[]\.|$[ (){}?+*^]/\\&/g'
}

_htmlDecode_() {
  # v1.0.0
  # Decode HTML characters with sed
  # Usage: _htmlDecode_ <string>

  local sedFile
  sedFile="${HOME}/.sed/htmlDecode.sed"

  [ -f "${sedFile}" ] \
    && { echo "${1}" | sed -f "${sedFile}"; } \
    || return 1
}

_htmlEncode_() {
  # v1.0.0
  # Encode HTML characters with sed
  # Usage: _htmlEncode_ <string>

  local sedFile
  sedFile="${HOME}/.sed/htmlEncode.sed"

  [ -f "${sedFile}" ] \
    && { echo "${1}" | sed -f "${sedFile}"; } \
    || return 1
}

_lower_() {
  # Convert stdin to lowercase.
  # usage:  text=$(lower <<<"$1")
  #         echo "MAKETHISLOWERCASE" | _lower_
  tr '[:upper:]' '[:lower:]'
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

_upper_() {
  # Convert stdin to uppercase.
  # usage:  text=$(upper <<<"$1")
  #         echo "make this" | _upper_
  tr '[:lower:]' '[:upper:]'
}

_urlEncode_() {
  # v1.0.0
  # URL encoding/decoding from: https://gist.github.com/cdown/1163649
  # Usage: _urlEncode_ <string>

  local LANG=C
  local i

  for ((i = 0; i < ${#1}; i++)); do
    if [[ ${1:$i:1} =~ ^[a-zA-Z0-9\.\~_-]$ ]]; then
      printf "${1:$i:1}"
    else
      printf '%%%02X' "'${1:$i:1}"
    fi
  done
}

_urlDecode_() {
  # v1.0.0
  # Usage: _urlDecode_ <string>
  local url_encoded="${1//+/ }"
  printf '%b' "${url_encoded//%/\\x}"
}
