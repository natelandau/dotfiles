#!/usr/bin/env bats
#shellcheck disable

load 'helpers/bats-support/load'
load 'helpers/bats-file/load'
load 'helpers/bats-assert/load'

rootDir="$(git rev-parse --show-toplevel)"
[[ "${rootDir}" =~ private ]] && rootDir="${HOME}/dotfiles"
s="${rootDir}/bootstrap/config-macOS.sh"
base="$(basename "$s")"


@test "Sanity..." {
  [[ "$OSTYPE" != "darwin"* ]] && skip
  run true

  assert_success
  assert_output ""
}

@test "Fail on unknown argument" {
  [[ "$OSTYPE" != "darwin"* ]] && skip "not on mac os"
  run "$s" -LK

  assert_failure
  assert_output --partial "[  fatal] invalid option: '-K'."
}

@test "usage (-h)" {
  [[ "$OSTYPE" != "darwin"* ]] && skip "not on mac os"
  run "$s" -h

  assert_success
  assert_output --partial "Configures a new computer running MacOSX."
}

@test "usage (--help)" {
  [[ "$OSTYPE" != "darwin"* ]] && skip "not on mac os"
  run "$s" --help

  assert_success
  assert_output --partial "Configures a new computer running MacOSX."
}
