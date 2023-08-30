segmentUser() {
  local fground="${bold}${fore_whi}"
  local bground="$back_gry"
  local invertedBckgrnd="$fore_gry" # Foreground of the current background
  local enabled=true
  local separator=""

  #local promptSegment=" ${USER} $(date "+%I:%M %p")"
  local promptSegment="  ${USER}"
  # Output to prompt
    _parseSegments_ "${promptSegment}" "${fground}" "${bground}" "${invertedBckgrnd}" "${enabled}" "${separator}"
}
segmentUser
