#!/usr/bin/env bats
#shellcheck disable

load 'helpers/bats-support/load'
load 'helpers/bats-file/load'
load 'helpers/bats-assert/load'

s="${HOME}/dotfiles/bootstrap/config-linux.sh"
base="$(basename "$s")"

@test "Sanity..." {
  run true

  assert_success
  assert_output ""
}

@test "Fail on unknown argument" {
  run "$s" -LK

  assert_failure
  assert_output --partial "[  fatal] invalid option: '-K'."
}

@test "usage (-h)" {
  run "$s" -h

  assert_success
  assert_output --partial "Configures a new computer running linux."
}

@test "usage (--help)" {
  run "$s" --help

  assert_success
  assert_output --partial "Configures a new computer running linux."
}