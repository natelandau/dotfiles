segmentTimestamp() {
  local fground="${bold}${fore_whi}"
  local bground="$back_gry2"
  local invertedBckgrnd="$fore_gry2" # Foreground of the current background
  local enabled=true # If false, this segment will be ignored
  local seperator=""

  local promptSegment=" $(date "+%H:%M:%S") "

  # Output to prompt
  _parseSegments_ "${promptSegment}" "${fground}" "${bground}" "${invertedBckgrnd}" "${enabled}" "${seperator}"
}
segmentTimestamp
