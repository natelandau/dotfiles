_printHost_() {
  # set colors
  local fground=$whi
  local bground=$gry2
  local enabled=true

  # If we are SSH'ed into a client, print the hostname
  if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    promptSegment=" \h"
  else
    promptSegment=" "
  fi

  _parseSegments_ "${promptSegment}" "${fground}" "${bground}" "${enabled}"
}
_printHost_