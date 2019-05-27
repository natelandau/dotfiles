_listFiles_() {
  # DESC:  Find files in a directory.  Use either glob or regex
  # ARGS:  $1 (Required) - 'g|glob' or 'r|regex'
  #        $2 (Required) - pattern to match
  #        $3 (Optional) - directory
  # OUTS:  None
  # NOTE:  Searches are NOT case sensitive
  # USAGE: _listFiles_ glob "*.txt" "some/backup/dir"
  #        _listFiles_ regex ".*\.txt" "some/backup/dir"
  #        array=($(_listFiles_ g "*.txt"))

  [[ $# -lt 2 ]] && fatal 'Missing required argument to _listFiles_()!'

  local t="${1}"
  local p="${2}"
  local d="${3:-.}"
  local fileMatch e

  # Error handling
  [ ! "$(declare -f "_realpath_")" ] \
    && {
      warning "need function _realpath_"
      return 1
    }
  [ -z "$p" ] \
    && {
      warning "No pattern entered to match against"
      return 1
    }

  case "$t" in
    glob | Glob | g | G)
      while read -r fileMatch; do
        e=$(_realpath_ "${fileMatch}")
        echo "${e}"
      done < <(find "${d}" -iname "${p}" -type f -maxdepth 1 | sort)
      ;;
    regex | Regex | r | R)
      while read -r fileMatch; do
        e=$(_realpath_ "${fileMatch}")
        echo "${e}"
      done < <(find "${d}" -iregex "${p}" -type f -maxdepth 1 | sort)
      ;;
    *)
      echo "Could not determine if search was glob or regex"
      return 1
      ;;
  esac

}

_backupFile_() {
  # DESC:   Creates a copy of a specified file
  # ARGS:   $1 (Required) - Source file
  #         $2 (Optional) - Destination dir (defaults to ./backup)
  # OUTS:   None
  # USAGE:  _backupFile_ "sourcefile.txt" "some/backup/dir"
  # NOTE:   dotfiles have their leading '.' removed in their backup

  [[ $# -lt 1 ]] && fatal 'Missing required argument to _backupFile_()!'

  local s="${1}"
  local d="${2:-backup}"
  local n # New filename (created by _uniqueFilename_)

  # Error handling
  [ ! "$(declare -f "_execute_")" ] \
    && {
      warning "need function _execute_"
      return 1
    }
  [ ! "$(declare -f "_uniqueFileName_")" ] \
    && {
      warning "need function _uniqueFileName_"
      return 1
    }
  [ ! -e "$s" ] \
    && {
      warning "Source '$s' not found"
      return 1
    }

  [ ! -d "$d" ] \
    && _execute_ "mkdir -p \"$d\"" "Creating backup directory"

  if [ -e "$s" ]; then
    n="$(basename "$s")"
    n="$(_uniqueFileName_ "${d}/${s#.}")"
    _execute_ "cp -R \"${s}\" \"${d}/${n##*/}\"" "Backing up: '${s}' to '${d}/${n##*/}'"
  fi
}

_cleanFilename_() {
  # DESC:   Cleans a filename of all non alphanumeric characters
  # ARGS:   $1 (Required) - File to be cleaned
  #         $2 (optional) - Additional characters to be cleaned separated by commas
  # OUTS:   Overwrites file with new new and prints name of new file
  # USAGE:  _cleanFilename_ "FILENAME.TXT" "^,&,*"
  # NOTE:   IMPORTANT - This will overwrite the original file
  #         IMPORTANT - All spaces and underscores will be replaced by dashes (-)

  [[ $# -lt 1 ]] && fatal 'Missing required argument to _cleanFilename_()!'

  local arrayToClean
  local fileToClean="$(_realpath_ "$1")"
  local optionalUserInput="${2-}"

  IFS=',' read -r -a arrayToClean <<<"$optionalUserInput"

  [ ! -f "$fileToClean" ] \
    && {
      warning "_cleanFileName_ ${fileToClean}: File doesn't exist"
      return 1
    }

  local dir="$(_realpath_ -d "$fileToClean")"
  local extension="${fileToClean##*.}"
  local baseFileName="$(basename "${fileToClean%.*}")"

  for i in "${arrayToClean[@]}"; do
    baseFileName="$(echo "${baseFileName}" | sed "s/$i//g")"
  done

  baseFileName="$(echo "${baseFileName}" | tr -dc '[:alnum:]-_ ' | sed 's/ /-/g')"

  local final="${dir}/${baseFileName}.${extension}"

  if [ "${fileToClean}" != "${final}" ]; then
    final="$(_uniqueFileName_ "${final}")"
    _execute_ -q "mv \"${fileToClean}\" \"${final}\""
    echo "$final"
  else
    echo "${fileToClean}"
  fi

}

_decryptFile_() {
  # DESC:   Decrypts a file with openSSL
  # ARGS:   $1 (Required) - File to be decrypted
  #         $2 (Optional) - Name of output file (defaults to $1.decrypt)
  # OUTS:   None
  # USAGE:  _decryptFile_ "somefile.txt.enc" "decrypted_somefile.txt"
  # NOTE:   If a variable '$PASS' has a value, we will use that as the password
  #         to decrypt the file. Otherwise we will ask

  [[ $# -lt 1 ]] && fatal 'Missing required argument to _decryptFile_()!'

  local fileToDecrypt decryptedFile defaultName
  fileToDecrypt="${1:?_decryptFile_ needs a file}"
  defaultName="${fileToDecrypt%.enc}"
  decryptedFile="${2:-$defaultName.decrypt}"

  [ ! "$(declare -f "_execute_")" ] \
    && {
      echo "need function _execute_"
      return 1
    }

  [ ! -f "$fileToDecrypt" ] && return 1

  if [ -z $PASS ]; then
    _execute_ "openssl enc -aes-256-cbc -d -in \"${fileToDecrypt}\" -out \"${decryptedFile}\"" "Decrypt ${fileToDecrypt}"
  else
    _execute_ "openssl enc -aes-256-cbc -d -in \"${fileToDecrypt}\" -out \"${decryptedFile}\" -k \"${PASS}\"" "Decrypt ${fileToDecrypt}"
  fi
}

_encryptFile_() {
  # DESC:   Encrypts a file using openSSL
  # ARGS:   $1 (Required) - Input file
  #         $2 (Optional) - Name of output file (defaults to $1.enc)
  # OUTS:   None
  # USAGE:  _encryptFile_ "somefile.txt" "encrypted_somefile.txt"
  # NOTE:   If a variable '$PASS' has a value, we will use that as the password
  #         for the encrypted file. Otherwise we will ask.

  local fileToEncrypt encryptedFile defaultName

  fileToEncrypt="${1:?_encodeFile_ needs a file}"
  defaultName="${fileToEncrypt%.decrypt}"
  encryptedFile="${2:-$defaultName.enc}"

  [ ! -f "$fileToEncrypt" ] && return 1

  [ ! "$(declare -f "_execute_")" ] \
    && {
      echo "need function _execute_"
      return 1
    }

  if [ -z $PASS ]; then
    _execute_ "openssl enc -aes-256-cbc -salt -in \"${fileToEncrypt}\" -out \"${encryptedFile}\"" "Encrypt ${fileToEncrypt}"
  else
    _execute_ "openssl enc -aes-256-cbc -salt -in \"${fileToEncrypt}\" -out \"${encryptedFile}\" -k \"${PASS}\"" "Encrypt ${fileToEncrypt}"
  fi
}

_ext_() {
  # DESC:   Extract the extension from a filename
  # ARGS:   $1 (Required) - Input file
  # OPTS:   -n            - optional flag for number of extension levels (Ex: -n2)
  # OUTS:   Print extension
  # USAGE:
  #   _ext_     foo.txt     #==> .txt
  #   _ext_ -n2 foo.tar.gz  #==> .tar.gz
  #   _ext_     foo.tar.gz  #==> .tar.gz
  #   _ext_ -n1 foo.tar.gz  #==> .gz

  [[ $# -lt 1 ]] && fatal 'Missing required argument to _ext_()!'

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
  if [[ ! ${levels-} ]]; then
    case $(tr '[:upper:]' '[:lower:]' <<<$filename) in
      *.tar.gz | *.tar.bz2) levels=2 ;;
    esac
  fi

  levels=${levels:-1}

  for ((i = 0; i < levels; i++)); do
    ext=.${fn##*.}
    exts=$ext${exts-}
    fn=${fn%$ext}
    [[ "$exts" == "$filename" ]] && return
  done

  echo "$exts"
}

_extract_() {
  # DESC:   Extract a compressed file
  # ARGS:   $1 (Required) - Input file
  #         $2 (optional) - Input 'v' to show verbose output
  # OUTS:   None

  local filename
  local foldername
  local fullpath
  local didfolderexist
  local vv

  [[ $# -lt 1 ]] && fatal 'Missing required argument to _extract_()!'

  [[ "${2-}" == "v" ]] && vv="v"

  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2 | *.tbz | *.tbz2) tar "x${vv}jf" "$1" ;;
      *.tar.gz | *.tgz) tar "x${vv}zf" "$1" ;;
      *.tar.xz)
        xz --decompress "$1"
        set -- "$@" "${1:0:-3}"
        ;;
      *.tar.Z)
        uncompress "$1"
        set -- "$@" "${1:0:-2}"
        ;;
      *.bz2) bunzip2 "$1" ;;
      *.deb) dpkg-deb -x${vv} "$1" "${1:0:-4}" ;;
      *.pax.gz)
        gunzip "$1"
        set -- "$@" "${1:0:-3}"
        ;;
      *.gz) gunzip "$1" ;;
      *.pax) pax -r -f "$1" ;;
      *.pkg) pkgutil --expand "$1" "${1:0:-4}" ;;
      *.rar) unrar x "$1" ;;
      *.rpm) rpm2cpio "$1" | cpio -idm${vv} ;;
      *.tar) tar "x${vv}f" "$1" ;;
      *.txz)
        mv "$1" "${1:0:-4}.tar.xz"
        set -- "$@" "${1:0:-4}.tar.xz"
        ;;
      *.xz) xz --decompress "$1" ;;
      *.zip | *.war | *.jar) unzip "$1" ;;
      *.Z) uncompress "$1" ;;
      *.7z) 7za x "$1" ;;
      *) return 1 ;;
    esac
  else
    return 1
  fi
  shift

}

_json2yaml_() {
  # DESC:   Convert JSON to YAML
  # ARGS:   $1 (Required) - JSON file
  # OUTS:   None

  python -c 'import sys, yaml, json; yaml.safe_dump(json.load(sys.stdin), sys.stdout, default_flow_style=False)' <"${1:?_json2yaml_ needs a file}"
}

_locateSourceFile_() {
  # DESC:   Find original file of a symlink
  # ARGS:   $1 (Required) - Input symlink
  # OUTS:   Print location of original file

  local TARGET_FILE
  local PHYS_DIR
  local RESULT

  # Error handling
  [ ! "$(declare -f "_realpath_")" ] \
    && {
      error "'_locateSourceFile_' requires function '_realpath_' "
      return 1
    }

  TARGET_FILE="${1:?_locateSourceFile_ needs a file}"

  cd "$(_realpath_ -d "${TARGET_FILE}")" &>/dev/null || return 1
  TARGET_FILE="$(basename "${TARGET_FILE}")"
  # Iterate down a (possible) chain of symlinks
  while [ -L "${TARGET_FILE}" ]; do
    TARGET_FILE=$(readlink "${TARGET_FILE}")
    cd "$(_realpath_ -d "${TARGET_FILE}")" &>/dev/null || return 1
    TARGET_FILE="$(basename "${TARGET_FILE}")"
  done

  # Compute the canonicalized name by finding the physical path
  # for the directory we're in and appending the target file.
  PHYS_DIR=$(pwd -P)
  RESULT="${PHYS_DIR}/${TARGET_FILE}"
  echo "${RESULT}"
  return 0
}

_makeSymlink_() {
  # DESC:   Creates a symlink and backs up a file which may be overwritten by the new symlink
  # ARGS:   $1 (Required) - Source file
  #         $2 (Required) - Destination
  #         $3 (Optional) - Backup directory for files which may be overwritten (defaults to 'backup')
  # OUTS:   None
  # USAGE:  _makeSymlink_ "/dir/someExistingFile" "/dir/aNewSymLink" "/dir/backup/location"
  # NOTE:   This function makes use of the _execute_ function

  [[ $# -lt 2 ]] && fatal 'Missing required argument to _makeSymlink_()!'

  local s="$1"
  local d="$2"
  local b="${3-}"
  local o

  # Fix files where $HOME is written as '~'
  d="${d/\~/$HOME}"
  s="${s/\~/$HOME}"
  b="${b/\~/$HOME}"

  [ ! -e "$s" ] \
    && {
      error "'$s' not found"
      return 1
    }
  [ -z "$d" ] \
    && {
      error "'$d' not specified"
      return 1
    }
  [ ! "$(declare -f "_execute_")" ] \
    && {
      echo "need function _execute_"
      return 1
    }
  [ ! "$(declare -f "_backupFile_")" ] \
    && {
      echo "need function _backupFile_"
      return 1
    }
  [ ! "$(declare -f "_locateSourceFile_")" ] \
    && {
      echo "need function _locateSourceFile_"
      return 1
    }

  # Create destination directory if needed
  [ ! -d "${d%/*}" ] \
    && _execute_ "mkdir -p \"${d%/*}\""

  if [ ! -e "${d}" ]; then
    _execute_ "ln -fs \"${s}\" \"${d}\"" "symlink ${s} → ${d}"
  elif [ -h "${d}" ]; then
    o="$(_locateSourceFile_ "$d")"
    _backupFile_ "${o}" ${b:-backup}
    ($dryrun) \
      || command rm -rf "$d"
    _execute_ "ln -fs \"${s}\" \"${d}\"" "symlink ${s} → ${d}"
  elif [ -e "${d}" ]; then
    _backupFile_ "${d}" "${b:-backup}"
    ($dryrun) \
      || rm -rf "$d"
    _execute_ "ln -fs \"${s}\" \"${d}\"" "symlink ${s} → ${d}"
  else
    warning "Error linking: ${s} → ${d}"
    return 1
  fi
  return 0
}

_parseYAML_() {
  # DESC:   Convert YANML file into BASH variables for use in a shell script
  # ARGS:   $1 (Required) - Source YAML file
  #         $2 (Required) - Prefix for the variables to avoid namespace collisions
  # OUTS:   Prints variables and arrays derived from YAML File
  # USAGE:  To source into a script
  #         _parseYAML_ "sample.yml" "CONF_" > tmp/variables.txt
  #         source "tmp/variables.txt"
  #
  # NOTE:   https://gist.github.com/DinoChiesa/3e3c3866b51290f31243
  #         https://gist.github.com/epiloque/8cf512c6d64641bde388


  local yamlFile="${1:?_parseYAML_ needs a file}"
  local prefix="${2-}"

  [ ! -s "${yamlFile}" ] \
    && return 1

  local s
  local w
  local fs

  s='[[:space:]]*'
  w='[a-zA-Z0-9_]*'
  fs="$(echo @ | tr @ '\034')"
  sed -ne "s|^\(${s}\)\(${w}\)${s}:${s}\"\(.*\)\"${s}\$|\1${fs}\2${fs}\3|p" \
    -e "s|^\(${s}\)\(${w}\)${s}[:-]${s}\(.*\)${s}\$|\1${fs}\2${fs}\3|p" "${yamlFile}" \
    | awk -F"${fs}" '{
    indent = length($1)/2;
    if (length($2) == 0) { conj[indent]="+";} else {conj[indent]="";}
    vname[indent] = $2;
    for (i in vname) {if (i > indent) {delete vname[i]}}
    if (length($3) > 0) {
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            printf("%s%s%s%s=(\"%s\")\n", "'"${prefix}"'",vn, $2, conj[indent-1],$3);
    }
  }' | sed 's/_=/+=/g' | sed 's/[[:space:]]*#.*"/"/g'
}

_readFile_() {
  # DESC:   Prints each line of a file
  # ARGS:   $1 (Required) - Input file
  # OUTS:   Prints contents of file

  [[ $# -lt 1 ]] && fatal 'Missing required argument to _readFile_()!'

  local result
  local c="$1"

  [ ! -f "$c" ] \
    && {
      echo "'$c' not found"
      return 1
    }

  while read -r result; do
    echo "${result}"
  done <"${c}"
}

_realpath_() {
  # DESC:   Convert a file with relative path to an absolute path
  # ARGS:   $1 (Required) - Input file
  # OPTS:   -d            - Print the directory information only, without the filename in the output
  # OUTS:   Prints absolute path of file. Returns 0 if successful or 1 if an error
  # NOTE:   http://github.com/morgant/realpath

  local file_basename
  local directory
  local output
  local showOnlyDir=false
  local OPTIND=1
  local opt

  while getopts ":dD" opt; do
    case $opt in
      d | D) showOnlyDir=true ;;
      *) {
        error "Unrecognized option '$1' passed to _execute. Exiting."
        _safeExit_
      }
        ;;
    esac
  done
  shift $((OPTIND - 1))

  local path="${1:?_realpath_ needs an input}"

  # make sure the string isn't empty as that implies something in further logic
  if [ -z "$path" ]; then
    return 1
  else
    # start with the file name (sans the trailing slash)
    path="${path%/}"

    # if we stripped off the trailing slash and were left with nothing, that means we're in the root directory
    if [ -z "$path" ]; then
      path="/"
    fi

    # get the basename of the file (ignoring '.' & '..', because they're really part of the path)
    file_basename="${path##*/}"
    if [[ ("$file_basename" == ".") || ("$file_basename" == "..") ]]; then
      file_basename=""
    fi

    # extracts the directory component of the full path, if it's empty then assume '.' (the current working directory)
    directory="${path%$file_basename}"
    if [ -z "$directory" ]; then
      directory='.'
    fi

    # attempt to change to the directory
    if ! cd "$directory" &>/dev/null; then
      return 1
    fi

    # does the filename exist?
    if [[ (-n "$file_basename") && (! -e "$file_basename") ]]; then
      return 1
    fi

    # get the absolute path of the current directory & change back to previous directory
    local abs_path
    abs_path="$(pwd -P)"
    cd "-" &>/dev/null || return

    # Append base filename to absolute path
    if [ "${abs_path}" = "/" ]; then
      output="${abs_path}${file_basename}"
    else
      output="${abs_path}/${file_basename}"
    fi

    # output the absolute path
    if ! $showOnlyDir ; then
      echo "${output}"
    else
      echo "${abs_path}"
    fi
  fi
}

_sourceFile_() {
  # DESC:   Source a file into a script
  # ARGS:   $1 (Required) - File to be sourced
  # OUTS:   None

  [[ $# -lt 1 ]] && fatal 'Missing required argument to _sourceFile_()!'

  local c="$1"

  [ ! -f "$c" ] \
    && {
      echo "error: '$c' not found"
      return 1
    }

  source "$c"
  return 0
}

_uniqueFileName_() {
  # DESC:   Ensure a file to be created has a unique filename to avoid overwriting other files
  # ARGS:   $1 (Required) - Name of file to be created
  #         $2 (Optional) - Separation characted (Defaults to space to mimic Mac Finder)
  # OUTS:   Prints unique filename to STDOUT
  # USAGE:  _uniqueFileName_ "/some/dir/file.txt" "-"

  local fullfile="${1:?_uniqueFileName_ needs a file}"
  local spacer="${2:--}"
  local directory
  local filename
  local extension
  local newfile
  local n

  # Error handling
  [ ! "$(declare -f "_realpath_")" ] \
    && {
      error "'_uniqueFileName_' requires function '_realpath_' "
      return 1
    }

  # Find directories with _realpath_ if input is an actual file
  if [ -e "$fullfile" ]; then
    fullfile="$(_realpath_ "$fullfile")"
  fi

  directory="$(dirname "$fullfile")"
  filename="$(basename "$fullfile")"

  # Extract extensions only when they exist
  if [[ "$filename" =~ \.[a-zA-Z]{2,4}$ ]]; then
    extension=".${filename##*.}"
    filename="${filename%.*}"
  fi

  newfile="${directory}/${filename}${extension-}"

  if [ -e "${newfile}" ]; then
    n=2
    while [[ -e "${directory}/${filename}${spacer}${n}${extension-}" ]]; do
      ((n++))
    done
    newfile="${directory}/${filename}${spacer}${n}${extension-}"
  fi

  echo "${newfile}"
  return 0
}

_yaml2json_() {
  # DESC:   Convert a YAML file to JSON
  # ARGS:   $1 (Required) - Input YAML file
  # OUTS:   None

  python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' <"${1:?_yaml2json_ needs a file}"
}
