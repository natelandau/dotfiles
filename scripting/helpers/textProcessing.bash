# Transform text using these functions
# Some were adapted from https://github.com/jmcantrell/bashful

_escape_() {
  # DESC:   Escapes a string by adding \ before special chars
  # ARGS:   $@ (Required) - String to be escaped
  # OUTS:   Prints output to STDOUD
  # USAGE:  _escape_ "Some text here"

  # shellcheck disable=2001
  echo "${@}" | sed 's/[]\.|$[ (){}?+*^]/\\&/g'
}

_htmlDecode_() {
  # DESC:   Decode HTML characters with sed
  # ARGS:   $1 (Required) - String to be decoded
  # OUTS:   Prints output to STDOUT
  # USAGE:  _htmlDecode_ <string>
  # NOTE:   Must have a sed file containing replacements

  [[ $# -lt 1 ]] && fatal 'Missing required argument to _htmlDecode_()!'

  local sedFile
  sedFile="${HOME}/.sed/htmlDecode.sed"

  [ -f "${sedFile}" ] \
    && { echo "${1}" | sed -f "${sedFile}"; } \
    || return 1
}

_htmlEncode_() {
  # DESC:   Encode HTML characters with sed
  # ARGS:   $1 (Required) - String to be encoded
  # OUTS:   Prints output to STDOUT
  # USAGE:  _htmlEncode_ <string>
  # NOTE:   Must have a sed file containing replacements

  [[ $# -lt 1 ]] && fatal 'Missing required argument to _htmlEncode_()!'

  local sedFile
  sedFile="${HOME}/.sed/htmlEncode.sed"

  [ -f "${sedFile}" ] \
    && { echo "${1}" | sed -f "${sedFile}"; } \
    || return 1
}

_lower_() {
  # DESC:   Convert stdin to lowercase
  # ARGS:   None
  # OUTS:   None
  # USAGE:  text=$(_lower_ <<<"$1")
  #         echo "STRING" | _lower_
  tr '[:upper:]' '[:lower:]'
}

_upper_() {
  # DESC:   Convert stdin to uppercase
  # ARGS:   None
  # OUTS:   None
  # USAGE:  text=$(_upper_ <<<"$1")
  #         echo "STRING" | _upper_
  tr '[:lower:]' '[:upper:]'
}

_ltrim_() {
  # DESC:   Removes all leading whitespace (from the left)
  # ARGS:   None
  # OUTS:   None
  # USAGE:  text=$(_ltrim_ <<<"$1")
  #         echo "STRING" | _ltrim_
  local char=${1:-[:space:]}
  sed "s%^[${char//%/\\%}]*%%"
}

_rtrim_() {
  # DESC:   Removes all leading whitespace (from the right)
  # ARGS:   None
  # OUTS:   None
  # USAGE:  text=$(_rtrim_ <<<"$1")
  #         echo "STRING" | _rtrim_
  local char=${1:-[:space:]}
  sed "s%[${char//%/\\%}]*$%%"
}

_trim_() {
  # DESC:   Removes all leading/trailing whitespace
  # ARGS:   None
  # OUTS:   None
  # USAGE:  text=$(_trim_ <<<"$1")
  #         echo "STRING" | _trim_
  _ltrim_ "$1" | _rtrim_ "$1"
}

_urlEncode_() {
  # DESC:   URL encode a string
  # ARGS:   $1 (Required) - String to be encoded
  # OUTS:   Prints output to STDOUT
  # USAGE:  _urlEncode_ <string>
  # NOTE:   https://gist.github.com/cdown/1163649

  [[ $# -lt 1 ]] && fatal 'Missing required argument to _urlEncode_()!'

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
  # DESC:   Decode a URL encoded string
  # ARGS:   $1 (Required) - String to be decoded
  # OUTS:   Prints output to STDOUT
  # USAGE:  _urlDecode_ <string>

  [[ $# -lt 1 ]] && fatal 'Missing required argument to _urlDecode_()!'

  local url_encoded="${1//+/ }"
  printf '%b' "${url_encoded//%/\\x}"
}
