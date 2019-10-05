#!/usr/bin/env bats
#shellcheck disable

load 'helpers/bats-support/load'
load 'helpers/bats-file/load'
load 'helpers/bats-assert/load'

_setPATH_() {
  # setPATH() Add homebrew and ~/bin to $PATH so the script can find executables
  PATHS=(/usr/local/bin $HOME/bin);
  for newPath in "${PATHS[@]}"; do
    if ! echo "$PATH" | grep -Eq "(^|:)${newPath}($|:)" ; then
      PATH="$newPath:$PATH"
   fi
 done
}
_setPATH_

if ! command -v trash &>/dev/null; then
  printf "No executable 'trash' found.\n" >&2
  printf "Can not run tests.\n" >&2
  exit 1
fi

s="$HOME/bin/trash"
base="$(basename "$s")"
user="$(whoami)"
trashFolder="/Users/${user}/.Trash"

setup() {
  testdir="$(temp_make)"
  curPath="$PWD"

  BATSLIB_FILE_PATH_REM="#${TEST_TEMP_DIR}"
  BATSLIB_FILE_PATH_ADD='<temp>'

  cd "${testdir}"
}

teardown() {
  cd "${curPath}"
  temp_del "${testdir}"

  if [ -n "${file}" ] && [ -e "${trashFolder}/${file}" ]; then
    file="$(basename "${file}")"
    command rm -rf "${trashFolder}/${file}"
    unset file
  fi
}

###########  RUN TESTS ##########

@test "sanity" {
  run true

  assert_success
  assert [ "$output" = "" ]
}

@test "Fail on unknown argument" {
  run $s -LK

  assert_failure
  assert_output --partial "[  fatal] invalid option: '-K'."
}

@test "Usage (no args)" {
  run $s

  assert_success
  assert_line --index 0 "  trash [OPTION]... [FILE]..."
}

@test "usage (-h)" {
  run $s -h

  assert_success
  assert_line --index 0 "  trash [OPTION]... [FILE]..."
}

@test "usage (--help)" {
  run $s --help

  assert_success
  assert_line --index 0 "  trash [OPTION]... [FILE]..."
}

@test "Fail when can't find file" {
  run $s -L "some-file-that-doesn't-exist"

  assert_success
  assert_output --partial "[warning] some-file-that-doesn't-exist: No such file or directory"
}

@test "Trashing a file" {
  file="1trash.bats.${RANDOM}.txt"
  touch "${file}"
  run $s "$file"

  assert_success
  assert_output --partial "[success] '${file}' moved to trash"
}

@test "Use system's 'rm'" {
  file="1trash.bats.${RANDOM}.txt"
  touch "${file}"
  run $s -s "$file"

  assert_success
  assert_output --partial "[success] '${file}' deleted"
}

@test "Dryrun (-n)" {
  file="1trash.bats.${RANDOM}.txt"
  touch "${file}"
  run $s -n "$file"

  assert_success
  assert_output --partial "[ dryrun] "
  assert_file_exist "${file}"
}

@test "Dryrun (--dryrun)" {
  file="1trash.bats.${RANDOM}.txt"
  touch "${file}"
  run $s --dryrun "$file"

  assert_success
  assert_output --partial "[ dryrun] "
  assert_file_exist "${file}"
}

@test "Quiet mode (-q)" {
  file="1trash.bats.${RANDOM}.txt"
  touch "${file}"
  run $s -q --dryrun "$file"

  assert_success
  refute_output --regexp '[a-zA-Z0-9\[\]]'
  assert_file_exist "${file}"
}

@test "Quiet mode (--quiet)" {
  file="1trash.bats.${RANDOM}.txt"
  touch "${file}"
  run $s --quiet --dryrun "$file"

  assert_success
  refute_output --regexp '[a-zA-Z0-9\[\]]'
  assert_file_exist "${file}"
}

@test "Verbose mode (-v)" {
  file="1trash.bats.${RANDOM}.txt"
  touch "${file}"
  run $s -v --dryrun "$file"

  assert_success
  assert_output --regexp "\[  debug\] Telling Finder to trash '${file}'..."
  assert_file_exist "${file}"
}

@test "Verbose mode (--verbose)" {
  file="1trash.bats.${RANDOM}.txt"
  touch "${file}"
  run $s --verbose --dryrun "$file"

  assert_success
  assert_output --regexp "\[  debug\] Telling Finder to trash '${file}'..."
  assert_file_exist "${file}"
}

@test "Trashing a directory" {
  file="2trash.bats.${RANDOM}"
  mkdir "${file}/"
  run $s "$file"

  assert_success
  assert_output --partial "[success] '${file}' moved to trash"
}

@test "Trashing a file in a directory" {
  dir="3trash.bats.${RANDOM}"
  file="3.1trash.bats.${RANDOM}.txt"
  mkdir "${dir}"
  touch "${dir}/${file}"
  run $s "${dir}/${file}"

  assert_success
  assert_output --partial "[success] '${file}' moved to trash"
}

@test "List trash contents (-l)" {
  file="4trash.bats.${RANDOM}.txt"
  touch "${file}"
  trash -q "${file}"
  run $s -l

  assert_success
  assert_line --index 0 --partial "[ notice] Listing items in Trash"
  assert_output --regexp "/Users/[a-zA-Z0-9]+/.Trash/${file}"
}

@test "List trash contents (--list)" {
  file="5trash.bats.${RANDOM}.txt"
  touch "${file}"
  trash -q "${file}"
  run $s --list

  assert_success
  assert_line --index 0 --partial "[ notice] Listing items in Trash"
  assert_output --regexp "/Users/[a-zA-Z0-9]+/.Trash/${file}"
}

@test "Empty Trash (-e)" {
  file="6trash.bats.${RANDOM}.txt"
  touch "${file}"
  trash -q "${file}"
  run $s -e --dryrun

  assert_success
  assert_output --partial "[ dryrun] /usr/bin/osascript -e 'tell application \"Finder\" to empty trash' (Trash emptied)"
}

@test "Empty Trash (--empty)" {
  file="6trash.bats.${RANDOM}.txt"
  touch "${file}"
  trash -q "${file}"
  run $s --empty --dryrun

  assert_success
  assert_output --partial "[ dryrun] /usr/bin/osascript -e 'tell application \"Finder\" to empty trash' (Trash emptied)"
}

@test "Empty Trash (-e, --bypassFinder)" {
  file="6trash.bats.${RANDOM}.txt"
  touch "${file}"
  trash -q "${file}"
  run $s -e --dryrun --bypassFinder

  assert_success
  assert_output --regexp "\[ dryrun\] rm -rf \"/Users/[a-zA-Z0-9]+/\.Trash/${file}\""
}