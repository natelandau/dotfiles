#!/usr/bin/env bats
#shellcheck disable
#
load 'helpers/bats-support/load'
load 'helpers/bats-file/load'
load 'helpers/bats-assert/load'

s="${HOME}/dotfiles/bootstrap/config-macOS.sh"
base="$(basename $s)"

[ -f "$s" ] \
  && { source "$s" --source-only ; trap - EXIT INT TERM ; } \
  || { echo "Can not find script to test" ; exit 1 ; }

sourceDIR="${HOME}/dotfiles/scripting/functions"

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

### Fixtures
YAML1="${BATS_TEST_DIRNAME}/fixtures/yaml1.yaml"
YAML1parse="${BATS_TEST_DIRNAME}/fixtures/yaml1.yaml.txt"
YAML2="${BATS_TEST_DIRNAME}/fixtures/yaml2.yaml"
symlinkYAML="${BATS_TEST_DIRNAME}/fixtures/symlinks.yaml"

@test "Sanity..." {
  run true

  assert_success
  assert_output ""
}

########### UNIQUE FUNCTION TESTS ##########

@test "_doSymlinks_" {
  mkdir "links"
  touch "testfile.txt" ".dotfile" "links/dotfile-link"

  local p="$(_realpath_ "testfile.txt")"
  local p="${p%/*}"

  _doSymlinks_ "$symlinkYAML"

  assert_success
  assert [ -L "${p}/links/testfile-link.txt" ]
  assert [ -L "${p}/links/dotfile-link" ]
  assert [ -f "backup/dotfile-link" ]
}

########### TAKING ARGUMENTS ###############
@test "Fail on unknown argument" {
  run $s -LK

  assert_failure
  assert_output --partial "[  fatal] invalid option: '-K'."
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

########### SHARED FUNCTION TESTS ##########

@test "_backupFile_: no source" {
  run _backupFile_ "testfile"

  assert_failure
}

@test "_backupFile_: backup file" {
  touch "testfile"
  run _backupFile_ "testfile" "backup-files"

  assert_success
  assert [ -f "backup-files/testfile" ]
}

@test "_backupFile_: default destination & rename" {
  mkdir backup
  touch "testfile" "backup/testfile"
  run _backupFile_ "testfile"

  assert_success
  assert [ -f "backup/testfile-2" ]
}

@test "_execute_: Debug command" {
  dryrun=true
  run _execute_ "rm testfile.txt"
  assert_success
  assert_output --partial "[ dryrun] rm testfile.txt"
  dryrun=false
}

@test "_execute_: No command" {
  run _execute_

  assert_failure
  assert_output --regexp "_execute_ needs a command$"
}

@test "_execute_: Bad command" {
  touch "testfile.txt"
  run _execute_ "rm nonexistant.txt"
  assert_failure
  assert_output --partial "[warning] rm nonexistant.txt"
  assert_file_exist "testfile.txt"
}

@test "_execute_: Good command" {
  touch "testfile.txt"
  run _execute_ "rm testfile.txt"
  assert_success
  assert_output --partial "[ notice] rm testfile.txt"
  assert_file_not_exist "testfile.txt"
}

@test "_haveFunction_: Success" {
  run _haveFunction_ "_haveFunction_"

  assert_success
}

@test "_haveFunction_: Failure" {
  run _haveFunction_ "_someUndefinedFunction_"

  assert_failure
}

@test "_locateSourceFile_: Resolve symlinks" {
  ln -s "$sourceDIR" "testSymlink"

  run _locateSourceFile_ "testSymlink"
  assert_output "$sourceDIR"
}

@test "_ltrim_" {
  local text=$(_ltrim_ <<<"    some text")

  run echo "$text"
  assert_output "some text"
}

@test "_makeSymlink_: No source" {
  run _makeSymlink_ "sourceFile" "destFile"

  assert_failure
}

@test "_makeSymlink_: empty destination" {
  touch "test.txt"
  run _makeSymlink_ "test.txt"

  assert_failure
}

@test "_makeSymlink_: create symlink" {
  touch "test.txt"
  run _makeSymlink_ "test.txt" "test2.txt"

  assert_success
  assert [ -h "test2.txt" ]
}

@test "_makeSymlink_: backup original file" {
  touch "test.txt"
  touch "test2.txt"
  run _makeSymlink_ "test.txt" "test2.txt"

  assert_success
  assert [ -h "test2.txt" ]
  assert [ -f "backup/test2.txt" ]
}

@test "_parseYAML_: success" {
  run _parseYAML_ "$YAML1"
  assert_success
  assert_output "$( cat "$YAML1parse")"
}

@test "_parseYAML_: empty file" {
  touch empty.yaml
  run _parseYAML_ "empty.yaml"
  assert_failure
}

@test "_parseYAML_: no file" {
  run _parseYAML_ "empty.yaml"
  assert_failure
}

@test "_readFile_: Reads files line by line" {
  echo -e "line 1\nline 2\nline 3" > testfile.txt

  run _readFile_ "testfile.txt"
  assert_line --index 0 'line 1'
  assert_line --index 2 'line 3'
}

@test "_readFile_: Failure" {
  run _readFile_ "testfile.txt"
  assert_failure
}

@test "_realpath_: true" {
  touch testfile.txt
  run _realpath_ "testfile.txt"
  assert_success
  assert_output --regexp "^/private/var/folders/.*/testfile.txt$"
}

@test "_realpath_: fail" {
  run _realpath_ "testfile.txt"
  assert_failure
}

@test "_rtrim_" {
  local text=$(_rtrim_ <<<"some text    ")

  run echo "$text"
  assert_output "some text"
}

@test "_seekConfirmation_: yes" {
  run _seekConfirmation_ 'test' <<<"y"

  assert_success
  assert_output --partial "[  input] test"
}

@test "_seekConfirmation_: no" {
  run _seekConfirmation_ 'test' <<<"n"

  assert_failure
  assert_output --partial "[  input] test"
}

@test "_seekConfirmation_: Force" {
  force=true

  run _seekConfirmation_ "test"
  assert_success
  assert_output --partial "test"

  force=false
}

@test "_seekConfirmation_: Quiet" {
  quiet=true
  run _seekConfirmation_ 'test' <<<"y"

  assert_success
  refute_output --partial "test"

  quiet=false
}

@test "_setdiff_: Print elements not common to arrays" {
  run _setdiff_ "${A[*]}" "${B[*]}"
  assert_output "one two three"

  run _setdiff_ "${B[*]}" "${A[*]}"
  assert_output "4 5 6"
}

@test "_sourceFile_ failure" {
  run _sourceFile_ "someNonExistantFile"

  assert_failure
  assert_output --partial "'someNonExistantFile' not found"
}

@test "_sourceFile_ success" {
  echo "echo 'hello world'" > "testSourceFile.txt"
  run _sourceFile_ "testSourceFile.txt"

  assert_success
  assert_output "hello world"
}

@test "_uniqueFileName_: Count to 3" {
  touch "test.txt"
  touch "test-2.txt"

  run _uniqueFileName_ "test.txt"
  assert_output --regexp ".*/test-3.txt$"
}

@test "_uniqueFileName_: Don't confuse existing numbers" {
  touch "test-2.txt"

  run _uniqueFileName_ "test-2.txt"
  assert_output --regexp ".*/test-2-2.txt$"
}

@test "_uniqueFileName_: User specified separator" {
  touch "test.txt"

  run _uniqueFileName_ "test.txt" " "
  assert_output --regexp ".*/test 2.txt$"
}

@test "_uniqueFileName_: failure" {
  touch "testfile"
  run _uniqueFileName_

  assert_failure
}

### Logging ####

@test "info" {
  run info "testing"
  assert_output --regexp "[0-9]+:[0-9]+:[0-9]+ (AM|PM) \[   info\] testing"
}

@test "error" {
  run error "testing"
  assert_output --regexp "\[  error\] testing"
}

@test "warning" {
  run warning "testing"
  assert_output --regexp "\[warning\] testing"
}

@test "success" {
  run success "testing"
  assert_output --regexp "\[success\] testing"
}

@test "notice" {
  run notice "testing"
  assert_output --regexp "\[ notice\] testing"
}

@test "header" {
  run header "testing"
  assert_output --regexp "\[ header\] == testing =="
}

@test "input" {
  run input "testing"
  assert_output --partial "[  input] testing"
}

@test "debug" {
  run debug "testing"
  assert_output --partial "[  debug] testing"
}

@test "die" {
  run die "testing"

  assert_failure
  assert_line --index 0 --partial "[  fatal] testing"
}

@test "quiet" {
  quiet=true
  run notice "testing"
  assert_success
  refute_output --partial "testing"
  quiet=false
}

@test "verbose" {
  run verbose "testing"
  refute_output --regexp "\[  debug\] testing"

  verbose=true
  run verbose "testing"
  assert_output --regexp "\[  debug\] testing"
  verbose=false
}

@test "logging" {
  printLog=true ; logFile="testlog"
  notice "testing"
  info "testing again"
  success "last test"

  assert_file_exist "${logFile}"

  run cat "${logFile}"
  assert_line --index 0 --partial "[ notice] testing"
  assert_line --index 1 --partial "[   info] testing again"
  assert_line --index 2 --partial "[success] last test"

  printLog=false
}