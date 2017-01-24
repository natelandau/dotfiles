#!/usr/bin/env bash

zipf () { zip -r "$1".zip "$1" ; }        # zipf:       To create a ZIP archive of a folder
alias numFiles='echo $(ls -1 | wc -l)'    # numFiles:   Count of non-hidden files in current dir
alias make1mb='mkfile 1m ./1MB.dat'       # make1mb:    Creates a file of 1mb size (all zeros)
alias make5mb='mkfile 5m ./5MB.dat'       # make5mb:    Creates a file of 5mb size (all zeros)
alias make10mb='mkfile 10m ./10MB.dat'    # make10mb:   Creates a file of 10mb size (all zeros)

function buf () {
  # buf :  Backup file with time stamp
  local filename
  local filetime
  filename="${1}"
  filetime=$(date +%Y%m%d_%H%M%S)
  cp -a "${filename}" "${filename}_${filetime}"
}

function extract() {
  local filename
  local foldername
  local fullpath
  local didfolderexist

  # Extract archives - use: extract <file>
  # Based on http://dotfiles.org/~pseup/.bashrc
  if [ -f "$1" ] ; then
    filename="$(basename "$1")"
    foldername="${filename%%.*}"
    fullpath=$(perl -e 'use Cwd "abs_path";print abs_path(shift)' "$1")
    didfolderexist=false
    if [ -d "$foldername" ]; then
      didfolderexist=true
      read -p "$foldername already exists, do you want to overwrite it? (y/n) " -n 1
      echo
      if [[ $REPLY =~ ^[Nn]$ ]]; then
        return
      fi
    fi
    mkdir -p "$foldername" && cd "$foldername"
    case $1 in
      *.tar.bz2) tar xjf "$fullpath" ;;
      *.tar.gz) tar xzf "$fullpath" ;;
      *.tar.xz) tar Jxvf "$fullpath" ;;
      *.tar.Z) tar xzf "$fullpath" ;;
      *.tar) tar xf "$fullpath" ;;
      *.taz) tar xzf "$fullpath" ;;
      *.tb2) tar xjf "$fullpath" ;;
      *.tbz) tar xjf "$fullpath" ;;
      *.tbz2) tar xjf "$fullpath" ;;
      *.tgz) tar xzf "$fullpath" ;;
      *.txz) tar Jxvf "$fullpath" ;;
      *.zip) unzip "$fullpath" ;;
      *) echo "'$1' cannot be extracted via extract()" && cd .. && ! $didfolderexist && rm -r "$foldername" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}


function chgext() {
  # chgext: Batch change extension
  #         For example 'chgext html php' will turn a directory of HTML files
  #         into PHP files.
  for file in *.$1 ; do mv "$file" "${file%.$1}.$2" ; done
}

function j2y() {
  # convert json files to yaml using python and PyYAML
  python -c 'import sys, yaml, json; yaml.safe_dump(json.load(sys.stdin), sys.stdout, default_flow_style=False)' < "$1"
}

function y2j() {
  # convert yaml files to json using python and PyYAML
  python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' < "$1"
}