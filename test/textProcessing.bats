#!/usr/bin/env bats
#shellcheck disable

load 'helpers/bats-support/load'
load 'helpers/bats-file/load'
load 'helpers/bats-assert/load'

s="${HOME}/dotfiles/scripting/helpers/textProcessing.bash"
base="$(basename $s)"

[ -f "$s" ] \
  && { source "$s"; trap - EXIT INT TERM ; } \
  || { echo "Can not find script to test" ; exit 1 ; }

# Set Flags
quiet=false;              printLog=false;             verbose=false;
force=false;              strict=false;               dryrun=false;
debug=false;              sourceOnly=false;           args=();

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

@test "Sanity..." {
  run true

  assert_success
  assert_output ""
}

########### BEGIN TESTS ##########


@test "_escape_" {
  run _escape_ "Here is some / text to & be - escape'd"
  assert_success
  assert_output "Here\ is\ some\ /\ text\ to\ &\ be\ -\ escape'd"
}

@test "_stopWords_: success" {
  run _stopWords_ "A string to be parsed"
  assert_success
  assert_output "string parsed"
}

@test "_stopWords_: success w/ user terms" {
  run _stopWords_ "A string to be parsed to help pass this test being performed by bats" "bats,string"
  assert_success
  assert_output "parsed pass performed"
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

@test "_lower" {
  local text="$(echo "MAKE THIS LOWERCASE" | _lower_)"

  run echo "$text"
  assert_output "make this lowercase"
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

@test "_upper_" {
  local text="$(echo "make this uppercase" | _upper_)"

  run echo "$text"
  assert_output "MAKE THIS UPPERCASE"
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