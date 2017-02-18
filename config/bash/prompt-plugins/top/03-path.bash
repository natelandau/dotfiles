segmentPath() {
  local fground=$whi
  local bground=$blu2
  local settings_path_max_length=40
  local segment_seperator="" # ❱/
  local enabled=true  # If false, this segment will be ignored

  local promptSegment

  _segmentLockedDir() {
    local fground=$blck
    local bground=$red
    local enabled=true

    local promptSegment=""
    _parseSegments_ "${promptSegment}" "${fground}" "${bground}" "${enabled}"
  }

  # if directory is locked, put a padlock in front of path
  if [[ ! -w "$PWD" ]] ; then _segmentLockedDir; fi

  # Get Path
  local path_value;   local i
  local wdir="$(PWD)"
  wdir="${wdir/$HOME/\~}"

  if [[ "${#wdir}" -gt "$settings_path_max_length" ]]; then
    wdir="$(dirname "${wdir}" | sed -e "s;\(/.\)[^/]*;\1;g")/$(basename "${wdir}")"
  fi

  IFS=/ read -r -a wdir_array <<<"$wdir"
  if [[ "${#wdir_array[@]}" -gt 1 ]]; then
    for i in "${!wdir_array[@]}"; do
      dir=${wdir_array["$i"]}
      segment_value=" $dir "
      [[ "$(( i + 1 ))" -eq "${#wdir_array[@]}" ]] && unset segment_seperator
      path_value="${path_value}${segment_value}${segment_seperator}"
    done
    promptSegment="$path_value"
  else
    promptSegment=" $wdir "
  fi

  # Output to prompt
  _parseSegments_ "${promptSegment}" "${fground}" "${bground}" "${enabled}"

  unset path_value
  unset wdir
  unset printPath
}
segmentPath