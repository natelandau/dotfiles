#!/usr/bin/env bats
# shellcheck disable

load 'helpers/bats-support/load'
load 'helpers/bats-file/load'
load 'helpers/bats-assert/load'

rootDir="$(git rev-parse --show-toplevel)"
[[ "${rootDir}" =~ private ]] && rootDir="${HOME}/dotfiles"
if ! test -f "${rootDir}/bin/updateHomebrew" &>/dev/null; then
    printf "No executable 'trash' found.\n" >&2
    printf "Can not run tests.\n" >&2
    exit 1
else
    s="${rootDir}/bin/updateHomebrew"
    base="$(basename "$s")"
fi

@test "sanity" {
  [[ "$OSTYPE" != "darwin"* ]] && skip "not MacOS"
  run true
  assert_success
  assert [ "$output" = "" ]
}

@test "Fail - bad args" {
  [[ "$OSTYPE" != "darwin"* ]] && skip "not MacOS"
  run "$s" -LK
  assert_failure
  assert_output --partial "[  fatal] invalid option: '-K'"
}

@test "usage (-h)" {
  [[ "$OSTYPE" != "darwin"* ]] && skip "not MacOS"
  run "$s" -h

  assert_success
  assert_line --index 0 "  updateHomebrew [OPTION]..."
}

@test "usage (--help)" {
  [[ "$OSTYPE" != "darwin"* ]] && skip "not MacOS"
  run "$s" --help

  assert_success
  assert_line --index 0 "  updateHomebrew [OPTION]..."
}

@test "Dryrun (-n)" {
  [[ "$OSTYPE" != "darwin"* ]] && skip "not MacOS"
  run "$s" -n

  assert_success
  assert_line --index 0 --partial "[ notice] Updating Homebrew..."
  assert_line --index 2 --partial "[ dryrun] brew upgrade (line:"
}

@test "Dryrun (--dryrun)" {
  [[ "$OSTYPE" != "darwin"* ]] && skip "not MacOS"
  run "$s" --dryrun

  assert_success
  assert_line --index 0 --partial "[ notice] Updating Homebrew..."
  assert_line --index 2 --partial "[ dryrun] brew upgrade (line:"
}