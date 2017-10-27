#!/usr/bin/env bats
#shellcheck disable

load 'helpers/bats-support/load'
load 'helpers/bats-file/load'
load 'helpers/bats-assert/load'

s="${HOME}/dotfiles/scripting/helpers/files.bash"
base="$(basename $s)"

source "${HOME}/dotfiles/scripting/helpers/arrays.bash"

[ -f "$s" ] \
  && { source "$s"; trap - EXIT INT TERM ; } \
  || { echo "Can not find script to test" ; exit 1 ; }

# Fixtures
  YAML1="${BATS_TEST_DIRNAME}/fixtures/yaml1.yaml"
  YAML1parse="${BATS_TEST_DIRNAME}/fixtures/yaml1.yaml.txt"
  YAML2="${BATS_TEST_DIRNAME}/fixtures/yaml2.yaml"
  JSON="${BATS_TEST_DIRNAME}/fixtures/json.json"
  unencrypted="${BATS_TEST_DIRNAME}/fixtures/test.md"
  encrypted="${BATS_TEST_DIRNAME}/fixtures/test.md.enc"

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

########### BEGIN TESTS ########

@test "_inArray_: success" {
  run _inArray_ one "${A[@]}"
  assert_success
}

@test "_inArray_: failure" {
  run _inArray_ ten "${A[@]}"
  assert_failure
}

@test "_join_: Join array comma" {
  run _join_ , "${B[@]}"
  assert_output "1,2,3,4,5,6"
}

@test "_join_: Join array space" {
  run _join_ " " "${B[@]}"
  assert_output "1 2 3 4 5 6"
}

@test "_join_: Join string complex" {
  run _join_ , a "b c" d
  assert_output "a,b c,d"
}

@test "_join_: join string simple" {
  run _join_ / var usr tmp
  assert_output "var/usr/tmp"
}

@test "_setdiff_: Print elements not common to arrays" {
  run _setdiff_ "${A[*]}" "${B[*]}"
  assert_output "one two three"

  run _setdiff_ "${B[*]}" "${A[*]}"
  assert_output "4 5 6"
}