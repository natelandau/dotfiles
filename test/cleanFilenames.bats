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
fi


cf="$HOME/bin/cleanFilenames"


setup() {
  testdir="$(temp_make)"
  curPath="$PWD"

  BATSLIB_FILE_PATH_REM="#${TEST_TEMP_DIR}"
  BATSLIB_FILE_PATH_ADD='<temp>'

  cd "${testdir}"
}

teardown() {
  cd $curPath
  #[ -d "$testdir" ] && rm -rf "$testdir"
  temp_del "${testdir}"
}

helper() {
  local -r file="$1"
  local -r newfile="$2"
  touch "${file}"
  run "${cf}" --nonInteractive "${file}"

  assert_success
  assert_output "${newfile}"
  assert_file_exist "${newfile}"
}

######## run TESTS ##########

@test "sanity" {
  run true

  assert_success
  assert [ "$output" = "" ]
}

@test "noOpts prints usage" {
  run $cf

  assert_success
  assert_output --partial "cleanFilenames [OPTION]... [FILE]..."
}

@test "-h prints usage" {
  run $cf -h

  assert_success
  assert_output --partial "cleanFilenames [OPTION]... [FILE]..."
}

@test "bad option" {
  run "$cf" -K

  assert_failure
  assert_output --partial 'invalid option'
}

@test "Fail when can't find file" {
  run $cf "some non-existant file.txt"

  assert_failure
  assert_output --partial 'No such file or directory'
}

@test "Fail on directories" {
  mkdir "testToFail"
  run $cf "testToFail"

  assert_failure
  assert_output --partial 'is a directory'
}

@test "Fail on dotfiles" {
  touch ".testdotfile"
  run $cf ".testdotfile"

  assert_failure
  assert_output --partial 'is a dotfile'
}

@test "Fail without extensions" {
  touch "testfile"
  run $cf "testfile"

  assert_failure
  assert_output --partial 'we need a file extension'
}

@test "Fail with DMG files" {
  touch "testfile.dmg"
  run $cf "testfile.dmg"

  assert_failure
  assert_output --partial 'is not a supported extension'
}

@test "Already datestamped" {
  helper "2016-01-01 Already datestamped.txt" "2016-01-01 Already datestamped.txt"
}

@test "YYY MM DD" {
  helper "YYY MM DD 2016 03 19 file.txt" "2016-03-19 YYY MM DD file.txt"
}

@test "MM-DD-YYYY" {
  helper "MM-DD-YYYY 02 02 2016.txt" "2016-02-02 MM-DD-YYYY.txt"
}

@test "MMDDYYYY" {
  helper "MMDDYYYY 01202015 file.txt" "2015-01-20 MMDDYYYY file.txt"
}

@test "YYYYMMDD" {
  helper "YYYYMMDD 2013-08-21.txt" "2013-08-21 YYYYMMDD.txt"
}

@test "MMDDYY" {
  skip "not working today"
  helper "MMDDYY file 110216.txt" "2016-11-02 MMDDYY file.txt"
}

@test "YYMMDD" {
  skip "not working today"
  helper "YYMMDD 160228.txt" "2016-02-28 YYMMDD.txt"
}

@test "MM-DD-YY" {
  helper "MM-DD-YY 05-27-16 file.txt" "2016-05-27 MM-DD-YY file.txt"
}

@test "Special chars and date" {
  helper "filename (with special chars and date) 08312016.txt" "2016-08-31 filename with special chars and date.txt"
}

@test "YY-MM-DD" {
  helper "YY-MM-DD 16-05-27.txt" "2016-05-27 YY-MM-DD.txt"
}

@test "M DD YY 7 19 15 test" {
  helper "M DD YY 7 19 15 test.txt" "2015-07-19 M DD YY test.txt"
}

@test "M D YY" {
  helper "M D YY 2 5 16.txt" "2016-02-05 M D YY.txt"
}

@test "month-DD-YY" {
  helper "month-DD-YY March 19, 74 test.txt" "2074-03-19 month-DD-YY test.txt"
}

@test "month-DD-YYYY" {
  helper "month-DD-YYYY file january 01 2016.txt" "2016-01-01 month-DD-YYYY file.txt"
}

@test "Ambiguous date (##-##-##)" {
  helper "Ambiguous date 11-02-12.txt" "2012-11-02 Ambiguous date.txt"
}

@test "Special Chars" {
  touch "f*r_testing&with   special^chars_-___.txt"

  run $cf --nonInteractive "f*r_testing&with   special^chars_-___.txt"
  assert_success
  assert_output --partial 'fr-testing&with specialchars.txt'
}

@test "Long numbers" {
  touch "name with long number 123456789101112 test.txt"

  run $cf --nonInteractive "name with long number 123456789101112 test.txt"
  assert_success
  assert_output --partial 'name with long number 123456789101112 test.txt'
}

@test "Lowercase Names" {
  touch "NAME TO LOWERCASE.txt"
  run $cf -L --nonInteractive "NAME TO LOWERCASE.txt"

  assert_success
  assert_output --regexp '^[0-9]{4}[_ -][0-9]{2}[_ -][0-9]{2} name to lowercase.txt$'
}

@test "Unique filename increments" {
  touch "NAME TO LOWERCASE.txt"
  run $cf -LC --nonInteractive "NAME TO LOWERCASE.txt"

  assert_success
  assert_output "name to lowercase 2.txt"
  assert_file_exist 'name to lowercase 2.txt'
}

@test "Remove date" {
  touch "test 01-01-2016 file.txt"
  run $cf -R "test 01-01-2016 file.txt"

  assert_success
  assert_output --partial 'test 01-01-2016 file.txt --> test file.txt'
  assert_file_exist "test file.txt"
}

@test "Files in Different Directories" {
  touch "${testdir}/M D YY 2 5 16.txt"
  run $cf "${testdir}/M D YY 2 5 16.txt"

  assert_success
  assert_output --regexp '\[success\] M D YY 2 5 16\.txt --> 2016-02-05 M D YY\.txt'
  assert_file_exist "${testdir}/2016-02-05 M D YY.txt"
}

@test "Don't add date" {
  touch "NAME TO TEST.txt"
  run $cf -C "NAME TO TEST.txt"

  assert_success
  assert_output --regexp '^[0-9]{2}[:][0-9]{2}[:][0-9]{2} (PM|AM) \[ notice\] NAME TO TEST\.txt: No change'
  assert_file_exist 'NAME TO TEST.txt'
}

@test "Dryrun" {
  touch "YY-MM-DD 16-05-27.txt"
  run $cf -n "YY-MM-DD 16-05-27.txt"

  assert_success
  assert_output --regexp '\[ dryrun\] YY-MM-DD 16-05-27\.txt --> 2016-05-27 YY-MM-DD\.txt'
  assert_file_exist 'YY-MM-DD 16-05-27.txt'
}

@test "Verbose" {
  touch "NAME TO TEST.txt"
  run $cf -nv "NAME TO TEST.txt"

  assert_success
  assert_output --regexp '\[  debug\]'
  assert_file_exist 'NAME TO TEST.txt'
}

@test "Quiet mode" {
  touch "M D YY 2 5 16.txt"
  run $cf -qv "M D YY 2 5 16.txt"

  assert_success
  refute_output --regexp '\[  debug\]|\[ dryrun\]|\[success\]|\[  error\]'
  assert_file_exist '2016-02-05 M D YY.txt'
}

@test "Iterating over files" {
  touch "M D YY 2 5 16.txt"
  touch "month-DD-YY March 19, 74 test.txt"
  touch "month-DD-YYYY file january 01 2016.txt"
  run $cf *.txt

  assert_success
  assert_file_exist '2016-02-05 M D YY.txt'
  assert_file_exist '2074-03-19 month-DD-YY test.txt'
  assert_file_exist '2016-01-01 month-DD-YYYY file.txt'
}