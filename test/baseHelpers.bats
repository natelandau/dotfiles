#!/usr/bin/env bats
#shellcheck disable

load 'helpers/bats-support/load'
load 'helpers/bats-file/load'
load 'helpers/bats-assert/load'

s="${HOME}/dotfiles/scripting/helpers/baseHelpers.bash"
base="$(basename $s)"

[ -f "$s" ] \
  && { source "$s"; trap - EXIT INT TERM ; } \
  || { echo "Can not find script to test" ; exit 1 ; }

# Set Flags
quiet=false;              printLog=false;             logErrors=true;   verbose=false;
force=false;              strict=false;               dryrun=false;
debug=false;              sourceOnly=false;           logErrors=false;   args=();

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

########### BEGIN TESTS ##########

@test "_alert_: success" {
  run success "testing"
  assert_output --regexp "\[success\] testing"
}

@test "_alert_: quiet" {
  quiet=true
  run notice "testing"
  assert_success
  refute_output --partial "testing"
  quiet=false
}

@test "_alert_: verbose" {
  run verbose "testing"
  refute_output --regexp "\[  debug\] testing"

  verbose=true
  run verbose "testing"
  assert_output --regexp "\[  debug\] testing"
  verbose=false
}

@test "_alert_: warning" {
  run warning "testing"
  assert_output --regexp "\[warning\] testing"
}

@test "_alert_: header" {
  run header "testing"
  assert_output --regexp "\[ header\] == testing =="
}

@test "_alert_: info" {
  run info "testing"
  assert_output --regexp "[0-9]+:[0-9]+:[0-9]+ (AM|PM) \[   info\] testing"
}

@test "_alert_: input" {
  run input "testing"
  assert_output --partial "[  input] testing"
}

@test "_alert_: logging" {
  printLog=true; logFile="${HOME}/tmp/bats-baseHelpers-test.log";
  [ -e "${logFile}" ] && rm "$logFile"
  header "$logFile"
  dryrun "dryrun"
  notice "tes${purple}ting"
  info "testing ${tan}again"
  success "last test"

  assert_file_exist "${logFile}"
  cp "${logFile}" "/Users/nlandau/Desktop/LogLOGLOGLOGLOGLOGLOG.txt"
  run cat "${logFile}"
  assert_line --index 0 --partial "[ header] == /Users/nlandau/tmp/bats-baseHelpers-test.log =="
  assert_line --index 1 --partial "[ dryrun] dryrun"
  assert_line --index 2 --partial "[ notice] testing"
  assert_line --index 3 --partial "[   info] testing again"
  assert_line --index 4 --partial "[success] last test"

  rm "$logFile"
  printLog=false; unset logFile;
}

@test "_alert_: logging: Errors only" {
  printLog=false; logErrors=true; logFile="${HOME}/tmp/bats-baseHelpers-tests.log"; quiet=true;
  [ -e "${logFile}" ] && rm "$logFile"
  header "$logFile"
  dryrun "dryrun"
  notice "testing"
  info "testing again"
  success "last test"
  error "test error"
  warning "test warning"

  assert_file_exist "${logFile}"

  run cat "${logFile}"
  assert_line --index 0 --regexp  ".*\[  error\] test error \( test_.*<.*<.* \)"

  rm "$logFile"
  printLog=false; logErrors=false; quiet=false; unset logFile;
}

@test "_alert_: notice" {
  run notice "testing"
  assert_output --regexp "\[ notice\] testing"
}

@test "_alert_: notice: with LINE" {
  run notice "testing" "$LINENO"
  assert_output --regexp ".*\[ notice\] testing \(line: [0-9]{1,3}\)"
}

@test "_alert_: refute debug" {
  run debug "testing"
  refute_output --partial "[  debug] testing"
}

@test "_alert_: assert debug" {
  verbose=true
  run debug "testing"
  assert_output --partial "[  debug] testing"
  verbose=false
}

@test "_alert_: die" {
  run die "testing"
  assert_line --index 0 --regexp ".*\[  fatal\] testing \( run:.*\)"
}

@test "_alert_: fatal: with LINE" {
  run fatal "testing" "$LINENO"
  assert_line --index 0 --regexp ".*\[  fatal\] testing \(line: [0-9]{1,3}\) \( run:.*\)"
}

@test "_alert_: error" {
  run error "testing"
  assert_output --regexp  ".*\[  error\] testing \( run:.*\)"
}

@test "_checkBinary_: true" {
  run _checkBinary_ "vi"
  assert_success
}

@test "_checkBinary_: false" {
  run _checkBinary_ "someNonexistantBinary"
  assert_failure
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

@test "_execute_ -e: Bad command" {
  touch "testfile.txt"
  run _execute_ -e "rm nonexistant.txt"

  assert_failure
  assert_output --partial "error: rm nonexistant.txt"
  assert_file_exist "testfile.txt"
}

@test "_execute_ -p: Return 0 on bad command" {
  touch "testfile.txt"
  run _execute_ -p "rm nonexistant.txt"

  assert_success
  assert_output --partial "[warning] rm nonexistant.txt"
  assert_file_exist "testfile.txt"
}

@test "_execute_: Good command" {
  touch "testfile.txt"
  run _execute_ "rm testfile.txt"
  assert_success
  assert_output --partial "[   info] rm testfile.txt"
  assert_file_not_exist "testfile.txt"
}

@test "_execute_: Good command - no output" {
  touch "testfile.txt"
  run _execute_ -q "rm testfile.txt"
  assert_success
  refute_output --partial "[   info] rm testfile.txt"
  assert_file_not_exist "testfile.txt"
}

@test "_execute_ -s: Good command" {
  touch "testfile.txt"
  run _execute_ -s "rm testfile.txt"
  assert_success
  assert_output --partial "[success] rm testfile.txt"
  assert_file_not_exist "testfile.txt"
}

@test "_execute_ -v: Good command" {
  touch "testfile.txt"
  run _execute_ -v "rm -v testfile.txt"

  assert_success
  assert_line --index 0 "removed 'testfile.txt'"
  assert_line --index 1 --partial "[   info] rm -v testfile.txt"
  assert_file_not_exist "testfile.txt"
}

@test "_execute_ -ev: Good command" {
  touch "testfile.txt"
  run _execute_ -ve "rm -v testfile.txt"

  assert_success
  assert_line --index 0 "removed 'testfile.txt'"
  assert_line --index 1 --partial "rm -v testfile.txt"
  assert_file_not_exist "testfile.txt"
}

@test "_findBaseDir_" {
  run _findBaseDir_
  assert_output "/usr/local/Cellar/bats/0.4.0/libexec"
}

@test "_haveFunction_: Success" {
  run _haveFunction_ "_haveFunction_"

  assert_success
}

@test "_haveFunction_: Failure" {
  run _haveFunction_ "_someUndefinedFunction_"

  assert_failure
}

@test "_makeTempDir_" {
  verbose="true"
  run _makeTempDir_
  assert_success
  assert_output --regexp '\$tmpDir=\/.*\/bats-exec-test\.[0-9]{3,6}\.[0-9]{3,6}\.[0-9]{3,6}\.[0-9]{3,6}'

  verbose="false"
}

@test "_progressBar_: verbose" {
  verbose=true
  run _progressBar_ 100

  assert_success
  assert_output ""
  verbose=false
}

@test "_progressBar_: quiet" {
  quiet=true
  run _progressBar_ 100

  assert_success
  assert_output ""
  quiet=false
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

@test "_setPATH_" {
  _setPATH_ "/testing/from/bats" "/testing/again"
  run echo "$PATH"
  assert_output --regexp "/testing/from/bats"
  assert_output --regexp "/testing/again"
}