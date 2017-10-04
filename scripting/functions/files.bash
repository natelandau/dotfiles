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

  unset OPTIND
  while getopts ":n:" option; do
    case $option in
      n) levels=$OPTARG ;;
    esac
  done && shift $((OPTIND - 1))

  local filename=${1##*/}

  [[ $filename == *.* ]] || return

  local fn=$filename
  local exts ext

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

  [ ! -f "$fileToClean" ] && die "_cleanFileName_ ${fileToClean}: File doesn't exist"

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
  local spacer="${2:- }"
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

_json2yaml_() {
  # v1.0.0
  # convert json files to yaml using python and PyYAML
  # usage: _json2yaml_ "dir/somefile.json"
  python -c 'import sys, yaml, json; yaml.safe_dump(json.load(sys.stdin), sys.stdout, default_flow_style=False)' < "${1:?_json2yaml_ needs a file}"
}

_yaml2json_() {
  # v1.0.0
  # convert yaml files to json using python and PyYAML
  # usage: _yaml2json_ "dir/somefile.yaml"
  python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' < "${1:?_yaml2json_ needs a file}"
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

  if [ -z $PASS ]; then
    _execute_ "openssl enc -aes-256-cbc -salt -in \"${fileToEncrypt}\" -out \"${encryptedFile}\"" "Encrypt ${fileToEncrypt}"
  else
    _execute_ "openssl enc -aes-256-cbc -salt -in \"${fileToEncrypt}\" -out \"${encryptedFile}\" -k \"${PASS}\"" "Encrypt ${fileToEncrypt}"
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

  [ ! -f "$fileToDecrypt" ] && return 1

  if [ -z $PASS ]; then
    _execute_ "openssl enc -aes-256-cbc -d -in \"${fileToDecrypt}\" -out \"${decryptedFile}\"" "Decrypt ${fileToDecrypt}"
  else
    _execute_ "openssl enc -aes-256-cbc -d -in \"${fileToDecrypt}\" -out \"${decryptedFile}\" -k \"${PASS}\"" "Decrypt ${fileToDecrypt}"
  fi
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