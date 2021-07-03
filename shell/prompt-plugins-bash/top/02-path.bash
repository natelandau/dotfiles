segmentPath() {
  local fground="${bold}${fore_whi}"
  local bground="$back_blu2"
  local invertedBckgrnd="$fore_blu2" # Foreground of the current background
  local settings_path_max_length=40
  local segment_seperator="" # ❱/
  local enabled=true            # If false, this segment will be ignored
  local seperator=""
  local promptSegment

  _segmentLockedDir() {
    local fground="${bold}${fore_blck}"
    local bground="$back_red"
    local invertedBckgrnd="$fore_red" # Foreground of the current background

    local enabled=true

    local promptSegment=""
    _parseSegments_ "${promptSegment}" "${fground}" "${bground}" "${invertedBckgrnd}" "${enabled}" "${seperator}"
  }

  # if directory is locked, put a padlock in front of path
  if [[ ! -w "$PWD" ]]; then _segmentLockedDir; fi

  # Get Path
  local path_value
  local i
  local wdir="$PWD"
  
  if [[ "$OSTYPE" == "darwin"* && -e "${HOME}/Library/Fonts/Meslo LG S DZ Regular Nerd Font Complete.otf" ]]; then
    wdir="${wdir/$HOME/\ﱮ }"
  else
    wdir="${wdir/$HOME/\~}"
  fi

  if [[ "${#wdir}" -gt "$settings_path_max_length" ]]; then
    wdir="$(dirname "${wdir}" | sed -e "s;\(/.\)[^/]*;\1;g")/$(basename "${wdir}")"
  fi

  IFS=/ read -r -a wdir_array <<<"$wdir"
  if [[ "${#wdir_array[@]}" -gt 1 ]]; then
    for i in "${!wdir_array[@]}"; do
      dir=${wdir_array["$i"]}
      segment_value=" $dir "
      [[ "$((i + 1))" -eq "${#wdir_array[@]}" ]] && unset segment_seperator
      path_value="${path_value}${segment_value}${segment_seperator}"
    done
    promptSegment="${path_value}"
  else
    promptSegment="${wdir}"
  fi

  # Output to prompt
  _parseSegments_ "${promptSegment}" "${fground}" "${bground}" "${invertedBckgrnd}" "${enabled}" "${seperator}"


  unset path_value
  unset wdir
  unset printPath
}
segmentPath
