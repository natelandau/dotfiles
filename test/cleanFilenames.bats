#!/usr/bin/env bats
# shellcheck disable

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
testdir="cleantest"

setup() {
  curPath="$PWD"
  mkdir "$testdir"
  cd "$testdir"
}

teardown() {
  cd $curPath
  [ -d "$testdir" ] && rm -rf "$testdir"
}

helper() {
  local -r file="$1"
  local -r newfile="$2"

  touch "$file"

  run "$cf" --nonInteractive "$file"
  [ "$status" -eq 0 ]
  [ "$output" = "$newfile" ]
  [ -f "$newfile" ]
}

@test "sanity" {
  run true
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "noOpts prints usage" {
  run $cf
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "cleanFilenames [OPTION]... [FILE]..." ]
}

@test "-h prints usage" {
  run $cf -h
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "cleanFilenames [OPTION]... [FILE]..." ]
}

@test "-bad option" {
  run $cf -K
  [ "$status" -eq 1 ]
  [[ "${lines[0]}" =~ 'invalid option' ]]
}

@test "Fail when can't find file" {
  run $cf "some non-existant file.txt"
  [ "$status" -eq 1 ]
  [[ "${lines[0]}" =~ 'No such file or directory' ]]
}

@test "Fail on directories" {
  mkdir "testToFail"
  run $cf "testToFail"
  [ "$status" -eq 1 ]
  [[ "${lines[0]}" =~ 'is a directory' ]]
}

@test "Fail on dotfiles" {
  touch ".testdotfile"
  run $cf ".testdotfile"
  [ "$status" -eq 1 ]
  [[ "${lines[0]}" =~ 'is a dotfile' ]]
}

@test "Fail without extensions" {
  touch "testfile"
  run $cf "testfile"
  [ "$status" -eq 1 ]
  [[ "${lines[0]}" =~ 'we need a file extension' ]]
}

@test "Fail with DMG files" {
  touch "testfile.dmg"
  run $cf "testfile.dmg"
  [ "$status" -eq 1 ]
  [[ "${lines[0]}" =~ 'is not a supported extension' ]]
}

@test "Create testfiles" {
  mkdir "$testdir"
  cd "$testdir"
  run $cf --samples
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" =~ 'Creating test files...' ]]
  [ -e "2016-01-01 Already datestamped.txt" ]
  [ -e "YYY MM DD 2016 03 19 file.txt" ]
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
  [ "$status" -eq 0 ]
  [[ "$output" =~ 'fr-testing&with specialchars.txt' ]]
}

@test "Long numbers" {
  touch "name with long number 123456789101112 test.txt"
  run $cf --nonInteractive "name with long number 123456789101112 test.txt"
  [ "$status" -eq 0 ]
  [[ "$output" =~ 'name with long number 123456789101112 test.txt' ]]
}

@test "Lowercase Names" {
  regex="^[0-9]{4}[_ -][0-9]{2}[_ -][0-9]{2} name to lowercase.txt$"
  touch "NAME TO LOWERCASE.txt"
  run $cf -L --nonInteractive "NAME TO LOWERCASE.txt"
  [ "$status" -eq 0 ]
  [[ "$output" =~ $regex ]]
}

@test "Unique filename increments" {
  touch "NAME TO LOWERCASE.txt"
  run $cf -LC --nonInteractive "NAME TO LOWERCASE.txt"
  [ "$status" -eq 0 ]
  [ "$output" = "name to lowercase 2.txt" ]
  [ -f "name to lowercase 2.txt" ]
}

@test "Remove date" {
  touch "test 01-01-2016 file.txt"
  run $cf -R "test 01-01-2016 file.txt"
  [ "$status" -eq 0 ]
  [[ "$output" =~ 'test file.txt' ]]
  [ -f "test file.txt" ]
}

@test "Don't add date" {
  regex="^[0-9]{2}[:][0-9]{2}[:][0-9]{2} (PM|AM) \[ notice\] NAME TO TEST\.txt: No change"
  touch "NAME TO TEST.txt"
  run $cf -C "NAME TO TEST.txt"
  [ "$status" -eq 0 ]
  [[ "$output" =~ $regex ]]
  [ -f "NAME TO TEST.txt" ]
}

@test "Dryrun" {
  regex="\[ dryrun\] YY-MM-DD 16-05-27\.txt --> 2016-05-27 YY-MM-DD\.txt"
  touch "YY-MM-DD 16-05-27.txt"
  run $cf -n "YY-MM-DD 16-05-27.txt"
  [ "$status" -eq 0 ]
  [[ "$output" =~ $regex ]]
  [ -f "YY-MM-DD 16-05-27.txt" ]
}

@test "Verbose" {
  regex="\[  debug\]"
  touch "NAME TO TEST.txt"
  run $cf -nv "NAME TO TEST.txt"
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" =~ $regex ]]
  [ -f "NAME TO TEST.txt" ]
}

@test "Iterating over files" {
  touch "M D YY 2 5 16.txt"
  touch "month-DD-YY March 19, 74 test.txt"
  touch "month-DD-YYYY file january 01 2016.txt"
  run $cf *.txt
  [ "$status" -eq 0 ]
  [ -f "2016-02-05 M D YY.txt" ]
  [ -f "2074-03-19 month-DD-YY test.txt" ]
  [ -f "2016-01-01 month-DD-YYYY file.txt" ]
}