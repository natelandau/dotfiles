
if [[ "$OSTYPE" == "darwin"* ]]; then

  ## ALIASES ##
  alias chrome='open -a Google\ Chrome'         # chrome:   Open item in Google Chrome browser
  alias f='open -a Finder ./'                   # f:      Opens current directory in MacOS Finder
  alias cpwd='pwd|tr -d "\n"|pbcopy'            # cpwd:     Copy the current path to mac clipboard
  alias cl="fc -e -|pbcopy"                     # cl:     Copy output of last command to mac clipboard
  alias c="caffeinate -ism"
  alias cleanupDS="find . -type f -name '*.DS_Store' -ls -delete"
  alias finderShowHidden='defaults write com.apple.finder AppleShowAllFiles TRUE'
  alias finderHideHidden='defaults write com.apple.finder AppleShowAllFiles FALSE'
  alias screensaverDesktop='/System/Library/Frameworks/ScreenSaver.framework/Resources/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine -background'

  # Opens any file in MacOS Quicklook Preview
  ql () { qlmanage -p "$*" >& /dev/null; }

  # Clean up LaunchServices to remove duplicates in the "Open With" menu
  alias cleanupLS="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder"

  function unmountDrive() {
    # unmountDrive - If an AFP drive is mounted, this will unmount the volume.
    if [ -d "$1" ]; then
      diskutil unmount "$1"
    fi
  }

  function unquarantine() {
    # unquarantine: Manually remove a downloaded app or file from the quarantine
    for attribute in com.apple.metadata:kMDItemDownloadedDate com.apple.metadata:kMDItemWhereFroms com.apple.quarantine; do
      xattr -r -d "$attribute" "$@"
    done
  }

  function lst() {
    # lst:  Search for files based on OSX native tags
    #       More info:  http://brettterpstra.com/2013/10/28/mavericks-tags-spotlight-and-terminal/
    local query
    # if the first argument is "all" (case insensitive),
    # a boolean AND search will be used. Defaults to OR.
    bool="OR"
    [[ $1 =~ "all" ]] && bool="AND" && shift

    # if there's no argument or the argument is "+"
    # list all files with any tags
    if [[ -z $1 || $1 == "+" ]]; then
      query="kMDItemUserTags == '*'"
    # if the first argument is "-"
    # list only files without tags
    elif [[ $1 == "-" ]]; then
      query="kMDItemUserTags != '*'"
    # Otherwise, build a Spotlight syntax query string
    else
      query="tag:$1"
      shift
      for tag in "$@"; do
        query="$query $bool tag:$tag"
      done
    fi

    while IFS= read -r -d $'\0' line; do
      echo "${line#$(pwd)/}"
    done < <(mdfind -onlyin . -0 "$query")
  }


  ## SPOTLIGHT MAINTENANCE ##
  alias spot-off="sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist"
  alias spot-on="sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist"

  # If the 'mds' process is eating tons of memory it is likely getting hung on a file.
  # This will tell you which file that is.
  alias spot-file="lsof -c '/mds$/'"

  # Search for a file using MacOS Spotlight's metadata
  spotlight () { mdfind "kMDItemDisplayName == '$1'wc"; }
fi