segmentTimestamp() {
  local fground=$whi
  local bground=$gry2
  local enabled=true  # If false, this segment will be ignored

  local promptSegment=" $(date "+%H:%M:%S") "

  # Output to prompt
  _parseSegments_ "${promptSegment}" "${fground}" "${bground}" "${enabled}"
}
segmentTimestamp