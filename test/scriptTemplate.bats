#!/usr/bin/env bats
# shellcheck disable

load 'helpers/bats-support/load'
load 'helpers/bats-file/load'
load 'helpers/bats-assert/load'

rootDir="$(git rev-parse --show-toplevel)"
[[ "${rootDir}" =~ private ]] && rootDir="${HOME}/dotfiles"
if ! test -f "${rootDir}/scripting/scriptTemplate.sh"; then
    printf "No executable 'scriptTemplate' found.\n" >&2
    printf "Can not run tests.\n" >&2
    exit 1
else
    s="${rootDir}/scripting/scriptTemplate.sh"
    base="$(basename "$s")"
fi


######## RUN TESTS ##########
@test "sanity" {
  run true
  assert_success
  assert [ "$output" = "" ]
}

@test "Fail - bad args" {
  run "$s" -LK
  assert_failure
  assert_output --partial "[  fatal] invalid option: '-K'"
}

@test "success" {
  run "$s"
  assert_success
  assert_output "hello world"
}

@test "Usage (-h)" {
  run "$s" -h

  assert_success
  assert_line --partial --index 0 "$base [OPTION]... [FILE]..."
}

@test "Usage (--help)" {
  run "$s" --help

  assert_success
  assert_line --partial --index 0 "$base [OPTION]... [FILE]..."
}