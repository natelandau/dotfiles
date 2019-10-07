#!/usr/bin/env bats
#shellcheck disable

load 'helpers/bats-support/load'
load 'helpers/bats-file/load'
load 'helpers/bats-assert/load'

gitRoot="$(git rev-parse --show-toplevel)"
filesToSource=(
  "${gitRoot}/scripting/helpers/numbers.bash"
  "${gitRoot}/scripting/helpers/baseHelpers.bash"
)
for sourceFile in "${filesToSource[@]}"; do
  [ ! -f "${sourceFile}" ] \
    && {
      echo "error: Can not find sourcefile '${sourceFile}'"
      echo "exiting..."
      exit 1
    }
  source "${sourceFile}"
  trap - EXIT INT TERM
done

# Set initial flags
quiet=false
printLog=false
logErrors=false
verbose=false
force=false
dryrun=false
declare -a args=()

@test "Sanity..." {
  run true

  assert_success
  assert_output ""
}

@test "_convertSecs_: Seconds to human readable" {

  run _fromSeconds_ "9255"
  assert_success
  assert_output "02:34:15"
}

@test "_toSeconds_: HH MM SS to Seconds" {
  run _toSeconds_ 12 3 33
  assert_success
  assert_output "43413"
}

@test "_countdown_" {
  run _countdown_ 10 0 "something"
  assert_line --index 0 --partial "something 10"
  assert_line --index 9 --partial "something 1"
}
