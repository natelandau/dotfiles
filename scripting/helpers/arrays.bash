_inArray_() {
  # DESC:   Determine if a value is in an arry
  # ARGS:   $1 (Required) - Value to search for
  #         $2 (Required) - Array written as ${ARRAY[@]}
  # OUTS:   true/false
  # USAGE:  if _inArray_ "VALUE" "${ARRAY[@]}"; then ...

  [[ $# -lt 2 ]] && fatal 'Missing required argument to _inArray_()!'

  local value="$1"
  shift
  for arrayItem in "$@"; do
    [[ "${arrayItem}" == "${value}" ]] && return 0
  done
  return 1
}

_join_() {
  # DESC:   joins items together with a user specified separator
  # ARGS:   $1 (Required) - Separator
  #         $@ (Required) - Items to be joined
  # OUTS:   Prints joined terms
  # USAGE:
  #   _join_ , a "b c" d #a,b c,d
  #   _join_ / var local tmp #var/local/tmp
  #   _join_ , "${foo[@]}" #a,b,c
  # NOTE:  http://stackoverflow.com/questions/1527049/bash-join-elements-of-an-array

  [[ $# -lt 2 ]] && fatal 'Missing required argument to _join_()!'

  local IFS="${1}"
  shift
  echo "${*}"
}

_setdiff_() {
  # DESC:  Return items that exist in ARRAY1 that are do not exist in ARRAY2
  # ARGS:  $1 (Required) - Array 1 in format ${ARRAY[*]}
  #        $2 (Required) - Array 2 in format ${ARRAY[*]}
  # OUTS:  Prints unique terms
  # USAGE: _setdiff_ "${array1[*]}" "${array2[*]}"
  # NOTE:  http://stackoverflow.com/a/1617303/142339

  [[ $# -lt 2 ]] && fatal 'Missing required argument to _setdiff_()!'

  local debug skip a b
  if [[ "$1" == 1 ]]; then
    debug=1
    shift
  fi
  if [[ "$1" ]]; then
    local setdiffA setdiffB setdiffC
    # shellcheck disable=SC2206
    setdiffA=($1)
    # shellcheck disable=SC2206
    setdiffB=($2)
  fi
  setdiffC=()
  for a in "${setdiffA[@]}"; do
    skip=
    for b in "${setdiffB[@]}"; do
      [[ "$a" == "$b" ]] && skip=1 && break
    done
    [[ "$skip" ]] || setdiffC=("${setdiffC[@]}" "$a")
  done
  [[ "$debug" ]] && for a in setdiffA setdiffB setdiffC; do
    #shellcheck disable=SC1087
    echo "$a ($(eval echo "\${#$a[*]}")) $(eval echo "\${$a[*]}")" 1>&2
  done
  [[ "$1" ]] && echo "${setdiffC[@]}"
}
