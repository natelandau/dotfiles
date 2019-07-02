#!/usr/bin/env bats
#shellcheck disable

load 'helpers/bats-support/load'
load 'helpers/bats-file/load'
load 'helpers/bats-assert/load'

s="${HOME}/dotfiles/scripting/helpers/files.bash"
base="$(basename $s)"

source "${HOME}/dotfiles/scripting/helpers/baseHelpers.bash"

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
  debug=false;              sourceOnly=false;           logErrors=false;  args=();

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
  #source "${home}/dotfiles/scripting/baseHelpers.bash"
  mkdir backup
  touch "testfile" "backup/testfile"
  run _backupFile_ "testfile"

  assert_success
  assert [ -f "backup/testfile-2" ]
}

@test "_cleanFilename_: no rename file" {
  touch "test.txt"

  run _cleanFilename_ "test.txt"
  assert_output --partial "test.txt"
  assert_file_exist "test.txt"
}

@test "_cleanFilename_: rename file" {
  touch "test&.txt"

  run _cleanFilename_ "test&.txt"
  assert_output --partial "test.txt"
  assert_file_exist "test.txt"
}

@test "_cleanFilename_: duplicate file" {
  touch "test&.txt"
  touch "test.txt"

  run _cleanFilename_ "test&.txt"
  assert_output --partial "test-2.txt"
  assert_file_exist "test-2.txt"
}

@test "_cleanFilename_: User input" {
  touch "testing_a_new_file.txt"

  run _cleanFilename_ "testing_a_new_file.txt" "y,e,_"

  assert_success
  assert_output --partial "tstinganwfil.txt"
  assert_file_exist "tstinganwfil.txt"
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

@test "_json2yaml_" { skip "seems to be a problem with pyyaml"
  run _json2yaml_ "$JSON"
  assert_success
  assert_output "$( cat "$YAML2")"
}

@test "_listFiles: glob w/ 2 files" {
  touch test1.txt test2.txt test3.json

  run _listFiles_ g "*.txt"
  assert_success
  assert_line --index 0 --partial 'test1.txt'
  assert_line --index 1 --partial 'test2.txt'
  refute_output --partial 'json'
}

@test "_listFiles: regex w/ 1 file" {
  touch test1.txt test2.txt test3.json

  run _listFiles_ r ".*\.json"
  assert_success
  assert_line --index 0 --partial 'test3.json'
  refute_output --partial 'txt'
}

@test "_listFiles: fail no args" {
  run _listFiles_
  assert_failure
}

@test "_listFiles: fail one arg" {
  run _listFiles_ "g"
  assert_failure
}

@test "_locateSourceFile_: Resolve symlinks" {
  ln -s "$YAML1" "testSymlink"

  run _locateSourceFile_ "testSymlink"
  assert_output "$YAML1"
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

@test "_parseFilename_: success" {
  verbose=true
  touch "${testdir}/testfile.txt"
  run _parseFilename_ "${testdir}/testfile.txt"
  assert_success
  assert_line --index 0 --regexp '\$_parsedFileFull: /private/.*/testfile\.txt'
  assert_line --index 1 --regexp '\$_parseFilePath: /private/.*files.bash:[0-9]{2,3}'
  assert_line --index 2 --partial '$_parseFileName: testfile.txt'
  assert_line --index 3 --partial '$_parseFileBase: testfile'
  assert_line --index 4 --partial '$_parseFileExt: .txt'

  verbose=false
}

@test "_parseFilename_: fail - no arguments" {
  run _parseFilename_
  assert_failure
}

@test "_parseFilename_: fail - can't find file" {
  run _parseFilename_ "a-new-file-to-test.txt"
  assert_failure
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

@test "_realpath_ -d: true" {
  touch testfile.txt
  run _realpath_ -d "testfile.txt"
  assert_success
  refute_output --regexp "^/private/var/folders/.*/testfile.txt$"
  assert_output --regexp "^/private/var/folders/.*"
}

@test "_realpath_: fail" {
  run _realpath_ "testfile.txt"
  assert_failure
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

@test "_yaml2json_" {skip "seems to be a problem with pyyaml"
  run _yaml2json_ "$YAML2"
  assert_success
  assert_output "$( cat "$JSON")"
}