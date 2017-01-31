segmentTimestamp() {
  local fground=$whi
  local bground=$gry2
  local level=1  # '1' for top line. '2' for second.
  local enabled=true  # If false, this segment will be ignored

  local promptSegment=" $(date "+%H:%M:%S") "

  # Output to prompt
  _parseSegments_ "${promptSegment}" "${fground}" "${bground}" "${level}" "${enabled}"
}
segmentTimestamp