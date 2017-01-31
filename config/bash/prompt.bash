# This prompt is heavily inspired by this great repository
# https://github.com/brujoand/sbp
#
# ####################################################
#
# This bash script reads a series of plugins to piece together
# a prompt heavily based on Powerline.
#
# The order of the plugins is alphabetical as they are
# read from the directory.
#
# Each plugin must contain the following variables:
#
#   local fground=$whi          # The foreground text color
#   local bground=$ora          # The background color
#   local level=1               # '1' for top line. '2' for second.
#   local enabled=true          # If false, this segment will be ignored
#
# ####################################################
function _buildPrompt_() {
  local lastExit=$?
  local prompt=""
  local prevBground=""

  # Colors
  local whi=231;  local blu=27;     local ora=208;   local red=1;
  local grn=10;   local pur=5;      local yel=3;     local blck=233
  local mag=9;    local gry=241;    local blu2=38;   local gry2=239;

  _separateSegments_() {
    local fromColor="$1"
    local toColor="$2"
    local textColor="$3"
    local level="$4"
    local segmentSeperator=""

    if [ $level -eq 1 ]; then
      prompt1+="$(tput setab $toColor)$(tput setaf $fromColor)${segmentSeperator}$(tput setaf $textColor)"
    elif [ $level -eq 2 ]; then
      prompt2+="$(tput setab $toColor)$(tput setaf $fromColor)${segmentSeperator}$(tput setaf $textColor)"
    fi
  }

  _parseSegments_() {
    local segment="$1"
    local fground="${2:-$whi}"
    local bground="${3:-$blu2}"
    local level="${4:-1}"
    local enabled="${5:-true}"

    if ! ${enabled}; then return ; fi

    if [ $level -eq 1 ]; then
      if [ -z $prevBground1 ]; then
        prompt1="$(tput setab $bground)$(tput setaf $fground)"
        prompt1+="$segment "
        prevBground1="$bground"
      else
        _separateSegments_ "$prevBground1" "$bground" "$fground" "$level"
        prompt1+="$segment"
        prevBground1="$bground"
      fi
    elif [ $level -eq 2 ]; then
      if [ -z $prevBground2 ]; then
        prompt2="\n$(tput setab $bground)$(tput setaf $fground)"
        prompt2+="$segment"
        prevBground2="$bground"
      else
        _separateSegments_ "$prevBground2" "$bground" "$fground" "$level"
        prompt2+="$segment"
        prevBground2="$bground"
      fi
    fi
  }

  promptPluginLocations=(
    ${HOME}/dotfiles/config/bash/prompt-plugins/
    )

  for promptPluginLocation in "${promptPluginLocations[@]}"; do
    if [ -d "${promptPluginLocation}" ]; then
      for plugin in ${promptPluginLocation}/*.bash; do
        if [ -f "${plugin}" ]; then
          source "${plugin}"
        fi
      done
    fi
  done


  # Add arrows to end of segment lines
  if [ -n "$prevBground1" ]; then
    prompt1+="${RESET}$(tput setaf $prevBground1)${RESET} "
  fi
  if [ -n "$prevBground2" ]; then
    prompt2+="${RESET}$(tput setaf $prevBground2)${RESET} "
  fi

  # If not plugins for the second line, add a default prompt
  if [ -z "$prompt2" ]; then
    prompt2="\n$(tput setab $gry)$(tput setaf $whi) $ ${RESET}$(tput setaf $gry)${RESET} "
  fi

  # Build the whole prompt
  local fullPrompt="${prompt1}${prompt2}"

  # Output the fully built prompt
  echo -e "$fullPrompt"

}


 export PS1="\n\$(_buildPrompt_)"
 export PS2="\[$WHITE\]→ \[$RESET\]"

# ####################################################


# prompt_git() {
#   local s=''
#   local branchName=''

#   # Check if the current directory is in a Git repository.
#   if [ "$(git rev-parse --is-inside-work-tree &>/dev/null; echo "${?}")" == '0' ]; then
#     # check if the current directory is in .git before running git checks

#     if [ "$(git rev-parse --is-inside-git-dir 2> /dev/null)" == 'false' ]; then

#       # Ensure the index is up to date.
#       git update-index --really-refresh -q &>/dev/null

#       # Check for uncommitted changes in the index.
#       if ! git diff --quiet --ignore-submodules --cached; then
#         s+='+'
#       fi

#       # Check for unstaged changes.
#       if ! git diff-files --quiet --ignore-submodules --; then
#         s+='!'
#       fi

#       # Check for untracked files.
#       if [ -n "$(git ls-files --others --exclude-standard)" ]; then
#         s+='?'
#       fi

#       # Check for stashed files.
#       if git rev-parse --verify refs/stash &>/dev/null; then
#         s+='$'
#       fi
#     fi

#     # Get the short symbolic ref.
#     # If HEAD isn’t a symbolic ref, get the short SHA for the latest commit
#     # Otherwise, just give up.
#     branchName="$(git symbolic-ref --quiet --short HEAD 2> /dev/null || \
#       git rev-parse --short HEAD 2> /dev/null || \
#       echo '(unknown)')";

#     [ -n "${s}" ] && s=" [${s}]";

#     echo -e "${1}${branchName}${s}";
#   else
#     return;
#   fi
# }

# export PS1="\[$WHITE\]________________________________________________________________________________\n| \
# \[${BOLD}${MAGENTA}\]\u \[$WHITE\]at \[$ORANGE\]\h \
# \[$WHITE\]in \[$GREEN\]\w\[$WHITE\]\
# \$([[ -n \$(git branch 2> /dev/null) ]] && echo \" on \")\
# \[$PURPLE\]\$(prompt_git \"$PRUPLE\")\[$WHITE\]\[$RESET\] \
# \n\[$WHITE\]| =>\[$RESET\] "
# #