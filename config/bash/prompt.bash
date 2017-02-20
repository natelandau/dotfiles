# ####################################################
#
# This bash script reads a series of plugins in to piece together
# a prompt heavily based on Powerline.  Two folders of plugins
# are used, a 'top' and a 'bottom'. Together they can create
# a two line prompt
#
# The order of the plugins is alphabetical as they are
# read from the directory.
#
# Each plugin must contain the following variables:
#
#   local fground=$whi          # The foreground text color
#   local bground=$ora          # The background color
#   local enabled=true          # If false, this segment will be ignored
#
# ####################################################

_setPrompt_() {
  local lastExit=$?
  local reset seperator oldBG ii iii
  seperator=""
  topPluginLocation=${HOME}/dotfiles/config/bash/prompt-plugins/top
  bottomPluginLocation=${HOME}/dotfiles/config/bash/prompt-plugins/bottom
  PS1="\n" # Add a newline at the beginning of the prompt
  oldBG=""

  reset="\[$(tput sgr0)\]"
  local whi=231;  local blu=27;     local ora=208;   local red=1;
  local grn=10;   local pur=5;      local yel=3;     local blck=233
  local mag=9;    local gry=241;    local blu2=38;   local gry2=239;

  _parseSegments_() {
    # This function is called by the prompt plugins to create the prompt

    local segment="$1"
    local fg="${2:-231}"
    local bg="${3:-241}"
    local enabled="${4:-true}"

    if ! ${enabled}; then return ; fi

    # if there was a previous segment, print the separator
    [ -n "$oldBG" ] && PS1+="\[$(tput setab $bg)\]\[$(tput setaf $oldBG)\]$seperator ${reset}"

    # Build the prompt from the plugin
    PS1+="\[$(tput setab $bg)\]\[$(tput setaf $fg)\]$segment ${reset}"

    # remember the current background for the seperator
    oldBG=$bg
  }

  # ########
  # Parse the top line
  # ########

  local ii=0
  if [ -d "${topPluginLocation}" ]; then
    for plugin in ${topPluginLocation}/*.bash; do
      [ -f "${plugin}" ] && source "${plugin}"
      [ -f "${plugin}" ] && ((ii++))
    done
  fi

  # Add a seperator at the end of the line
  [ -n "$oldBG" ] && PS1+="\[$(tput setaf $oldBG)\]$seperator ${reset}"
  oldBG=""

  # ########
  # Parse the bottom line
  # ########

  # Add a newline if any plugins were added to the top line
  [ $ii -gt 0 ] && PS1+="\n"

  local iii=0
  if [ -d "${bottomPluginLocation}" ]; then
    for plugin in ${bottomPluginLocation}/*.bash; do
      [ -f "${plugin}" ] && source "${plugin}"
      [ -f "${plugin}" ] && ((iii++))
    done
  fi



  # If we don't have any bottom plugins, add a simple prompt
  [ $iii -eq 0 ] && PS1+="\[$(tput setab $gry)\]\[$(tput setaf $whi)\]  ${reset}" && oldBG=$gry

  # Add a seperator at the end of the line
  [ -n "$oldBG" ] && PS1+="\[$(tput setaf $oldBG)\]$seperator ${reset}"

  export PS2="\[$(tput setaf $whi)\]→ $reset"
}
PROMPT_COMMAND=_setPrompt_
