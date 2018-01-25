#!/usr/bin/env bats
#shellcheck disable

load 'helpers/bats-support/load'
load 'helpers/bats-file/load'
load 'helpers/bats-assert/load'

s="${HOME}/dotfiles/scripting/helpers/numbers.bash"
base="$(basename $s)"

[ -f "$s" ] \
  && { source "$s"; trap - EXIT INT TERM ; } \
  || { echo "Can not find script to test" ; exit 1 ; }

# Set Flags
quiet=false;              printLog=false;             verbose=false;
force=false;              strict=false;               dryrun=false;
debug=false;              sourceOnly=false;           args=();

setup() {

  # Set arrays
  A=(one two three 1 2 3)
  B=(1 2 3 4 5 6)

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

########### BEGIN TESTS ##########

@test "_convertSecs_: Seconds to human readable" {

  run _fromSeconds_ "9255"
  assert_success
  assert_output "02:34:15"
}

@test "_toSeconds_: HH MM SS to Seconds" {
  run _toSeconds_ 12 3 33
  assert_success
  assert_output "43413"
}

@test "_countdown_" {
  run _countdown_ 10 0 "something"
  assert_line --index 0 --partial "something 10"
  assert_line --index 9 --partial "something 1"
}
