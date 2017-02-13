#!/usr/bin/env bash
# shellcheck disable=2154

# ###############
#
# Shared utilities for bootstrap scripts
#
# ###############

function _backupOriginalFile_() {
  local newFile
  local backupDir

  # Set backup directory location
  backupDir="${baseDir}/dotfiles_backup"

  if [[ ! -d "$backupDir" && "$dryrun" == false ]]; then
    execute "mkdir $backupDir" "Creating backup directory"
  fi

  if [ -e "$1" ]; then
    newFile="$(basename $1)"
    execute "cp -R ${1} ${backupDir}/${newFile#.}" "Backing up: ${newFile}"
  fi
}

function _executeFunction_() {
  local functionName="$1"
  local functionDesc="${2:-next step?}"

  if seek_confirmation "${functionDesc}?"; then
    "${functionName}"
  fi
}

function _createSymlinks_() {
  # This function takes an input of the YAML variable containing the symlinks to be linked
  # and then creates the appropriate symlinks in the home directory. it will also backup existing files if there.

  local link=""
  local destFile=""
  local sourceFile=""

  header "Creating ${1:-symlinks}"

  # For each link do the following
  for link in "${filesToLink[@]}"; do
    verbose "Working on: $link"
    # Parse destination and source
    destFile=$(echo "$link" | cut -d':' -f1 | _trim_)
    sourceFile=$(echo "$link" | cut -d':' -f2 | _trim_)
    sourceFile=$(echo "$sourceFile" | cut -d'#' -f1 | _trim_) # remove comments if exist

    # Fix files where $HOME is written as '~'
    destFile="${destFile/\~/$HOME}"

    # Grab the absolute path for the source
    sourceFile="${baseDir}/$sourceFile"

    # If we can't find a source file, skip it
    if ! test -e "$sourceFile"; then
      warning "Can't find '$sourceFile'."
      continue
    fi

    # Now we symlink the files
    if [ ! -e "$destFile" ]; then
      execute "ln -fs $sourceFile $destFile" "symlink $sourceFile → $destFile"
    elif [ -h "$destFile" ]; then
      originalFile=$(locateSourceFile "$destFile")
      _backupOriginalFile_ "$originalFile"
      if ! $dryrun; then rm -rf "$destFile"; fi
      execute "ln -fs $sourceFile $destFile" "symlink $sourceFile → $destFile"
    elif [ -e "$destFile" ]; then
      _backupOriginalFile_ "$destFile"
      if ! $dryrun; then rm -rf "$destFile"; fi
      execute "ln -fs $sourceFile $destFile" "symlink $sourceFile → $destFile"
    else
      warning "Error linking: $sourceFile → $destFile"
    fi
  done
}

function _ltrim_() {
  # Removes all leading whitespace (from the left).
  local char=${1:-[:space:]}
    sed "s%^[${char//%/\\%}]*%%"
}

function _rtrim_() {
  # Removes all trailing whitespace (from the right).
  local char=${1:-[:space:]}
  sed "s%[${char//%/\\%}]*$%%"
}

function _trim_() {
  # Removes all leading/trailing whitespace
  # Usage examples:
  #     echo "  foo  bar baz " | _trim_  #==> "foo  bar baz"
  _ltrim_ "$1" | _rtrim_ "$1"
}

function _parse_yaml_() {
  # Function to parse YAML files and add values to variables. Send it to a temp file and source it
  # https://gist.github.com/DinoChiesa/3e3c3866b51290f31243 which is derived from
  # https://gist.github.com/epiloque/8cf512c6d64641bde388
  #
  # Usage:
  #     $ parse_yaml sample.yml > /some/tempfile
  #     $ source /some/tempfile
  #
  # parse_yaml accepts a prefix argument so that imported settings all have a common prefix
  # (which will reduce the risk of name-space collisions).
  #
  #     $ parse_yaml sample.yml "CONF_"

    local prefix=$2
    local s
    local w
    local fs
    s='[[:space:]]*'
    w='[a-zA-Z0-9_]*'
    fs="$(echo @|tr @ '\034')"
    sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$1" |
    awk -F"$fs" '{
      indent = length($1)/2;
      if (length($2) == 0) { conj[indent]="+";} else {conj[indent]="";}
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
              vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
              printf("%s%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, conj[indent-1],$3);
      }
    }' | sed 's/_=/+=/g'
}

function _readFile_() {
  # readFile
  # ------------------------------------------------------
  # Function to read a line from a file.
  # Outputs each line in a variable named $result
  # ------------------------------------------------------
  local result
  while read -r result
  do
    if $verbose; then
      verbose "${result}"
    else
      echo "${result}"
    fi
  done < "$1"
}

function locateSourceFile() {
  # locateSourceFile is fed a symlink and returns the originating file
  # usage:  $ locateSourceFile 'some/symlink'

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
    cd "$(dirname $TARGET_FILE)"  || die "Could not find TARGET FILE"
    TARGET_FILE="$(basename $TARGET_FILE)"
  done

  # Compute the canonicalized name by finding the physical path
  # for the directory we're in and appending the target file.
  PHYS_DIR=$(pwd -P)
  RESULT="$PHYS_DIR/$TARGET_FILE"
  echo "$RESULT"
}

function _setdiff_() {
  # Given strings containing space-delimited words A and B, "setdiff A B" will
  # return all words in A that do not exist in B. Arrays in bash are insane
  # (and not in a good way).
  #
  #   Usage: setdiff "${array1[*]}" "${array2[*]}"
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