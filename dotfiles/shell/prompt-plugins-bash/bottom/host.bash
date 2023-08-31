_printHost_() {
  # set colors
  local fground="${bold}${fore_whi}"
  local bground="$back_gry2"
  local invertedBckgrnd="$fore_gry2" # Foreground of the current background
  local enabled=true
  local separator=""

  # If we are SSH'ed into a client, print the hostname
  if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    promptSegment=" \h"
  elif [[ "$OSTYPE" == "darwin"* && -e "${HOME}/Library/Fonts/Meslo LG S DZ Regular Nerd Font Complete.otf" ]]; then
    promptSegment="  "
  else
    promptSegment=" \h"
  fi

    _parseSegments_ "${promptSegment}" "${fground}" "${bground}" "${invertedBckgrnd}" "${enabled}" "${separator}"

}
_printHost_
