#!/usr/bin/env bats
#shellcheck disable

load 'helpers/bats-support/load'
load 'helpers/bats-file/load'
load 'helpers/bats-assert/load'

rootDir="$(git rev-parse --show-toplevel)"
[[ "${rootDir}" =~ private ]] && rootDir="${HOME}/dotfiles"
s="${rootDir}/bin/convertVideo"
base="$(basename $s)"

[ -f "$s" ] \
  && { source "$s" --source-only ; trap - EXIT INT TERM ; } \
  || { echo "Can not find script to test" >&2 ; exit 1 ; }

# Fixtures
v720="${BATS_TEST_DIRNAME}/fixtures/video720psample.mp4"
vmkv="${BATS_TEST_DIRNAME}/fixtures/videoMKVsample.mkv"
vwmv="${BATS_TEST_DIRNAME}/fixtures/videoWmvPALSample.wmv"

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
  assert [ "$output" = "" ]
}

@test "convert: copy streams" {
  cp "$vmkv" "videoMKVsample.mkv"
  run $s -n "videoMKVsample.mkv"

  assert_success
  assert_line --index 2 --regexp "\[ dryrun\] caffeinate -ism ffmpeg -i \".*/videoMKVsample.mkv\"  -c:v libx264 -crf 18 -preset slow -c:a copy \".*/videoMKVsample.mp4\""
}

@test "convert: Don't convert if the same" {
  cp "$v720" "video720psample.mp4"
  run $s -n --force --size 720 "video720psample.mp4"

  assert_success
  assert_line --index 2 --regexp "\[   info\] File already 720p. Will not resize to self."
}

@test "convert: --size hd720" {
  cp "$vwmv" "videoWmvPALSample.wmv"
  run $s -n --force --size hd720 "videoWmvPALSample.wmv"

  assert_success
  assert_line --index 2 --regexp "\[ dryrun\] caffeinate -ism ffmpeg -i \".*/videoWmvPALSample.wmv\" -vf scale=1280:-1 -c:v libx264 -crf 18 -preset slow -c:a libfdk_aac -b:a 125k \".*/videoWmvPALSample.mp4\""
}

@test "convert: --size 4k" {
  cp "$vwmv" "videoWmvPALSample.wmv"
  run $s -n --force --size 4k "videoWmvPALSample.wmv"

  assert_success
  assert_line --index 2 --regexp "\[ dryrun\] caffeinate -ism ffmpeg -i \".*/videoWmvPALSample.wmv\" -vf scale=4096:-1 -c:v libx264 -crf 18 -preset slow -c:a libfdk_aac -b:a 125k \".*/videoWmvPALSample.mp4\""
}

@test "convert: --size 2k" {
  cp "$vwmv" "videoWmvPALSample.wmv"
  run $s -n --force --size 2k "videoWmvPALSample.wmv"

  assert_success
  assert_line --index 2 --regexp "\[ dryrun\] caffeinate -ism ffmpeg -i \".*/videoWmvPALSample.wmv\" -vf scale=2048:-1 -c:v libx264 -crf 18 -preset slow -c:a libfdk_aac -b:a 125k \".*/videoWmvPALSample.mp4\""
}

@test "convert: --size hd1080" {
  cp "$vwmv" "videoWmvPALSample.wmv"
  run $s -n --force --size hd1080 "videoWmvPALSample.wmv"

  assert_success
  assert_line --index 2 --regexp "\[ dryrun\] caffeinate -ism ffmpeg -i \".*/videoWmvPALSample.wmv\" -vf scale=1920:-1 -c:v libx264 -crf 18 -preset slow -c:a libfdk_aac -b:a 125k \".*/videoWmvPALSample.mp4\""
}

@test "convert: --size 1920x1080" {
  cp "$vwmv" "videoWmvPALSample.wmv"
  run $s -n --force --size 1820x1000 "videoWmvPALSample.wmv"

  assert_success
  assert_line --index 2 --regexp "\[ dryrun\] caffeinate -ism ffmpeg -i \".*/videoWmvPALSample.wmv\" -vf scale=1820:-1 -c:v libx264 -crf 18 -preset slow -c:a libfdk_aac -b:a 125k \".*/videoWmvPALSample.mp4\""
}

@test "convert: --output" {
  cp "$vwmv" "videoWmvPALSample.wmv"
  run $s -n --output mkv "videoWmvPALSample.wmv"

  assert_success
  assert_line --index 1 --regexp "\[ dryrun\] caffeinate -ism ffmpeg -i \".*/videoWmvPALSample.wmv\"  -c:v libx264 -crf 18 -preset slow -c:a libfdk_aac -b:a 125k \".*/videoWmvPALSample.mkv\""
}

@test "convert: -o" {
  cp "$vwmv" "videoWmvPALSample.wmv"
  run $s -n -o mkv "videoWmvPALSample.wmv"

  assert_success
  assert_line --index 1 --regexp "\[ dryrun\] caffeinate -ism ffmpeg -i \".*/videoWmvPALSample.wmv\"  -c:v libx264 -crf 18 -preset slow -c:a libfdk_aac -b:a 125k \".*/videoWmvPALSample.mkv\""
}

@test "convert: --delete" {
  cp "$vwmv" "videoWmvPALSample.wmv"
  run $s --delete -o mp4 "videoWmvPALSample.wmv"

  assert_success
  assert_file_exist "videoWmvPALSample.mp4"
  assert_file_not_exist "videoWmvPALSample.wmv"
}

@test "convert: no specified output" {
  cp "$vwmv" "videoWmvPALSample.wmv"
  run $s --dryrun "videoWmvPALSample.wmv"

  assert_success
  assert_line --index 0 --regexp "\[ notice\] No output format specified. Defaulting to 'mp4'"
}

@test "convert: -n" {
  cp "$vwmv" "videoWmvPALSample.wmv"
  run $s -n "videoWmvPALSample.wmv"

  assert_success
  assert_line --index 2 --regexp "\[ dryrun\] caffeinate -ism ffmpeg -i \".*/videoWmvPALSample.wmv\"  -c:v libx264 -crf 18 -preset slow -c:a libfdk_aac -b:a 125k \".*/videoWmvPALSample.mp4\""
}

@test "convert: --dryrun" {
  cp "$vwmv" "videoWmvPALSample.wmv"
  run $s --dryrun "videoWmvPALSample.wmv"

  assert_success
  assert_line --index 2 --regexp "\[ dryrun\] caffeinate -ism ffmpeg -i \".*/videoWmvPALSample.wmv\"  -c:v libx264 -crf 18 -preset slow -c:a libfdk_aac -b:a 125k \".*/videoWmvPALSample.mp4\""
}

@test "convert: no specified output" {
  cp "$vwmv" "videoWmvPALSample.wmv"
  run $s --dryrun "videoWmvPALSample.wmv"

  assert_success
  assert_line --index 0 --regexp "\[ notice\] No output format specified. Defaulting to 'mp4'"
}

@test "--probe" {
  run $s --probe $v720

  assert_success
  assert_line --index 4 "    \"streams\": ["
}

@test "Fail without video files" {
  run $s somevideofile.mkv

  assert_failure
  assert_output --partial "[  error] Please specify at least one video file. Exiting."
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

@test "Usage (no args)" {
  run $s

  assert_success
  assert_line --index 0 "$base [OPTION]... [FILE]..."
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

@test "_uniqueFileName_: Count to 3" {
  skip
  touch "test.txt"
  touch "test 2.txt"

  run _uniqueFileName_ "test.txt"
  assert_output "test 3.txt"
}

@test "_uniqueFileName_: Don't confuse existing numbers" {
  skip
  touch "test 2.txt"

  run _uniqueFileName_ "test 2.txt"
  assert_output "test 2 2.txt"
}

@test "_uniqueFileName_: User specified separator" {
  skip
  touch "test.txt"

  run _uniqueFileName_ "test.txt" "-"
  assert_output "test-2.txt"
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

@test "_execute_: Debug command" {
  dryrun=true
  run _execute_ "rm testfile.txt"
  assert_success
  assert_output --partial "[ dryrun] rm testfile.txt"
  dryrun=false
}

@test "_execute_: Bad command" {
  touch "testfile.txt"
  run _execute_ "rm nonexistant.txt"
  assert_success
  assert_output --partial "[warning] rm nonexistant.txt"
  assert_file_exist "testfile.txt"
}

@test "_execute_: Good command" {
  touch "testfile.txt"
  run _execute_ "rm testfile.txt"
  assert_success
  assert_output --partial "[success] rm testfile.txt"
  assert_file_not_exist "testfile.txt"
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

@test "_inArray_: success" {
  A=(one two three 1 2 3)
  run _inArray_ one "${A[@]}"
  assert_success
}

@test "_inArray_: failure" {
  A=(one two three 1 2 3)
  run _inArray_ ten "${A[@]}"
  assert_failure
}