#!/usr/bin/env bats
#shellcheck disable
#
load 'helpers/bats-support/load'
load 'helpers/bats-file/load'
load 'helpers/bats-assert/load'

s="${HOME}/dotfiles/bootstrap/install-linux-gnu.sh"
base="$(basename $s)"

[ -f "$s" ] \
  && { source "$s" --source-only ; trap - EXIT INT TERM ; } \
  || { echo "Can not find script to test" ; exit 1 ; }



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

@test "_ltrim_" {
  local text=$(_ltrim_ <<<"    some text")

  run echo "$text"
  assert_output "some text"
}

@test "_rtrim_" {
  local text=$(_rtrim_ <<<"some text    ")

  run echo "$text"
  assert_output "some text"
}

@test "_setdiff_" {
  # Set arrays
  local A=(one two three 1 2 3)
  local B=(1 2 3 4 5 6)

  run _setdiff_ "${A[*]}" "${B[*]}"
  assert_output "one two three"

  run _setdiff_ "${B[*]}" "${A[*]}"
  assert_output "4 5 6"
}

@test "_execute_: quiet" {
  touch testfile.txt
  run _execute_ "rm testfile.txt"

  assert_success
  assert_line --index 0 --partial "[success] rm testfile.txt"
  assert_file_not_exist "testfile.txt"
}

@test "_execute_: verbose" {
  verbose=true
  touch testfile.txt
  run _execute_ "rm -v testfile.txt" "testing worked"

  assert_success
  assert_line --index 0 "removed 'testfile.txt'"
  assert_line --index 1 --partial "[success] testing worked"
  assert_file_not_exist "testfile.txt"

  verbose=false
}

@test "_parseYAML_" {
  YAML1="${BATS_TEST_DIRNAME}/fixtures/yaml1.yaml"
  YAML1parse="${BATS_TEST_DIRNAME}/fixtures/yaml1.yaml.txt"
  run _parseYAML_ "$YAML1"
  assert_success
  assert_output "$( cat "$YAML1parse")"
}

@test "_trim_" {
  local text=$(_trim_ <<<"    some text     ")

  run echo "$text"
  assert_output "some text"
}

@test "_seekConfirmation_" {
  run _seekConfirmation_ 'test' <<<"y"

  assert_success
  assert_output --partial "[  input] test"
}

@test "_backupOriginalFile_" {
  baseDir="$testdir"
  touch testfile.txt

  run _backupOriginalFile_ "testfile.txt"

  assert_success
  assert_file_exist "${baseDir}/dotfiles_backup/testfile.txt"
  assert_line --index 0 --partial "[success] Creating backup directory"
  assert_line --index 1 --partial "[success] Backing up: testfile.txt"
}

@test "_locateSourceFile_" {
  ln -s "$s" "testSymlink.txt"

  run _locateSourceFile_ "testSymlink.txt"
  assert_output "$s"
}

@test "_findBaseDir_" {
  run _findBaseDir_

  assert_output "${HOME}/dotfiles/bootstrap"
}

@test "Quiet mode" {
  quiet=true
  run success "Working"

  assert_success
  refute_output --regexp '[a-zA-Z0-9\[\]]'
  quiet=false
}

@test "_readFile_" {
cat >testfile.txt <<EOL
line 1
line 2
line 3
EOL

  run _readFile_ "testfile.txt"
  assert_line --index 0 'line 1'
  assert_line --index 2 'line 3'
}