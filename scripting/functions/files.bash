_ext_() {
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

_locateSourceFile_() {
  # locateSourceFile is fed a symlink and returns the originating file
  # usage: _locateSourceFile_ 'some/symlink'

  local TARGET_FILE
  local PHYS_DIR
  local RESULT

  TARGET_FILE="$1"

  cd "$(dirname $TARGET_FILE)" || die "Could not find TARGET FILE"
  TARGET_FILE="$(basename $TARGET_FILE)"

  # Iterate down a (possible) chain of symlinks
  while [ -L "$TARGET_FILE" ]
  do
    TARGET_FILE=$(readlink "$TARGET_FILE")
    cd "$(dirname $TARGET_FILE)" || die "Could not find TARGET FILE"
    TARGET_FILE="$(basename $TARGET_FILE)"
  done

  # Compute the canonicalized name by finding the physical path
  # for the directory we're in and appending the target file.
  PHYS_DIR=$(pwd -P)
  RESULT="$PHYS_DIR/$TARGET_FILE"
  echo "$RESULT"
}

_uniqueFileName_() {
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
  #   _uniqueFileName "/some/dir/file.txt" "-"
  #
  #   Would return "/some/dir/file-2.txt"

  local n origFull origName origExt newfile spacer

  origFull="$1"
  spacer="${2:- }"
  origName="${origFull%.*}"
  origExt="${origFull##*.}"
  newfile="${origName}.${origExt}"

  if [ -e "${newfile}" ]; then
    n=2
    while [[ -e "${origName}${spacer}${n}.${origExt}" ]]; do
      (( n++ ))
    done
    newfile="${origName}${spacer}${n}.${origExt}"
  fi

  echo "${newfile}"
}

_readFile_() {
  # Function to reads a file and prints each line.
  # Usage: _readFile_ "some/filename"
  local result

  while read -r result
  do
    echo "${result}"
  done < "${1:?Must specify a file for _readFile_}"
  unset result
}

_json2yaml_() {
  # convert json files to yaml using python and PyYAML
  # usage: _json2yaml_ "dir/somefile.json"
  python -c 'import sys, yaml, json; yaml.safe_dump(json.load(sys.stdin), sys.stdout, default_flow_style=False)' < "$1"
}

_yaml2json_() {
  # convert yaml files to json using python and PyYAML
  # usage: _yaml2json_ "dir/somefile.yaml"
  python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' < "$1"
}