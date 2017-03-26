#!/usr/bin/env bats
#shellcheck disable
#
load 'helpers/bats-support/load'
load 'helpers/bats-file/load'
load 'helpers/bats-assert/load'

s="${HOME}/dotfiles/install.sh"
base="$(basename $s)"

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

###########  RUN TESTS ##########

@test "sanity" {
  run true

  assert_success
  assert_output ""
}

@test "Fail on unknown argument" {
  run $s -K

  assert_failure
  assert_output --partial "[  error] invalid option: '-K'. Exiting."
}

@test "Print version (--version)" {
  run $s --version

  assert_success
  assert_output --regexp "$base [v|V]?[0-9]+\.[0-9]+\.[0-9]+"
}

@test "Usage (no args)" {
  skip "Script runs without args"
  run $s

  assert_success
  assert_line --index 0 "$base [OPTION]... [FILE]..."
}

@test "usage (-h)" {
  run $s -h

  assert_success
  assert_line --index 0 "$base [OPTION]... [FILE]..."
}

@test "usage (--help)" {
  run $s --help

  assert_success
  assert_line --index 0 "$base [OPTION]... [FILE]..."
}

@test "Able to source config file" {
  run $s -vnu
  assert_success
  assert_line --index 0 --partial "[  debug] -- Config Variables --"
  assert_line --index 1 --partial "symlinks+="
}