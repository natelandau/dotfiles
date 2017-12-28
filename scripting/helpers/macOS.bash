# Functions for use on computers running  MacOS

_haveScriptableFinder_() {
  # Determine whether we can script the Finder or not
  # We must have a valid PID for Finder, plus we cannot be in
  # `screen` (another thing that's broken)
  local finder_pid
  finder_pid="$(pgrep -f /System/Library/CoreServices/Finder.app)"

  if [[ (${finder_pid} -gt 1) && ("$STY" == "") ]]; then
    return 0
  else
    return 1
  fi
}

_guiInput_() {
  # Ask for user input using a Mac dialog box.
  # Defaults to use the prompt: "Password". Pass an option to change that text.
  #
  # Credit: https://github.com/herrbischoff/awesome-osx-command-line/blob/master/functions.md
  if _haveScriptableFinder_; then
    guiPrompt="${1:-Password:}"
    guiInput=$(
      osascript &>/dev/null <<EOF
      tell application "System Events"
          activate
          text returned of (display dialog "${guiPrompt}" default answer "" with hidden answer)
      end tell
EOF
  )
    echo -n "${guiInput}"
  else
    error "No GUI input without macOS"
    return 1
  fi

}