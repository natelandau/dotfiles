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

if ! test -f "${HOME}/dotfiles/scripting/scriptTemplate.sh"; then
    printf "No executable 'scriptTemplate' found.\n" >&2
    printf "Can not run tests.\n" >&2
    exit 1
else
    s="${HOME}/dotfiles/scripting/scriptTemplate.sh"
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