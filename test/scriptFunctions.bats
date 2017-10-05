#!/usr/bin/env bats
#shellcheck disable

load 'helpers/bats-support/load'
load 'helpers/bats-file/load'
load 'helpers/bats-assert/load'

sourceDIR="${HOME}/dotfiles/scripting/functions"

[ -d "$sourceDIR" ] || exit 1

while read -r sourcefile; do
  [ -f "$sourcefile" ] && source "$sourcefile"
done < <(find "$sourceDIR" -name "*.bash" -type f -maxdepth 1)

# Fixtures
YAML1="${BATS_TEST_DIRNAME}/fixtures/yaml1.yaml"
YAML1parse="${BATS_TEST_DIRNAME}/fixtures/yaml1.yaml.txt"
YAML2="${BATS_TEST_DIRNAME}/fixtures/yaml2.yaml"
JSON="${BATS_TEST_DIRNAME}/fixtures/json.json"
unencrypted="${BATS_TEST_DIRNAME}/fixtures/test.md"
encrypted="${BATS_TEST_DIRNAME}/fixtures/test.md.enc"

# Set Defaults
force=false;    dryrun=false;    verbose=false;    quiet=false;
printLog=false; debug=false;

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

############## Begin Tests ###############

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

@test "_cleanFilename_: no rename file" {
  touch "test.txt"

  _cleanFilename_ "test.txt"
  assert_file_exist "test.txt"
}

@test "_cleanFilename_: rename file" {
  touch "test&.txt"

  _cleanFilename_ "test&.txt"
  assert_file_exist "test.txt"
}

@test "_cleanFilename_: rename file" {
  touch "test&.txt"

  _cleanFilename_ "test&.txt"
  assert_file_exist "test.txt"
}

@test "_convertSecs_: Seconds to human readable" {

  run _convertSecs_ "9255"
  assert_success
  assert_output "02:34:15"
}

@test "_countdown_" {
  run _countdown_ 10 0 "something"
  assert_line --index 0 --partial "[   info] something 10"
  assert_line --index 9 --partial "[   info] something 1"
}

@test "_decryptFile_" {
  PASS=123
  run _decryptFile_ "${encrypted}" "test-decrypted.md"
  assert_success
  assert_file_exist "test-decrypted.md"
  run cat "test-decrypted.md"
  assert_success
  assert_output "$( cat "$unencrypted")"
}

@test "_encryptFile_" {
  PASS=123
  run _encryptFile_ "${unencrypted}" "test-encrypted.md.enc"
  assert_success
  assert_file_exist "test-encrypted.md.enc"
  run cat "test-encrypted.md.enc"
  assert_line --index 0 --partial "Salted__"
  unset PASS
}

@test "_escape_" {
  run _escape_ "Here is some / text to & be - escape'd"
  assert_success
  assert_output "Here\ is\ some\ /\ text\ to\ &\ be\ -\ escape'd"
}

@test "_ext_: .txt" {
  touch "foo.txt"

  run _ext_ foo.txt
  assert_success
  assert_output ".txt"
}

@test "_ext_: tar.gz" {
  touch "foo.tar.gz"

  run _ext_ foo.tar.gz
  assert_success
  assert_output ".tar.gz"
}

@test "_ext_: -n1" {
  touch "foo.tar.gz"

  run _ext_ -n1 foo.tar.gz
  assert_success
  assert_output ".gz"
}

@test "_ext_: -n2" {
  touch "foo.txt.gz"

  run _ext_ -n2 foo.txt.gz
  assert_success
  assert_output ".txt.gz"
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
  assert_success
  assert_output --partial "[  error] rm nonexistant.txt"
  assert_file_exist "testfile.txt"
}

@test "_execute_: Good command" {
  touch "testfile.txt"
  run _execute_ "rm testfile.txt"
  assert_success
  assert_output --partial "[success] rm testfile.txt"
  assert_file_not_exist "testfile.txt"
}

@test "_findBaseDir_" {
  run _findBaseDir_
  assert_output "${HOME}/dotfiles/scripting/functions"
}

@test "_haveFunction_: Success" {
  run _haveFunction_ "_haveFunction_"

  assert_success
}

@test "_haveFunction_: Failure" {
  run _haveFunction_ "_someUndefinedFunction_"

  assert_failure
}

@test "_httpStatus_: Bad URL" {
  run _httpStatus_ http://thereisabadurlishere.com 1
  assert_success
  assert_line --index 1 "000 Not responding within 1 seconds"
}

@test "_httpStatus_: redirect" {skip "not working yet...."
  run _httpStatus_ https://jigsaw.w3.org/HTTP/300/301.html 3 --status -L
  assert_success
  assert_output --partial "000 Not responding within 3 seconds"
}

@test "_httpStatus_: google.com" {skip
  run _httpStatus_ google.com
  assert_success
  assert_output --partial "200 Successful:"
}

@test "_httpStatus_: -c" {skip
  run _httpStatus_ https://natelandau.com/something/not/here/ 3 -c
  assert_success
  assert_output "404"
}

@test "_httpStatus_: --code" {skip
  run _httpStatus_ www.google.com 3 --code
  assert_success
  assert_output "200"
}

@test "_httpStatus_: -s" {skip
  run _httpStatus_ www.google.com 3 -s
  assert_success
  assert_output "200 Successful: OK within 3 seconds"
}

@test "_httpStatus_: --status" {skip
  run _httpStatus_ www.google.com 3 -s
  assert_success
  assert_output "200 Successful: OK within 3 seconds"
}

@test "_htmlEncode_" {
  run _htmlEncode_ "Here's some text& to > be h?t/M(l• en™codeç£§¶d"
  assert_success
  assert_output "Here's some text&amp; to &gt; be h?t/M(l&bull; en&trade;code&ccedil;&pound;&sect;&para;d"
}

@test "_htmlDecode_" {
  run _htmlDecode_ "&clubs;Here's some text &amp; to &gt; be h?t/M(l&bull; en&trade;code&ccedil;&pound;&sect;&para;d"
  assert_success
  assert_output "♣Here's some text & to > be h?t/M(l• en™codeç£§¶d"
}

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

@test "_json2yaml_" { skip "seems to be a problem with pyyaml"
  run _json2yaml_ "$JSON"
  assert_success
  assert_output "$( cat "$YAML2")"
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

@test "_urlEncode_" {
  run _urlEncode_ "Here's some.text%that&needs_to-be~encoded+a*few@more(characters)"
  assert_success
  assert_output "Here%27s%20some.text%25that%26needs_to-be~encoded%2Ba%2Afew%40more%28characters%29"
}

@test "_urlDecode_" {
  run _urlDecode_ "Here%27s%20some.text%25that%26needs_to-be~encoded%2Ba%2Afew%40more%28characters%29"
  assert_success
  assert_output "Here's some.text%that&needs_to-be~encoded+a*few@more(characters)"
}

@test "_yaml2json_" {skip "seems to be a problem with pyyaml"
  run _yaml2json_ "$YAML2"
  assert_success
  assert_output "$( cat "$JSON")"
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
  assert_line --index 0 --partial "[  error] testing Exiting."
  assert_line --index 1 --partial "_safeExit_: command not found"
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