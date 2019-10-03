#!/usr/bin/env bats
#shellcheck disable
#
load 'helpers/bats-support/load'
load 'helpers/bats-file/load'
load 'helpers/bats-assert/load'

s="${HOME}/dotfiles/bootstrap/config-linux.sh"
base="$(basename $s)"

sourceDIR="${HOME}/dotfiles/scripting/functions"

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

@test "Sanity..." {
  run true

  assert_success
  assert_output ""
}

@test "Fail on unknown argument" {
  run "$s" -LK

  assert_failure
  assert_output --partial "[  fatal] invalid option: '-K'."
}

@test "usage (-h)" {
  run "$s" -h

  assert_success
  assert_output --partial "Configures a new computer running linux."
}

@test "usage (--help)" {
  run "$s" --help

  assert_success
  assert_output --partial "Configures a new computer running linux."
}