segmentUser() {
  local fground=$whi
  local bground=$gry
  local enabled=true  # If false, this segment will be ignored

  #local promptSegment=" ${USER} $(date "+%I:%M %p")"
  local promptSegment=" ${USER}"
  # Output to prompt
  _parseSegments_ "${promptSegment}" "${fground}" "${bground}" "${enabled}"
}
segmentUser