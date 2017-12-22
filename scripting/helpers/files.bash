_backupFile_() {
  # v1.0.0
  # Creates a copy of a specified file taking two inputs:
  #   $1 - File to be backed up
  #   $2 - Destination
  #
  # NOTE: dotfiles have their leading '.' removed in their backup
  #
  # Usage:  _backupFile_ "sourcefile.txt" "some/backup/dir"

  local s="$1"                # Source file
  local d="${2:-backup}"      # Destination directory (optional, defaults to 'backup')
  local n                     # New filename (created by _uniqueFilename_)

  [ ! "$(declare -f "_execute_")" ] \
    && { echo "need function _execute_"; return 1; }
  [ ! "$(declare -f "_uniqueFileName_")" ] \
    && { echo "need function _uniqueFileName_"; return 1; }
  [ ! -e "$s" ] \
    &&  { error "Source '$s' not found"; return 1; }

  [ ! -d "$d" ] \
    && _execute_ "mkdir \"$d\"" "Creating backup directory"

  if [ -e "$s" ]; then
    n="$(basename "$s")"
    n="$(_uniqueFileName_ "${d}/${s#.}")"
    _execute_ "cp -R \"${s}\" \"${d}/${n##*/}\"" "Backing up: '${s}' to '${d}/${n##*/}'"
  fi
}

_cleanFilename_() {
  # v1.0.0
  # _cleanFilename_ takes an input of a file and returns a replaces it with a version
  # that is cleaned of certain characters.
  #
  # Update the cleanedFile variable after the pipe to customize for each script
  #
  # IMPORTANT: This will overwrite the original file and echo the new filename to the script

  local final cleanedFile fileToClean extension baseFileName

  fileToClean="$1"

  [ ! -f "$fileToClean" ] \
    && { warning "_cleanFileName_ ${fileToClean}: File doesn't exist"; return 1; }

  extension="${fileToClean##*.}"
  baseFileName=${fileToClean%.*}

  cleanedFile=$(echo "${baseFileName}" | tr -dc '[:alnum:]-_ ' | sed 's/ /-/g')

  final="${cleanedFile}.${extension}"

  if ! ${dryrun}; then
    if [[ "${fileToClean}" != "${final}" ]]; then
      mv "${fileToClean}" "${final}" || die "_cleanFileName_: could not create new file"
      echo "$final"
    else
      echo "${fileToClean}"
    fi
  else
    echo "${fileToClean}"
  fi
}

_decryptFile_() {
  # v1.0.0
  # Takes a file as argument $1 and decrypts it using openSSL.
  # Argument $2 is the output name. If $2 is not specified, the
  # output will be '$1.decrypt'
  #
  # If a variable '$PASS' has a value, we will use that as the password
  # to decrypt the file. Otherwise we will ask
  #
  # usage:  _decryptFile_ "somefile.txt.enc" "decrypted_somefile.txt"

  local fileToDecrypt decryptedFile defaultName
  fileToDecrypt="${1:?_decryptFile_ needs a file}"
  defaultName="${fileToDecrypt%.enc}"
  decryptedFile="${2:-$defaultName.decrypt}"

  [ ! "$(declare -f "_execute_")" ] \
    && { echo "need function _execute_"; return 1; }

  [ ! -f "$fileToDecrypt" ] && return 1

  if [ -z $PASS ]; then
    _execute_ "openssl enc -aes-256-cbc -d -in \"${fileToDecrypt}\" -out \"${decryptedFile}\"" "Decrypt ${fileToDecrypt}"
  else
    _execute_ "openssl enc -aes-256-cbc -d -in \"${fileToDecrypt}\" -out \"${decryptedFile}\" -k \"${PASS}\"" "Decrypt ${fileToDecrypt}"
  fi
}

_encryptFile_() {
  # v1.0.0
  # Takes a file as argument $1 and encodes it using openSSL
  # Argument $2 is the output name. if $2 is not specified, the
  # output will be '$1.enc'
  #
  # If a variable '$PASS' has a value, we will use that as the password
  # for the encrypted file. Otherwise we will ask.
  #
  # usage:  _encryptFile_ "somefile.txt" "encrypted_somefile.txt"

  local fileToEncrypt encryptedFile defaultName

  fileToEncrypt="${1:?_encodeFile_ needs a file}"
  defaultName="${fileToEncrypt%.decrypt}"
  encryptedFile="${2:-$defaultName.enc}"

  [ ! -f "$fileToEncrypt" ] && return 1

  [ ! "$(declare -f "_execute_")" ] \
    && { echo "need function _execute_"; return 1; }

  if [ -z $PASS ]; then
    _execute_ "openssl enc -aes-256-cbc -salt -in \"${fileToEncrypt}\" -out \"${encryptedFile}\"" "Encrypt ${fileToEncrypt}"
  else
    _execute_ "openssl enc -aes-256-cbc -salt -in \"${fileToEncrypt}\" -out \"${encryptedFile}\" -k \"${PASS}\"" "Encrypt ${fileToEncrypt}"
  fi
}

_ext_() {
  # v1.0.0
  # Get the extension of the given filename.
  #
  # Usage: _ext_ [-n LEVELS] FILENAME
  #
  # Usage examples:
  #   _ext_     foo.txt     #==> .txt
  #   _ext_ -n2 foo.tar.gz  #==> .tar.gz
  #   _ext_     foo.tar.gz  #==> .tar.gz
  #   _ext_ -n1 foo.tar.gz  #==> .gz

  local levels
  local option
  local filename
  local exts
  local ext
  local fn
  local i

  unset OPTIND
  while getopts ":n:" option; do
    case $option in
      n) levels=$OPTARG ;;
      *) continue ;;
    esac
  done && shift $((OPTIND - 1))

  filename=${1##*/}

  [[ $filename == *.* ]] || return

  fn=$filename

  # Detect some common multi-extensions
  if [[ ! $levels ]]; then
    case $(tr '[:upper:]' '[:lower:]' <<<$filename) in
      *.tar.gz|*.tar.bz2) levels=2 ;;
    esac
  fi

  levels=${levels:-1}

  for (( i=0; i<levels; i++ )); do
    ext=.${fn##*.}
    exts=$ext$exts
    fn=${fn%$ext}
    [[ "$exts" == "$filename" ]] && return
  done

  echo "$exts"
}

_extract_() {
  # Takes a file as input ($1) and attempts to extract a compressed file
  # pass 'v' as a second variable to show verbose output

  local filename
  local foldername
  local fullpath
  local didfolderexist
  local vv

  [[ "$2" == "v" ]] && vv="v"

  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2|*.tbz|*.tbz2) tar "x${vv}jf" "$1" ;;
      *.tar.gz|*.tgz) tar "x${vv}zf" "$1" ;;
      *.tar.xz) xz --decompress "$1"; set -- "$@" "${1:0:-3}" ;;
      *.tar.Z) uncompress "$1"; set -- "$@" "${1:0:-2}" ;;
      *.bz2) bunzip2 "$1" ;;
      *.deb) dpkg-deb -x${vv} "$1" "${1:0:-4}" ;;
      *.pax.gz) gunzip "$1"; set -- "$@" "${1:0:-3}" ;;
      *.gz) gunzip "$1" ;;
      *.pax) pax -r -f "$1" ;;
      *.pkg) pkgutil --expand "$1" "${1:0:-4}" ;;
      *.rar) unrar x "$1" ;;
      *.rpm) rpm2cpio "$1" | cpio -idm${vv} ;;
      *.tar) tar "x${vv}f" "$1" ;;
      *.txz) mv "$1" "${1:0:-4}.tar.xz"; set -- "$@" "${1:0:-4}.tar.xz" ;;
      *.xz) xz --decompress "$1" ;;
      *.zip|*.war|*.jar) unzip "$1" ;;
      *.Z) uncompress "$1" ;;
      *.7z) 7za x "$1" ;;
      *) return 1
    esac
  else
    return 1
  fi
  shift

}

_json2yaml_() {
  # v1.0.0
  # convert json files to yaml using python and PyYAML
  # usage: _json2yaml_ "dir/somefile.json"
  python -c 'import sys, yaml, json; yaml.safe_dump(json.load(sys.stdin), sys.stdout, default_flow_style=False)' < "${1:?_json2yaml_ needs a file}"
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
  #v1.1.0
  # Given two arguments $1 & $2, creates a symlink from $1 (source) to $2 (destination) and
  # create a backup of an original file before overwriting
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
  [ ! "$(declare -f "_execute_")" ] \
    && { echo "need function _execute_"; return 1; }
  [ ! "$(declare -f "_backupFile_")" ] \
    && { echo "need function _backupFile_"; return 1; }
  [ ! "$(declare -f "_locateSourceFile_")" ] \
      && { echo "need function _locateSourceFile_"; return 1; }

  # Fix files where $HOME is written as '~'
    d="${d/\~/$HOME}"
    s="${s/\~/$HOME}"
    b="${b/\~/$HOME}"

  # Create destination directory if needed
  [ ! -d "${d%/*}" ] \
    && _execute_ "mkdir -p \"${d%/*}\""

  if [ ! -e "${d}" ]; then
    _execute_ "ln -fs \"${s}\" \"${d}\"" "symlink ${s} → ${d}"
  elif [ -h "${d}" ]; then
    o="$(_locateSourceFile_ "$d")"
    _backupFile_ "${o}" ${b:-backup}
    ( $dryrun ) \
      || rm -rf "$d"
    _execute_ "ln -fs \"${s}\" \"${d}\"" "symlink ${s} → ${d}"
  elif [ -e "${d}" ]; then
    _backupFile_ "${d}" "${b:-backup}"
    ( $dryrun ) \
      || rm -rf "$d"
    _execute_ "ln -fs \"${s}\" \"${d}\"" "symlink ${s} → ${d}"
  else
    warning "Error linking: ${s} → ${d}"
    return 1
  fi
  return 0
}

_parseYAML_() {
  # v1.1.0
  # Function to parse YAML files and add values to variables. Send it to a temp file and source it
  # https://gist.github.com/DinoChiesa/3e3c3866b51290f31243 which is derived from
  # https://gist.github.com/epiloque/8cf512c6d64641bde388
  #
  # Note that portions of strings containing a '#' are removed to allow for comments.
  #
  # Usage:
  #     $ _parseYAML_ sample.yml > /some/tempfile
  #     $ source /some/tempfile
  #
  # _parseYAML_ accepts a prefix argument so that imported settings all have a common prefix
  # (which will reduce the risk of name-space collisions).
  #
  #     $ _parseYAML_ sample.yml "CONF_"
  local yamlFile="${1:?_parseYAML_ needs a file}"
  local prefix="$2"

  [ ! -s "$yamlFile" ] \
    && return 1

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

_readFile_() {
  # v1.0.1
  # Function to reads a file and prints each line.
  # Usage: _readFile_ "some/filename"
  local result
  local c="$1"

  [ ! -f "$c" ] \
    &&  { echo "'$c' not found"; return 1; }

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
  local file_basename
  local directory

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
    file_basename="${path##*/}"
    if [[ ( "$file_basename" = "." ) || ( "$file_basename" = ".." ) ]]; then
      file_basename=""
    fi

    # extracts the directory component of the full path, if it's empty then assume '.' (the current working directory)
    directory="${path%$file_basename}"
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

_sourceFile_() {
  # v1.0.0
  # Takes a file as an argument $1 and sources it into the current script
  # usage: _sourceFile_ "SomeFile.txt"
  local c="$1"

  [ ! -f "$c" ] \
    &&  { echo "error: '$c' not found"; return 1; }

  source "$c"
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
  local extension
  local newfile
  local n

  # Find directories with _realpath_ if available
  if [ -e "$fullfile" ]; then
    if type -t _realpath_ | grep -E '^function$' &> /dev/null; then
      fullfile="$(_realpath_ "$fullfile")"
    fi
  fi

  directory="$(dirname "$fullfile")"
  filename="$(basename "$fullfile")"

  # Extract extensions only when they exist
  if [[ "$filename" =~ \.[a-zA-Z]{2,3}$ ]]; then
    extension=".${filename##*.}"
    filename="${filename%.*}"
  fi

  newfile="${directory}/${filename}${extension}"

  if [ -e "${newfile}" ]; then
    n=2
    while [[ -e "${directory}/${filename}${spacer}${n}${extension}" ]]; do
      (( n++ ))
    done
    newfile="${directory}/${filename}${spacer}${n}${extension}"
  fi

  echo "${newfile}"
}

_yaml2json_() {
  # v1.0.0
  # convert yaml files to json using python and PyYAML
  # usage: _yaml2json_ "dir/somefile.yaml"
  python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' < "${1:?_yaml2json_ needs a file}"
}