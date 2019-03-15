# Functions needed
_zshWifiSignal_(){
  # Originally found here: https://github.com/bhilburn/powerlevel9k/wiki/Show-Off-Your-Config
  if [[ "$OSTYPE" == "darwin"* ]]; then
    local output=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport -I)
    local airport=$(echo $output | grep 'AirPort' | awk -F': ' '{print $2}')

    if [ "$airport" = "Off" ]; then
      local color='%F{black}'
      echo -n "%{$color%}Wifi Off"
    else
      local ssid=$(echo $output | grep ' SSID' | awk -F': ' '{print $2}')
      local speed=$(echo $output | grep 'lastTxRate' | awk -F': ' '{print $2}')
      local color='%F{black}'

      [[ $speed -gt 100 ]] && color='%F{black}'
      [[ $speed -lt 50 ]] && color='%F{red}'

      echo -n "%{$color%}$speed Mbps \uf1eb%{%f%}" # removed char not in my PowerLine font
    fi
  elif command -v nmcli &>/dev/null; then
    local signal=$(nmcli device wifi | grep yes | awk '{print $8}')
    local color='%F{yellow}'
    [[ $signal -gt 75 ]] && color='%F{green}'
    [[ $signal -lt 50 ]] && color='%F{red}'
    echo -n "%{$color%}\uf230  $signal%{%f%}" # \uf230 is 
  else
    return 0
  fi
}

# backgorund of terminal: grey236

# Prompt Elements
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  root_indicator
  context
  dir_writable
  dir
  vcs
  status
  ssh
  )

POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  time
  #battery
  ip
  custom_wifi_signal
  )

# Set nerdfont (https://github.com/ryanoasis/nerd-fonts)
POWERLEVEL9K_MODE='nerdfont-complete'

POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="%F{blue}\u256D\u2500%f"
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%F{blue}\u2570\uf460%f "

# General Configs
POWERLEVEL9K_PROMPT_ON_NEWLINE=true

# Wifi signal
POWERLEVEL9K_CUSTOM_WIFI_SIGNAL="_zshWifiSignal_"
POWERLEVEL9K_CUSTOM_WIFI_SIGNAL_BACKGROUND="white"
POWERLEVEL9K_CUSTOM_WIFI_SIGNAL_FOREGROUND="black"

# Battery
POWERLEVEL9K_BATTERY_CHARGING='yellow'
POWERLEVEL9K_BATTERY_CHARGED='green'
POWERLEVEL9K_BATTERY_DISCONNECTED='$DEFAULT_COLOR'
POWERLEVEL9K_BATTERY_LOW_THRESHOLD='10'
POWERLEVEL9K_BATTERY_LOW_COLOR='red'
POWERLEVEL9K_BATTERY_HIDE_ABOVE_THRESHOLD="90"
POWERLEVEL9K_BATTERY_ICON='\uf1e6'

# Context
# Set Default user to only display context when NOT default
whoamiregex="nlandau|natelandau|ncl"
[[ "$(whoami)" =~ $whoamiregex ]] && DEFAULT_USER=$(whoami)
POWERLEVEL9K_CONTEXT_TEMPLATE='%n@%m'
POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND='white'
POWERLEVEL9K_CONTEXT_DEFAULT_BACKGROUND='black'
POWERLEVEL9K_CONTEXT_REMOTE_FOREGROUND='white'
POWERLEVEL9K_CONTEXT_REMOTE_BACKGROUND='black'

# Time
POWERLEVEL9K_TIME_FORMAT="%D{\uf017 %H:%M \uf073 %m/%d/%y}"
POWERLEVEL9K_TIME_BACKGROUND='white'

# Dir
POWERLEVEL9K_HOME_ICON='\uf015'
POWERLEVEL9K_HOME_SUB_ICON='\uf015'
POWERLEVEL9K_SHORTEN_DELIMITER="\uf6d7"
POWERLEVEL9K_DIR_OMIT_FIRST_CHARACTER=true
POWERLEVEL9K_FOLDER_ICON=''
POWERLEVEL9K_ETC_ICON=''
POWERLEVEL9K_SHORTEN_DIR_LENGTH='2'
POWERLEVEL9K_SHORTEN_STRATEGY="truncate_to_first_and_last"

# IP
POWERLEVEL9K_IP_FOREGROUND="white"
POWERLEVEL9K_IP_BACKGROUND="grey236"

# Last Command Status
POWERLEVEL9K_STATUS_VERBOSE=true
POWERLEVEL9K_STATUS_CROSS=false

# Version Control (VCS)
POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='yellow'
POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND='yellow'
POWERLEVEL9K_VCS_UNTRACKED_ICON='?'
POWERLEVEL9K_CHANGESET_HASH_LENGTH="0"