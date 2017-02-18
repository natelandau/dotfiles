_somePromptFunction_() {
  # set colors
  local fground=$whi
  local bground=$gry2
  #enable or disable this segment
  local enabled=true

  #### ADD YOU CODE HERE ####
  # The final output of the segment must be added to '$promptSegment'


  # Output to prompt
  _parseSegments_ "${promptSegment}" "${fground}" "${bground}" "${enabled}"
}
_somePromptFunction_