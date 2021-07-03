_somePromptFunction_() {
  # set colors
  local fground="${bold}${fore_whi}"
  local bground="$back_gry2"
  local invertedBckgrnd="$fore_gry2" # Foreground of the current background
  local enabled=true # If false, this segment will be ignored
  local seperator=""

  #### ADD YOU CODE HERE ####
  # The final output of the segment must be added to '$promptSegment'

  # Output to prompt
  _parseSegments_ "${promptSegment}" "${fground}" "${bground}" "${invertedBckgrnd}" "${enabled}" "${seperator}"
}
_somePromptFunction_
