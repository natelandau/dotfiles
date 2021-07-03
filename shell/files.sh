#!/usr/bin/env bash

md5Check() {
  local opt
  local OPTIND=1
  local md5="$1"
  local file="$2"

  while getopts "hv" opt; do
    case "$opt" in
      h)
        cat <<End-Of-Usage
  Compares an md5 hash to the md5 hash of a file

  Usage: ${FUNCNAME[0]} [option] <md5> <filename>

  options:
    -h  show this message and exit
End-Of-Usage
        return
        ;;
      ?)
        md5Check -h >&2
        return 1
        ;;
    esac
  done
  shift $((OPTIND - 1))

  if ! command -v md5sum &>/dev/null; then
    echo "Can not find 'md5sum' utility"
    return 1
  fi

  [ ! -e "${file}" ] \
    && {
      echo "Can not find ${file}"
      return 1
    }

  # Get md5 has of file
  local filemd5="$(md5sum "${file}" | awk '{ print $1 }')"

  if [[ "$filemd5" == "$md5" ]]; then
    success "The two md5 hashes match"
    return 0
  else
    warning "The two md5 hashes do not match"
    return 1
  fi

}

zipf() { zip -r "$1".zip "$1"; }       # zipf:       To create a ZIP archive of a folder
alias numFiles='echo $(ls -1 | wc -l)' # numFiles:   Count of non-hidden files in current dir
alias make1mb='mkfile 1m ./1MB.dat'    # make1mb:    Creates a file of 1mb size (all zeros)
alias make5mb='mkfile 5m ./5MB.dat'    # make5mb:    Creates a file of 5mb size (all zeros)
alias make10mb='mkfile 10m ./10MB.dat' # make10mb:   Creates a file of 10mb size (all zeros)

buf() {
  # buf :  Backup file with time stamp
  local filename
  local filetime

  filename="${1}"
  filetime=$(date +%Y%m%d_%H%M%S)
  cp -a "${filename}" "${filename}_${filetime}"
}

extract() {
  local opt
  local OPTIND=1

  while getopts "hv" opt; do
    case "$opt" in
      h)
        cat <<End-Of-Usage
Usage: ${FUNCNAME[0]} [option] <archives>
  options:
    -h  show this message and exit
    -v  verbosely list files processed
End-Of-Usage
        return
        ;;
      v)
        local -r verbose='v'
        ;;
      ?)
        extract -h >&2
        return 1
        ;;
    esac
  done
  shift $((OPTIND - 1))

  [ $# -eq 0 ] && extract -h && return 1
  while [ $# -gt 0 ]; do
    if [ -f "$1" ]; then
      case "$1" in
        *.tar.bz2 | *.tbz | *.tbz2) tar "x${verbose}jf" "$1" ;;
        *.tar.gz | *.tgz) tar "x${verbose}zf" "$1" ;;
        *.tar.xz)
          xz --decompress "$1"
          set -- "$@" "${1:0:-3}"
          ;;
        *.tar.Z)
          uncompress "$1"
          set -- "$@" "${1:0:-2}"
          ;;
        *.bz2) bunzip2 "$1" ;;
        *.deb) dpkg-deb -x${verbose} "$1" "${1:0:-4}" ;;
        *.pax.gz)
          gunzip "$1"
          set -- "$@" "${1:0:-3}"
          ;;
        *.gz) gunzip "$1" ;;
        *.pax) pax -r -f "$1" ;;
        *.pkg) pkgutil --expand "$1" "${1:0:-4}" ;;
        *.rar) unrar x "$1" ;;
        *.rpm) rpm2cpio "$1" | cpio -idm${verbose} ;;
        *.tar) tar "x${verbose}f" "$1" ;;
        *.txz)
          mv "$1" "${1:0:-4}.tar.xz"
          set -- "$@" "${1:0:-4}.tar.xz"
          ;;
        *.xz) xz --decompress "$1" ;;
        *.zip | *.war | *.jar) unzip "$1" ;;
        *.Z) uncompress "$1" ;;
        *.7z) 7za x "$1" ;;
        *) echo "'$1' cannot be extracted via extract" >&2 ;;
      esac
    else
      echo "extract: '$1' is not a valid file" >&2
    fi
    shift
  done
}

chgext() {
  # chgext: Batch change extension
  #         For example 'chgext html php' will turn a directory of HTML files
  #         into PHP files.

  local f
  for f in *."$1"; do mv "$f" "${f%.$1}.$2"; done
}

j2y() {
  # convert json files to yaml using python and PyYAML
  python -c 'import sys, yaml, json; yaml.safe_dump(json.load(sys.stdin), sys.stdout, default_flow_style=False)' <"$1"
}

y2j() {
  # convert yaml files to json using python and PyYAML
  python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' <"$1"
}
