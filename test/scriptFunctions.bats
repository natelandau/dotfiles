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

@test "_inArray_: Test if value is in array" {
  run _inArray_ one "${A[@]}"
  assert_success

  run _inArray_ ten "${A[@]}"
  assert_failure
}

@test "_join_: Joins arrays or input" {
  run _join_ , "${B[@]}"
  assert_output "1,2,3,4,5,6"

  run _join_ " " "${B[@]}"
  assert_output "1 2 3 4 5 6"

  run _join_ , a "b c" d
  assert_output "a,b c,d"

  run _join_ / var usr tmp
  assert_output "var/usr/tmp"
}

@test "_setdiff_: Print elements not common to arrays" {
  run _setdiff_ "${A[*]}" "${B[*]}"
  assert_output "one two three"

  run _setdiff_ "${B[*]}" "${A[*]}"
  assert_output "4 5 6"
}


@test "_ext_: Find extensions" {
  touch "foo.txt"
  touch "foo.tar.gz"

  run _ext_ foo.txt
  assert_output ".txt"

  run _ext_ -n2 foo.tar.gz
  assert_output ".tar.gz"

  run _ext_ foo.tar.gz
  assert_output ".tar.gz"

  run _ext_ -n1 foo.tar.gz
  assert_output ".gz"
}

@test "_locateSourceFile_: Resolve symlinks" {
  ln -s "$sourceDIR" "testSymlink"

  run _locateSourceFile_ "testSymlink"
  assert_output "$sourceDIR"
}

@test "_uniqueFileName_: Mimic finder naming" {
  touch "test.txt"
  touch "test 2.txt"

  run _uniqueFileName_ "test.txt"
  assert_output "test 3.txt"

  run _uniqueFileName_ "test 2.txt"
  assert_output "test 2 2.txt"

  run _uniqueFileName_ "test.txt" "-"
  assert_output "test-2.txt"
}

@test "_readFile_: Reads files line by line" {
cat >testfile.txt <<EOL
line 1
line 2
line 3
EOL

  run _readFile_ "testfile.txt"
  assert_line --index 0 'line 1'
  assert_line --index 2 'line 3'
}