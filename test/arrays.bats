#!/usr/bin/env bats
#shellcheck disable

load 'helpers/bats-support/load'
load 'helpers/bats-file/load'
load 'helpers/bats-assert/load'

rootDir="$(git rev-parse --show-toplevel)"
[[ "${rootDir}" =~ private ]] && rootDir="${HOME}/dotfiles"
filesToSource=(
  "${rootDir}/scripting/helpers/arrays.bash"
  "${rootDir}/scripting/helpers/baseHelpers.bash"
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

setup() {

  # Set arrays
  A=(one two three 1 2 3)
  B=(1 2 3 4 5 6)

}

@test "Sanity..." {
  run true

  assert_success
  assert_output ""
}

########### BEGIN TESTS ########

@test "_inArray_: success" {
  run _inArray_ one "${A[@]}"
  assert_success
}

@test "_inArray_: failure" {
  run _inArray_ ten "${A[@]}"
  assert_failure
}

@test "_join_: Join array comma" {
  run _join_ , "${B[@]}"
  assert_output "1,2,3,4,5,6"
}

@test "_join_: Join array space" {
  run _join_ " " "${B[@]}"
  assert_output "1 2 3 4 5 6"
}

@test "_join_: Join string complex" {
  run _join_ , a "b c" d
  assert_output "a,b c,d"
}

@test "_join_: join string simple" {
  run _join_ / var usr tmp
  assert_output "var/usr/tmp"
}

@test "_setdiff_: Print elements not common to arrays" {
  run _setdiff_ "${A[*]}" "${B[*]}"
  assert_output "one two three"

  run _setdiff_ "${B[*]}" "${A[*]}"
  assert_output "4 5 6"
}