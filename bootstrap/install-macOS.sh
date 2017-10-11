#!/usr/bin/env bash

version="1.0.0"

_mainScript_() {

  [[ "$OSTYPE" != "darwin"* ]] \
    && die "We are not on macOS"

  # Set Variables
    baseDir="$(_findBaseDir_)"
    rootDIR="$(dirname "$baseDir")"
    privateInstallScript="${HOME}/dotfiles-private/privateInstall.sh"
    pluginScripts="${baseDir}/lib/mac-plugins"

  # Config files
    configSymlinks="${baseDir}/config/symlinks.yaml"
    configHomebrew="${baseDir}/config/homebrew.yaml"
    configCasks="${baseDir}/config/homebrewCasks.yaml"
    configNode="${baseDir}/config/node.yaml"
    configRuby="${baseDir}/config/ruby.yaml"

  scriptFlags=()
    ( $dryrun ) && scriptFlags+=(--dryrun)
    ( $quiet ) && scriptFlags+=(--quiet)
    ( $printLog ) && scriptFlags+=(--log)
    ( $verbose ) && scriptFlags+=(--verbose)
    ( $debug ) && scriptFlags+=(--debug)
    ( $strict ) && scriptFlags+=(--strict)

  _commandLineTools_() {
    local x

    info "Checking for Command Line Tools..."

    if ! xcode-select --print-path &> /dev/null; then

      # Prompt user to install the XCode Command Line Tools
      xcode-select --install > /dev/null 2>&1

      # Wait until the XCode Command Line Tools are installed
      until xcode-select --print-path &> /dev/null 2>&1; do
        sleep 5
      done

      x=$(find '/Applications' -maxdepth 1 -regex '.*/Xcode[^ ]*.app' -print -quit)
      if [ -e "$x" ]; then
        sudo xcode-select -s "$x"
        sudo xcodebuild -license accept
      fi
      success 'Install XCode Command Line Tools'
    else
      success "Command Line Tools installed"
    fi
  }
  _commandLineTools_

  # Create symlinks
  if _seekConfirmation_ "Create symlinks to configuration files?"; then
    header "Creating Symlinks"
    _doSymlinks_ "${configSymlinks}"
  fi

  _homebrew_() {
    local tap
    local package
    local testInstalled
    local t="${tmpDir}/${RANDOM}.${RANDOM}.${RANDOM}.txt"
    local c="$1"  # Config YAML file

    if ! _seekConfirmation_ "Install Homebrew Packages?"; then return; fi

    info "Checking for Homebrew..."
    ( _checkForHomebrew_ )

    [ ! -f "$c" ] \
      && { error "Can not find config file '$c'"; return 1; }

    # Parse & source Config File
    # shellcheck disable=2015
    ( _parseYAML_ "${c}" > "${t}" ) \
      && { if $verbose; then verbose "-- Config Variables"; _readFile_ "$t"; fi; } \
      || die "Could not parse YAML config file"

    _sourceFile_ "$t"

    # Brew updates can take forever if we're not bootstrapping. Show the output
    local v=$verbose; verbose=true;

    header "Updating Homebrew"
    _execute_ "caffeinate -ism brew update"
    _execute_ "caffeinate -ism brew doctor"
    _execute_ "caffeinate -ism brew upgrade"

    header "Installing Homebrew Taps"
    # shellcheck disable=2154
    for tap in "${homebrewTaps[@]}"; do
      tap=$(echo "${tap}" | cut -d'#' -f1 | _trim_) # remove comments if exist
      _execute_ "brew tap ${tap}"
    done

    header "Installing Homebrew Packages"
    # shellcheck disable=2154
    for package in "${homebrewPackages[@]}"; do

      package=$(echo "${package}" | cut -d'#' -f1 | _trim_) # remove comments if exist
      testInstalled=$(echo "${package}" | cut -d' ' -f1 | _trim_)  # strip flags from package names

      if brew ls --versions "$testInstalled" > /dev/null; then
        info "$testInstalled already installed"
      else
        _execute_ "caffeinate -ism brew install ${package}" "Install ${testInstalled}"
      fi
    done

    _execute_ "brew cleanup"  # cleanup after ourselves
    verbose=$v                # Reset verbose settings
  }
  _homebrew_ "$configHomebrew"

  _homebrewCasks_() {
    local cask
    local testInstalled
    local t="${tmpDir}/${RANDOM}.${RANDOM}.${RANDOM}.txt"
    local c="$1"  # Config YAML file

    if ! _seekConfirmation_ "Install Homebrew Casks?"; then return; fi

    info "Checking for Homebrew..."
    _checkForHomebrew_

    [ ! -f "$c" ] \
      && { error "Can not find config file '$c'"; return 1; }

    # Parse & source Config File
    # shellcheck disable=2015
    ( _parseYAML_ "${c}" > "${t}" ) \
      && { if $verbose; then verbose "-- Config Variables"; _readFile_ "$t"; fi; } \
      || die "Could not parse YAML config file"

    _sourceFile_ "$t"

    # Brew updates can take forever if we're not bootstrapping. Show the output
    saveVerbose=$verbose; verbose=true;

    header "Updating Homebrew"
    _execute_ "caffeinate -ism brew update"
    _execute_ "caffeinate -ism brew doctor"

    header "Installing Casks"
    # shellcheck disable=2154
    for cask in "${homebrewCasks[@]}"; do

      cask=$(echo "${cask}" | cut -d'#' -f1 | _trim_) # remove comments if exist

      # strip flags from package names
      testInstalled=$(echo "${cask}" | cut -d' ' -f1 | _trim_)

      if brew cask ls "${testInstalled}" &> /dev/null; then
        info "${testInstalled} already installed"
      else
        _execute_ "brew cask install $cask" "Install ${testInstalled}"
      fi
    done

    _execute_ "brew cleanup"  # cleanup after ourselves
    verbose=$saveVerbose      # Reset verbose settings
  }
  _homebrewCasks_ "$configCasks"

  _node_() {
    local package
    local npmPackages
    local modules
    local t="${tmpDir}/${RANDOM}.${RANDOM}.${RANDOM}.txt"
    local c="$1"  # Config YAML file

    if ! _seekConfirmation_ "Install Node Packages?"; then return; fi

    [ ! -f "$c" ] \
      && { error "Can not find config file '$c'"; return 1; }

    # Parse & source Config File
    # shellcheck disable=2015
    ( _parseYAML_ "${c}" > "${t}" ) \
      && { if $verbose; then verbose "-- Config Variables"; _readFile_ "$t"; fi; } \
      || die "Could not parse YAML config file"

    _sourceFile_ "$t"

    header "Installing global node packages"

    #confirm node is installed
    if test ! "$(which node)"; then
      notice "Can not install npm packages without node. Installing now"
      info "Checking for Homebrew..."
      _checkForHomebrew_
      if ! brew install node; then
        warning "Can not install node. Please rerun script."
        return 1
      fi
    fi

    # Grab packages already installed
    { pushd "$(npm config get prefix)/lib/node_modules"; installed=(*); popd; } >/dev/null

    #Show nodes's detailed install information
    saveVerbose=$verbose; verbose=true;

    # If comments exist in the list of npm packaged to be installed remove them
    # shellcheck disable=2154
    for package in "${nodePackages[@]}"; do
      npmPackages+=($(echo "${package}" | cut -d'#' -f1 | _trim_) )
    done

    # Install packages that do not already exist
    modules=($(_setdiff_ "${npmPackages[*]}" "${installed[*]}"))
    if (( ${#modules[@]} > 0 )); then
      pushd ${HOME} > /dev/null; _execute_ "npm install -g ${modules[*]}"; popd > /dev/null;
    else
      info "All node packages already installed"
    fi

    # Reset verbose settings
    verbose=$saveVerbose
  }
  _node_ "$configNode"

  _ruby_() {
    local RUBYVERSION="2.3.4 " # Version of Ruby to install via RVM
    local t="${tmpDir}/${RANDOM}.${RANDOM}.${RANDOM}.txt"
    local c="$1"  # Config YAML file
    local gem
    local testInstalled

    if ! _seekConfirmation_ "Install Ruby Packages?"; then return; fi
    header "Installing RVM and Ruby packages"

    [ ! -f "$c" ] \
      && { error "Can not find config file '$c'"; return 1; }

    # Parse & source Config File
    # shellcheck disable=2015
    ( _parseYAML_ "${c}" > "${t}" ) \
      && { if $verbose; then verbose "-- Config Variables"; _readFile_ "$t"; fi; } \
      || die "Could not parse YAML config file"

    _sourceFile_ "$t"

    info "Checking for RVM (Ruby Version Manager)..."
    pushd ${HOME} &> /dev/null
    # Check for RVM
    if ! command -v rvm &> /dev/null; then
      _execute_ "curl -L https://get.rvm.io | bash -s stable --ruby"
      _execute_ "source ${HOME}/.rvm/scripts/rvm"
      _execute_ "source ${HOME}/.bash_profile"
      #rvm get stable --autolibs=enable
      _execute_ "rvm install ${RUBYVERSION}"
      _execute_ "rvm use ${RUBYVERSION} --default"
    fi
    success "RVM and Ruby are installed"


    header "Installing global ruby gems"
    local v=$verbose; verbose=true;

    # shellcheck disable=2154
    for gem in "${rubyGems[@]}"; do

      # Strip comments
      gem=$(echo "$gem" | cut -d'#' -f1 | _trim_)

      # strip flags from package names
      testInstalled=$(echo "$gem" | cut -d' ' -f1 | _trim_)

      if ! gem list "$testInstalled" -i >/dev/null; then
        _execute_ "gem install ${gem}"
      else
        info "${testInstalled} already installed"
      fi
    done

    popd &> /dev/null

    verbose=$v
  }
  _ruby_ "$configRuby"

  _runPlugins_() {
    local plugin pluginName

    header "Running plugin scripts"

    if [ ! -d "$pluginScripts" ]; then die "Can't find plugins."; fi

    # Run the bootstrap scripts in numerical order

    set +e # Don't quit install.sh when a sub-script fails
    for plugin in ${pluginScripts}/*.sh; do
      pluginName="$(basename ${plugin})"
      pluginName="$(echo $pluginName | sed -e 's/[0-9][0-9]-//g' | sed -e 's/-/ /g' | sed -e 's/\.sh//g')"
      if _seekConfirmation_ "Run '${pluginName}' plugin?"; then
        "${plugin}" "${scriptFlags[*]}" --verbose --rootDIR "$rootDIR"
      fi
    done
  }
  _runPlugins_

  _privateRepo_() {
    if _seekConfirmation_ "Run Private install script"; then
      [ ! -f "${privateInstallScript}" ] \
        && { warning "Could not find private install script" ; return 1; }
      "${privateInstallScript}" "${scriptFlags[*]}"
    fi
  }
  _privateRepo_

}  # end _mainScript_


# ### CUSTOM FUNCTIONS ###########################

_doSymlinks_() {
  # Takes an input of a configuration YAML file and creates symlinks from it.
  # Note that the YAML file must group symlinks in a section named 'symlinks'
  local l                                     # link
  local d                                     # destination
  local s                                     # source
  local c="${1:?Must have a config file}"     # config file
  local t                                     # temp file
  local line

  t="${tmpDir}/${RANDOM}.${RANDOM}.${RANDOM}.txt"

  [ ! -f "$c" ] \
    && { error "Can not find config file '$c'"; return 1; }

  # Parse & source Config File
  # shellcheck disable=2015
  ( _parseYAML_ "${c}" > "${t}" ) \
    && { if $verbose; then verbose "-- Config Variables"; _readFile_ "$t"; fi; } \
    || die "Could not parse YAML config file"

  _sourceFile_ "$t"

  [ "${#symlinks[@]}" -eq 0 ] \
    && { warning "No symlinks found in '$c'"; return 1; }

  # For each link do the following
  for l in "${symlinks[@]}"; do
    verbose "Working on: $l"

    # Parse destination and source
    d=$(echo "$l" | cut -d':' -f1 | _trim_)
    s=$(echo "$l" | cut -d':' -f2 | _trim_)
    s=$(echo "$s" | cut -d'#' -f1 | _trim_) # remove comments if exist

    # Add the rootDIR to source if it exists
    [ -n "$rootDIR" ] \
      && s="${rootDIR}/${s}"

    # Grab the absolute path for the source
    s="$(_realpath_ "${s}")"

    # If we can't find a source file, skip it
    [ ! -e "${s}" ] \
      && { warning "Can't find source '${s}'"; continue; }

    ( _makeSymlink_ "${s}" "${d}" ) \
      || { warning "_makeSymlink_ failed for source: '$s'"; return 1; }

  done
}

_checkForHomebrew_() {

  if ! command -v brew &> /dev/null; then
    notice "Installing Homebrew..."
    #   Ensure that we can actually, like, compile anything.
    if [[ ! $(command -v gcc) || ! "$(command -v git)" ]]; then
      _commandLineTools_
    fi

    # Install Homebrew
    ( _execute_ "ruby -e $(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" "Install Homebrew" ) \
        || { return 1; }
    brew analytics off
  else
    return 0
  fi
}

# ### SHARED FUNCTIONS ###########################

_backupFile_() {
  # v1.0.0
  # Creates a copy of a specified file taking two inputs:
  #   $1 - File to be backed up
  #   $2 - Destination
  #
  # NOTE: dotfiles have their leading '.' removed in their backup
  #
  # Usage:  _backupFile_ "sourcefile.txt" "some/backup/dir"

  local s="$1"
  local d="${2:-backup}"
  local n

  [ ! -e "$s" ] \
    &&  { error "Source '$s' not found"; return 1; }
  #[ ! -d "$d" ] \
  #  &&  { error "Destination '$d' not found"; return 1; }

  if ! _haveFunction_ "_execute_"; then
    error "need function _execute_"; return 1;
  fi
  if ! _haveFunction_ "_uniqueFileName_"; then
    error "need function _uniqueFileName_"; return 1;
  fi

  [ ! -d "$d" ] \
    && _execute_ "mkdir \"$d\"" "Creating backup directory"

  if [ -e "$s" ]; then
    n="$(basename "$s")"
    n="$(_uniqueFileName_ "${d}/${s#.}")"
    _execute_ "cp -R \"${s}\" \"${d}/${n##*/}\"" "Backing up: '${s}' to '${d}/${n##*/}'"
  fi
}

_execute_() {
  # v1.0.2
  # _execute_ - wrap an external command in '_execute_' to push native output to /dev/null
  #           and have control over the display of the results.  In "dryrun" mode these
  #           commands are not executed at all. In Verbose mode, the commands are executed
  #           with results printed to stderr and stdin
  #
  # usage:
  #   _execute_ "cp -R \"~/dir/somefile.txt\" \"someNewFile.txt\"" "Optional message to print to user"
  local cmd="${1:?_execute_ needs a command}"
  local message="${2:-$1}"
  if ${dryrun}; then
    dryrun "${message}"
  else
    if $verbose; then
      eval "$cmd"
    else
      eval "$cmd" &> /dev/null
    fi
    if [ $? -eq 0 ]; then
      success "${message}"
    else
      error "${message}"
      return 1
      #die "${message}"
    fi
  fi
}

_findBaseDir_() {
  #v1.0.0
  # fincBaseDir locates the real directory of the script being run. similar to GNU readlink -n
  # usage :  baseDir="$(_findBaseDir_)"
  local SOURCE
  local DIR
  SOURCE="${BASH_SOURCE[0]}"
  while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="${DIR}/${SOURCE}" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  done
  echo "$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
}

_haveFunction_ () {
  # v1.0.0
  # Tests if a function exists.  Returns 0 if yes, 1 if no
  # usage: _haveFunction "_someFunction_"
  local f
  f="$1"

  if declare -f "$f" &> /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

_locateSourceFile_() {
  # v1.0.1
  # locateSourceFile is fed a symlink and returns the originating file
  # usage: _locateSourceFile_ 'some/symlink'

  local TARGET_FILE
  local PHYS_DIR
  local RESULT

  TARGET_FILE="${1:?_locateSourceFile_ needs a file}"

  cd "$(dirname "$TARGET_FILE")" || return 1
  TARGET_FILE="$(basename "$TARGET_FILE")"

  # Iterate down a (possible) chain of symlinks
  while [ -L "$TARGET_FILE" ]; do
    TARGET_FILE=$(readlink "$TARGET_FILE")
    cd "$(dirname "$TARGET_FILE")" || return 1
    TARGET_FILE="$(basename "$TARGET_FILE")"
  done

  # Compute the canonicalized name by finding the physical path
  # for the directory we're in and appending the target file.
  PHYS_DIR=$(pwd -P)
  RESULT="${PHYS_DIR}/${TARGET_FILE}"
  echo "$RESULT"
}

_makeSymlink_() {
  #v1.0.0
  # Given two arguments $1 & $2, creates a symlink from $1 (source) to $2 (destination) and
  # will create a backup of an original file before overwriting
  #
  # Script arguments:
  #
  #   $1 - Source file
  #   $2 - Destination for symlink
  #   $3 - backup directory for files to be overwritten (defaults to 'backup')
  #
  # NOTE: This function makes use of the _execute_ function
  #
  # usage: _makeSymlink_ "/dir/someExistingFile" "/dir/aNewSymLink" "/dir/backup/location"
  local s="$1"    # Source file
  local d="$2"    # Destination file
  local b="$3"    # Backup directory for originals (optional)
  local o         # Original file

  [ ! -e "$s" ] \
    &&  { error "'$s' not found"; return 1; }
  [ -z "$d" ] \
    && { error "'$d' not specified"; return 1; }

  # Fix files where $HOME is written as '~'
    d="${d/\~/$HOME}"
    s="${s/\~/$HOME}"
    b="${b/\~/$HOME}"

    if ! _haveFunction_ "_execute_"; then error "need function _execute_"; return 1; fi
    if ! _haveFunction_ "_backupFile_"; then error "need function _backupFile_"; return 1; fi
    if ! _haveFunction_ "_locateSourceFile_"; then error "need function _locateSourceFile_"; return 1; fi

  if [ ! -e "${d}" ]; then
    _execute_ "ln -fs \"${s}\" \"${d}\"" "symlink ${s} → ${d}"
  elif [ -h "${d}" ]; then
    o="$(_locateSourceFile_ "$d")"
    _backupFile_ "${o}" ${b:-backup}
    if ! ${dryrun}; then rm -rf "$d"; fi
    _execute_ "ln -fs \"${s}\" \"${d}\"" "symlink ${s} → ${d}"
  elif [ -e "${d}" ]; then
    _backupFile_ "${d}" "${b:-backup}"
    if ! ${dryrun}; then rm -rf "$d"; fi
    _execute_ "ln -fs \"${s}\" \"${d}\"" "symlink ${s} → ${d}"
  else
    warning "Error linking: ${s} → ${d}"
    return 1
  fi
  return 0
}

_parseYAML_() {
  # v1.1.0
  local yamlFile="${1:?_parseYAML_ needs a file}"
  local prefix=$2

  [ ! -f "$yamlFile" ] && return 1
  [ ! -s "$yamlFile" ] && return 1

  local s
  local w
  local fs
  s='[[:space:]]*'
  w='[a-zA-Z0-9_]*'
  fs="$(echo @|tr @ '\034')"
  sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
      -e "s|^\($s\)\($w\)$s[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$yamlFile" |
  awk -F"$fs" '{
    indent = length($1)/2;
    if (length($2) == 0) { conj[indent]="+";} else {conj[indent]="";}
    vname[indent] = $2;
    for (i in vname) {if (i > indent) {delete vname[i]}}
    if (length($3) > 0) {
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            printf("%s%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, conj[indent-1],$3);
    }
  }' | sed 's/_=/+=/g' | sed 's/[[:space:]]*#.*"/"/g'
}

_sourceFile_() {
  # v1.0.0
  # Takes a file as an argument $1 and sources it into the current script
  # usage: _sourceFile_ "SomeFile.txt"
  local c=$1

  [ ! -f "$c" ] \
    &&  { error "'$c' not found"; return 1; }

  source "$c"
}

_readFile_() {
  # v1.0.1
  # Function to reads a file and prints each line.
  # Usage: _readFile_ "some/filename"
  local result
  local c=$1

  [ ! -f "$c" ] \
    &&  { error "'$c' not found"; return 1; }

  while read -r result; do
    echo "${result}"
  done < "${c}"
}

_realpath_() {
  # v1.0.0
  # Convert a relative path to an absolute path.
  #
  # From http://github.com/morgant/realpath
  #
  # @param string the string to converted from a relative path to an absolute path
  # @returns Outputs the absolute path to STDOUT, returns 0 if successful or 1 if
  # an error (esp. path not found).
  local success=true
  local path="$1"

  # make sure the string isn't empty as that implies something in further logic
  if [ -z "$path" ]; then
    success=false
  else
    # start with the file name (sans the trailing slash)
    path="${path%/}"

    # if we stripped off the trailing slash and were left with nothing, that means we're in the root directory
    if [ -z "$path" ]; then
      path="/"
    fi

    # get the basename of the file (ignoring '.' & '..', because they're really part of the path)
    local file_basename="${path##*/}"
    if [[ ( "$file_basename" = "." ) || ( "$file_basename" = ".." ) ]]; then
      file_basename=""
    fi

    # extracts the directory component of the full path, if it's empty then assume '.' (the current working directory)
    local directory="${path%$file_basename}"
    if [ -z "$directory" ]; then
      directory='.'
    fi

    # attempt to change to the directory
    if ! cd "$directory" &>/dev/null ; then
      success=false
    fi

    if $success; then
      # does the filename exist?
      if [[ ( -n "$file_basename" ) && ( ! -e "$file_basename" ) ]]; then
        success=false
      fi

      # get the absolute path of the current directory & change back to previous directory
      local abs_path
      abs_path="$(pwd -P)"
      cd "-" &>/dev/null || return

      # Append base filename to absolute path
      if [ "${abs_path}" = "/" ]; then
        abs_path="${abs_path}${file_basename}"
      else
        abs_path="${abs_path}/${file_basename}"
      fi

      # output the absolute path
      echo "$abs_path"
    fi
  fi

  $success
}

_seekConfirmation_() {
  # v1.0.1
  # Seeks a Yes or No answer to a question.  Usage:
  #   if _seekConfirmation_ "Answer this question"; then
  #     something
  #   fi

  input "$@"
  if "${force}"; then
    verbose "Forcing confirmation with '--force' flag set"
    echo -e ""
    return 0
  else
    while true; do
      read -r -p " (y/n) " yn
      case $yn in
        [Yy]* ) return 0;;
        [Nn]* ) return 1;;
        * ) input "Please answer yes or no.";;
      esac
    done
  fi
}

_setdiff_() {
  # v1.0.0
  # Given strings containing space-delimited words A and B, "setdiff A B" will
  # return all words in A that do not exist in B. Arrays in bash are insane
  # (and not in a good way).
  #
  #   Usage: _setdiff_ "${array1[*]}" "${array2[*]}"
  #
  # From http://stackoverflow.com/a/1617303/142339
  local debug skip a b
  if [[ "$1" == 1 ]]; then debug=1; shift; fi
  if [[ "$1" ]]; then
    local setdiffA setdiffB setdiffC
    setdiffA=($1); setdiffB=($2)
  fi
  setdiffC=()
  for a in "${setdiffA[@]}"; do
    skip=
    for b in "${setdiffB[@]}"; do
      [[ "$a" == "$b" ]] && skip=1 && break
    done
    [[ "$skip" ]] || setdiffC=("${setdiffC[@]}" "$a")
  done
  [[ "$debug" ]] && for a in setdiffA setdiffB setdiffC; do
    echo "$a ($(eval echo "\${#$a[*]}")) $(eval echo "\${$a[*]}")" 1>&2
  done
  [[ "$1" ]] && echo "${setdiffC[@]}"
}

_uniqueFileName_() {
  # v2.0.0
  # _uniqueFileName_ takes an input of a file and returns a unique filename.
  # The use-case here is trying to write a file to a directory which may already
  # have a file with the same name. To ensure unique filenames, we append a digit
  # to files when necessary
  #
  # Inputs:
  #
  #   $1  The name of the file (may include a directory)
  #
  #   $2  Option separation character. Defaults to a space
  #
  # Usage:
  #
  #   _uniqueFileName_ "/some/dir/file.txt" "-"
  #
  #   Would return "/some/dir/file-2.txt"

  local fullfile="${1:?_uniqueFileName_ needs a file}"
  local spacer="${2:--}"
  local directory
  local filename

  # Find directories with _realpath_ if available
  if [ -e "$fullfile" ]; then
    if type -t _realpath_ | grep -E '^function$' &>/dev/null; then
      fullfile="$(_realpath_ "$fullfile")"
    fi
  fi

  directory="$(dirname "$fullfile")"
  filename="$(basename "$fullfile")"

  # Extract extensions only when they exist
  if [[ "$filename" =~ \.[a-zA-Z]{2,3}$ ]]; then
    local extension=".${filename##*.}"
    local filename="${filename%.*}"
  fi

  local newfile="${directory}/${filename}${extension}"

  if [ -e "${newfile}" ]; then
    local n=2
    while [[ -e "${directory}/${filename}${spacer}${n}${extension}" ]]; do
      (( n++ ))
    done
    newfile="${directory}/${filename}${spacer}${n}${extension}"
  fi

  echo "${newfile}"
}

_ltrim_() {
  # Removes all leading whitespace (from the left).
  local char=${1:-[:space:]}
    sed "s%^[${char//%/\\%}]*%%"
}

_rtrim_() {
  # Removes all trailing whitespace (from the right).
  local char=${1:-[:space:]}
  sed "s%[${char//%/\\%}]*$%%"
}

_trim_() {
  # Removes all leading/trailing whitespace
  # Usage examples:
  #     echo "  foo  bar baz " | _trim_  #==> "foo  bar baz"
  _ltrim_ "$1" | _rtrim_ "$1"
}

_trapCleanup_() {
  echo ""
  # Delete temp files, if any
  [ -d "${tmpDir}" ] && rm -r "${tmpDir}"
  die "Exit trapped. In function: '${FUNCNAME[*]:1}'"
}

_safeExit_() {
  # Delete temp files, if any
  [ -d "${tmpDir}" ] && rm -r "${tmpDir}"
  trap - INT TERM EXIT
  exit ${1:-0}
}

# Set Base Variables
# ----------------------
scriptName=$(basename "$0")

# Set Flags
quiet=false;              printLog=false;             verbose=false;
force=false;              strict=false;               dryrun=false;
debug=false;              sourceOnly=false;           args=();

# Set Colors
bold=$(tput bold);        reset=$(tput sgr0);         purple=$(tput setaf 171);
red=$(tput setaf 1);      green=$(tput setaf 76);     tan=$(tput setaf 3);
blue=$(tput setaf 38);    underline=$(tput sgr 0 1);

# Set Temp Directory
tmpDir="/tmp/${scriptName}.$RANDOM.$RANDOM.$RANDOM.$$"
(umask 077 && mkdir "${tmpDir}") || {
  die "Could not create temporary directory! Exiting."
}

# Logging & Feedback
logFile="${HOME}/Library/Logs/${scriptName%.sh}.log"

_alert_() {
  # v1.0.0
  if [ "${1}" = "error" ]; then local color="${bold}${red}"; fi
  if [ "${1}" = "warning" ]; then local color="${red}"; fi
  if [ "${1}" = "success" ]; then local color="${green}"; fi
  if [ "${1}" = "debug" ]; then local color="${purple}"; fi
  if [ "${1}" = "header" ]; then local color="${bold}${tan}"; fi
  if [ "${1}" = "input" ]; then local color="${bold}"; fi
  if [ "${1}" = "dryrun" ]; then local color="${blue}"; fi
  if [ "${1}" = "info" ] || [ "${1}" = "notice" ]; then local color=""; fi
  # Don't use colors on pipes or non-recognized terminals
  if [[ "${TERM}" != "xterm"* ]] || [ -t 1 ]; then color=""; reset=""; fi

  # Print to console when script is not 'quiet'
  if ${quiet}; then tput cuu1 ; return; else # tput cuu1 moves cursor up one line
   echo -e "$(date +"%r") ${color}$(printf "[%7s]" "${1}") ${_message}${reset}";
  fi

  # Print to Logfile
  if ${printLog} && [ "${1}" != "input" ]; then
    color=""; reset="" # Don't use colors in logs
    echo -e "$(date +"%m-%d-%Y %r") $(printf "[%7s]" "${1}") ${_message}" >> "${logFile}";
  fi
}

function die ()       { local _message="${*} Exiting."; echo -e "$(_alert_ error)"; _safeExit_ "1";}
function error ()     { local _message="${*}"; echo -e "$(_alert_ error)"; }
function warning ()   { local _message="${*}"; echo -e "$(_alert_ warning)"; }
function notice ()    { local _message="${*}"; echo -e "$(_alert_ notice)"; }
function info ()      { local _message="${*}"; echo -e "$(_alert_ info)"; }
function debug ()     { local _message="${*}"; echo -e "$(_alert_ debug)"; }
function success ()   { local _message="${*}"; echo -e "$(_alert_ success)"; }
function dryrun()     { local _message="${*}"; echo -e "$(_alert_ dryrun)"; }
function input()      { local _message="${*}"; echo -n "$(_alert_ input)"; }
function header()     { local _message="== ${*} ==  "; echo -e "$(_alert_ header)"; }
function verbose()    { if ${verbose}; then debug "$@"; fi }

# Options and Usage
# -----------------------------------
_usage_() {
  echo -n "${scriptName} [OPTION]... [FILE]...

This script runs a series of installation scripts to configure a new computer running Mac OSX.
It relies on a number of YAML config files which contain the lists of packages to be installed.

This script also looks for plugin scripts in a user configurable directory for added customization.

 ${bold}Options:${reset}

  -n, --dryrun      Non-destructive. Makes no permanent changes.
  -q, --quiet       Quiet (no output)
  -l, --log         Print log to file
  -s, --strict      Exit script with null variables.  i.e 'set -o nounset'
  -v, --verbose     Output more information. (Items echoed to 'verbose')
  -d, --debug       Runs script in BASH debug mode (set -x)
  -h, --help        Display this help and exit
      --source-only Bypasses main script functionality to allow unit tests of functions
      --version     Output version information and exit
      --force       Skip all user interaction.  Implied 'Yes' to all actions.
"
}

# Iterate over options breaking -ab into -a -b when needed and --foo=bar into
# --foo bar
optstring=h
unset options
while (($#)); do
  case $1 in
    # If option is of type -ab
    -[!-]?*)
      # Loop over each character starting with the second
      for ((i=1; i < ${#1}; i++)); do
        c=${1:i:1}

        # Add current char to options
        options+=("-$c")

        # If option takes a required argument, and it's not the last char make
        # the rest of the string its argument
        if [[ $optstring = *"$c:"* && ${1:i+1} ]]; then
          options+=("${1:i+1}")
          break
        fi
      done
      ;;

    # If option is of type --foo=bar
    --?*=*) options+=("${1%%=*}" "${1#*=}") ;;
    # add --endopts for --
    --) options+=(--endopts) ;;
    # Otherwise, nothing special
    *) options+=("$1") ;;
  esac
  shift
done
set -- "${options[@]}"
unset options

# Print help if no arguments were passed.
# Uncomment to force arguments when invoking the script
# -------------------------------------
# [[ $# -eq 0 ]] && set -- "--help"

# Read the options and set stuff
while [[ $1 = -?* ]]; do
  case $1 in
    -h|--help) _usage_ >&2; _safeExit_ ;;
    -n|--dryrun) dryrun=true ;;
    -v|--verbose) verbose=true ;;
    -l|--log) printLog=true ;;
    -q|--quiet) quiet=true ;;
    -s|--strict) strict=true;;
    -d|--debug) debug=true;;
    --version) echo "$(basename $0) ${version}"; _safeExit_ ;;
    --source-only) sourceOnly=true;;
    --force) force=true ;;
    --endopts) shift; break ;;
    *) die "invalid option: '$1'." ;;
  esac
  shift
done

# Store the remaining part as arguments.
args+=("$@")

# Trap bad exits with your cleanup function
trap _trapCleanup_ EXIT INT TERM

# Set IFS to preferred implementation
IFS=$' \n\t'

# Exit on error. Append '||true' when you run the script if you expect an error.
# if using the 'execute' function this must be disabled for warnings to be shown if tasks fail
#set -o errexit

# Force pipelines to fail on the first non-zero status code.
set -o pipefail

# Run in debug mode, if set
if ${debug}; then set -x ; fi

# Exit on empty variable
if ${strict}; then set -o nounset ; fi

# Exit the script if a command fails
#set -e

# Run your script unless in 'source-only' mode
if ! ${sourceOnly}; then _mainScript_; fi

# Exit cleanly
if ! ${sourceOnly}; then _safeExit_; fi