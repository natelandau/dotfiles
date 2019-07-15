#!/usr/bin/env bats
# shellcheck disable

load 'helpers/bats-support/load'
load 'helpers/bats-file/load'
load 'helpers/bats-assert/load'

_setPATH_() {
  # setPATH() Add homebrew and ~/bin to $PATH so the script can find executables
  PATHS=(/usr/local/bin $HOME/bin);
  for newPath in "${PATHS[@]}"; do
    if ! echo "$PATH" | grep -Eq "(^|:)${newPath}($|:)" ; then
      PATH="$newPath:$PATH"
   fi
 done
}
_setPATH_

if ! command -v $HOME/bin/cleanFilenames &>/dev/null; then
    printf "No executable 'cleanFilenames' found.\n" >&2
    printf "Can not run tests.\n" >&2
    exit 1
else
    s="${HOME}/bin/cleanFilenames"
    base="$(basename "$s")"
fi

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

helper() {
  local -r file="$1"
  local -r newfile="$2"
  touch "${file}"
  run "$s" --nonInteractive "${file}"

  assert_success
  assert_line --regexp "^/private/var/folders/.*/${newfile}$"
  assert_file_exist "${newfile}"
}

######## RUN TESTS ##########

@test "sanity" {
  run true
  assert_success
  assert [ "$output" = "" ]
}

@test "Fail - no file specified" {
  run "$s" -vT
  assert_failure
  assert_output --partial "[  error] No file specified"
}

@test "Fail - bad args" {
  run "$s" -eK
  assert_failure
  assert_output --partial "[  fatal] invalid option: '-K'"
}

@test "Fail - nonexistant file" {
  run "$s" "nonexistant-file.txt"
  assert_failure
  assert_output --partial "No such file"
}

@test "Fail - not a file" {
  mkdir "testdir"
  run "$s" "testdir"
  assert_failure
  assert_output --partial "'testdir' is not a file"
}

@test "Fail - dotfiles" {
  touch ".dotfile.txt"
  run "$s" ".dotfile.txt"
  assert_failure
  assert_output --partial "is a dotfile"
}

@test "Fail - user specified file extensions" {
  touch "file.dmg"
  touch "file.download"
  run "$s" "file.dmg"
  assert_failure
  assert_output --partial "'.dmg' is not a supported extension"
  run "$s" "file.download"
  assert_failure
  assert_output --partial "'.download' is not a supported extension"

}

@test "Fail - continue parsing files if one fails" {
  touch "file.dmg"
  touch "file.txt"
  run "$s" "file.dmg" "file.txt"
  assert_success
  assert_output --partial "[  error] '.dmg' is not a supported extension"
  assert_output --partial "[success] file.txt -->"
}

@test "Usage (no args)" {
  run "$s"

  assert_success
  assert_line --index 0 "  $base [OPTION]... [FILE]..."
}

@test "usage (-h)" {
  run $s -h

  assert_success
  assert_line --index 0 "  $base [OPTION]... [FILE]..."
}

@test "usage (--help)" {
  run $s --help

  assert_success
  assert_line --index 0 "  $base [OPTION]... [FILE]..."
}

@test "Test mode (-T)" {
  run "$s" -T "newfile.txt"
  assert_success
  assert_line --index 0 --partial "[ notice] Running in test mode."
  assert_line --index 1 --regexp "newfile\.txt --> [0-9]{4}-[0-9]{2}-[0-9]{2} newfile\.txt"
}

@test "Test mode (--test)" { # if this test dails, it is likely the line index numbers
  run "$s" -v --test "newfile.txt"
  assert_success
  assert_line --index 2 --partial "[ notice] Running in test mode."
  assert_line --index 4 --partial "Created test file"
  assert_line --index 18 --regexp "newfile\.txt --> [0-9]{4}-[0-9]{2}-[0-9]{2} newfile\.txt"
}

@test "Remove brackets" {
  touch "new[file].txt"
  run "$s" "new[file].txt"
  assert_success
  assert_line --index 0 --partial "[ notice] Filename contains restricted special characters"
  assert_line --index 2 --regexp "newfile\.txt --> [0-9]{4}-[0-9]{2}-[0-9]{2} newfile\.txt"
}

@test "Clean only (-C): No Change" {
  touch "newfile.txt"
  run "$s" -C "newfile.txt"
  assert_success
  assert_output --partial "[ notice] newfile.txt: No change"
}

@test "Clean only (--clean): lowercase no other cleaning" {
  touch "NEWFILE.txt"
  run "$s" -L --clean "NEWFILE.txt"
  assert_success
  assert_output --partial "[success] NEWFILE.txt --> newfile.txt"
}

@test "Clean only (--clean): lowercase and clean" {
  touch "NEWFILE---two.txt"
  run "$s" -L --clean "NEWFILE---two.txt"
  assert_success
  assert_output --partial "[success] NEWFILE---two.txt --> newfile-two.txt"
}

@test "--nonInteractive" {
  touch "2016-01-01 already datestamped.txt"
  run $s -LC --nonInteractive "2016-01-01 already datestamped.txt"

  assert_success
  assert_line --regexp "^/private/var/folders/.*/2016-01-01 already datestamped.txt$"
  assert_file_exist "2016-01-01 already datestamped.txt"
}

@test "Use Dashes (-D)" {
  touch "2019-06-01 this is a test file.txt"
  run "$s" -D "2019-06-01 this is a test file.txt"
  assert_success
  assert_output --partial "[success] 2019-06-01 this is a test file.txt --> 2019-06-01-this-is-a-test-file.txt"
  assert_file_exist "2019-06-01-this-is-a-test-file.txt"
}

@test "Use Dashes (--useDashes)" {
  touch "this is a test file.txt"
  run "$s" -C --useDashes "this is a test file.txt"
  assert_success
  assert_output --partial "[success] this is a test file.txt --> this-is-a-test-file.txt"
  assert_file_exist "this-is-a-test-file.txt"
}

@test "Remove stopwords (-S)" {
  touch "this is a test file.txt"
  run "$s" -CS "this is a test file.txt"
  assert_success
  assert_output --partial "[success] this is a test file.txt --> file.txt"
  assert_file_exist "file.txt"
}

@test "Remove stopwords (--stopwords)" {
  touch "2019-06-01 this is a test file.txt"
  run "$s" -S "2019-06-01 this is a test file.txt"
  assert_success
  assert_output --partial "[success] 2019-06-01 this is a test file.txt --> 2019-06-01 file.txt"
  assert_file_exist "2019-06-01 file.txt"
}

@test "Remove date (--removeDate)" {
  touch "test 01-01-2016 file.txt"
  run $s --removeDate "test 01-01-2016 file.txt"

  assert_success
  assert_output --partial 'test 01-01-2016 file.txt --> test file.txt'
  assert_file_exist "test file.txt"
}

@test "Remove date (-R)" {
  touch "test 01-01-2016 file.txt"
  run $s -R "test 01-01-2016 file.txt"

  assert_success
  assert_output --partial 'test 01-01-2016 file.txt --> test file.txt'
  assert_file_exist "test file.txt"
}

@test "Dryrun (-n)" {
  touch "YYYY-MM-DD 2016-05-27.txt"
  run $s -n "YYYY-MM-DD 2016-05-27.txt"

  assert_success
  assert_output --partial "[ dryrun] command mv"
  assert_file_exist 'YYYY-MM-DD 2016-05-27.txt'
}

@test "Dryrun (--dryrun)" {
  touch "YYYY-MM-DD 2016-05-27.txt"
  run $s --dryrun "YYYY-MM-DD 2016-05-27.txt"

  assert_success
  assert_output --partial "[ dryrun] command mv"
  assert_file_exist 'YYYY-MM-DD 2016-05-27.txt'
}

@test "Verbose (-v)" {
  touch "NAME TO TEST.txt"
  run $s -nv "NAME TO TEST.txt"

  assert_success
  assert_output --regexp '\[  debug\]'
  assert_file_exist 'NAME TO TEST.txt'
}

@test "Verbose (--verbose)" {
  touch "NAME TO TEST.txt"
  run $s -n --verbose "NAME TO TEST.txt"

  assert_success
  assert_output --regexp '\[  debug\]'
  assert_file_exist 'NAME TO TEST.txt'
}

@test "Quiet mode (-q)" {
  touch "month-DD-YY March 19, 74 test.txt"
  run $s -qv "month-DD-YY March 19, 74 test.txt"

  assert_success
  refute_output --regexp 'debug|success|fatal|error|warning|info|notice|dryrun'
  assert_file_exist '2074-03-19 month-DD-YY test.txt'
}

@test "Quiet mode (--quiet)" {
  touch "month-DD-YY March 19, 74 test.txt"
  run $s -v --quiet "month-DD-YY March 19, 74 test.txt"

  assert_success
  refute_output --regexp 'debug|success|fatal|error|warning|info|notice|dryrun'
  assert_file_exist '2074-03-19 month-DD-YY test.txt'
}

@test "No change" {
  helper "2016-01-01 already datestamped.txt" "2016-01-01 already datestamped.txt"
}

@test "YYYY-MM-DD 1" {
  helper "YYYY-MM-DD 2019-06-22.txt" "2019-06-22 YYYY-MM-DD.txt"
}

@test "YYYY-MM-DD 2" {
  helper "YYYY MM DD 2016 03 19 file.txt" "2016-03-19 YYYY MM DD file.txt"
}

@test "YYYY-MM-DD 3" {
  helper "YYYY MM DD 2016.03.19 file.txt" "2016-03-19 YYYY MM DD file.txt"
}

@test "MM-DD-YYYY 1" {
  helper "MM-DD-YYYY 02-02-2016.txt" "2016-02-02 MM-DD-YYYY.txt"
}

@test "MM-DD-YYYY 2" {
  helper "MM-DD-YYYY 02 22 2016.txt" "2016-02-22 MM-DD-YYYY.txt"
}

@test "DD-MM-YYYY" {
  helper "DD-MM-YYYY 22 02 2016.txt" "2016-02-22 DD-MM-YYYY.txt"
}

@test "DD-MM-YY" {
  helper "DD-MM-YYYY 23 02 2016.txt" "2016-02-23 DD-MM-YYYY.txt"
}

@test "MM-DD-YY 1" {
  helper "DD-MM-YYYY2 22 2016.txt" "2016-02-22 DD-MM-YYYY.txt"
}

@test "MM-DD-YY 2" {
  helper "DD-MM-YYYY 02 02 2016.txt" "2016-02-02 DD-MM-YYYY.txt"
}

@test "Month DD, YYYY" {
  helper "somefile January 12, 2016.txt" "2016-01-12 somefile.txt"
}

@test "Month DD YYYY" {
  helper "month-DD-YYYY file january 01 2016.txt" "2016-01-01 month-DD-YYYY file.txt"
}

@test "Month DD, YY" {
  helper "month-DD-YY March 19, 19 test.txt" "2019-03-19 month-DD-YY test.txt"
}

@test "Month, YYYY" {
  helper "somefile mar, 2016.txt" "2016-03-01 somefile.txt"
}

@test "DD Month, YYYY" {
  helper "somefile 16 mar, 2016.txt" "2016-03-16 somefile.txt"
}

@test "MMDDYYYY" {
  helper "MMDDYYYY 01202015 file.txt" "2015-01-20 MMDDYYYY file.txt"
}

@test "YYYYMMDD" {
  helper "YYYYMMDD 20130821.txt" "2013-08-21 YYYYMMDD.txt"
}

@test "YYYYDDMM" {
  helper "YYYYDDMM 20132208.txt" "2013-08-22 YYYYDDMM.txt"
}

@test "YYYYMMDDHHMM" {
  helper "YYYYMMDD 201308210922.txt" "2013-08-21 YYYYMMDD.txt"
}

@test "YYYYMMDDHH" {
  helper "YYYYMMDD 2013082109.txt" "2013-08-21 YYYYMMDD.txt"
}

@test "Special chars and date" {
  helper "filename (with special chars and date) 08312016.txt" "2016-08-31 filename with special chars and date.txt"
}

@test "ignore: Long numbers" {
  touch "name with long number 123456789101112 test.txt"

  run "$s" --nonInteractive "name with long number 123456789101112 test.txt"
  assert_success
  assert_output --partial 'name with long number 123456789101112 test.txt'
}

@test "Ambiguous date (##-##-##)" {skip "not implemented in dates.bash"
  helper "Ambiguous date 11-02-12.txt" "2012-11-02 Ambiguous date.txt"
}

@test "Unique filename increments" {
  touch "2019-12-22 somefile.txt"
  helper "somefile 2019-12-22.txt" "2019-12-22 somefile-2.txt"
}

@test "Files in different directories" {
  mkdir "testtest"
  touch "testtest/somefile 2019-12-22.txt"
  run "$s" "testtest/somefile 2019-12-22.txt"

  assert_success
  assert_output --regexp '\[success\] somefile 2019-12-22\.txt --> 2019-12-22 somefile\.txt'
  assert_file_exist "testtest/2019-12-22 somefile.txt"
}

@test "Iterating over files" {
  touch "2019-12-22 somefile.txt"
  touch "month-DD-YY March 19, 74 test.txt"
  touch "month-DD-YYYY file january 01 2016.txt"
  run "$s" *.txt

  assert_success
  assert_file_exist '2019-12-22 somefile.txt'
  assert_file_exist '2074-03-19 month-DD-YY test.txt'
  assert_file_exist '2016-01-01 month-DD-YYYY file.txt'
}