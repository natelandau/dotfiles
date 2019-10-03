#!/usr/bin/env bats
# shellcheck disable

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

if ! command -v "${HOME}/bin/updateHomebrew" &>/dev/null; then
    printf "No executable 'updateHomebrew' found.\n" >&2
    printf "Can not run tests.\n" >&2
    exit 1
else
    s="${HOME}/bin/updateHomebrew"
    base="$(basename "$s")"
fi

setup() {
  testdir="$(temp_make)"
  curPath="$PWD"

  BATSLIB_FILE_PATH_REM="#${TEST_TEMP_DIR}"
  BATSLIB_FILE_PATH_ADD='<temp>'

  cd "${testdir}"
}

teardown() {
  cd $curPath
  temp_del "${testdir}"
}

@test "sanity" {
  [[ "$OSTYPE" != "darwin"* ]] && skip "not MacOS"
  run true
  assert_success
  assert [ "$output" = "" ]
}

@test "Fail - bad args" {
  [[ "$OSTYPE" != "darwin"* ]] && skip "not MacOS"
  run "$s" -K
  assert_failure
  assert_output --partial "[  fatal] invalid option: '-K'"
}

@test "usage (-h)" {
  [[ "$OSTYPE" != "darwin"* ]] && skip "not MacOS"
  run "$s" -h

  assert_success
  assert_line --index 0 "  updateHomebrew [OPTION]..."
}

@test "usage (--help)" {
  [[ "$OSTYPE" != "darwin"* ]] && skip "not MacOS"
  run "$s" --help

  assert_success
  assert_line --index 0 "  updateHomebrew [OPTION]..."
}

@test "Dryrun (-n)" {
  [[ "$OSTYPE" != "darwin"* ]] && skip "not MacOS"
  run "$s" -n

  assert_success
  assert_line --index 0 --partial "[ notice] Updating Homebrew..."
  assert_line --index 2 --partial "[ dryrun] brew upgrade (line:"
}

@test "Dryrun (--dryrun)" {
  [[ "$OSTYPE" != "darwin"* ]] && skip "not MacOS"
  run "$s" --dryrun

  assert_success
  assert_line --index 0 --partial "[ notice] Updating Homebrew..."
  assert_line --index 2 --partial "[ dryrun] brew upgrade (line:"
}