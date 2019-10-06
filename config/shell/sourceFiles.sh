_sourceFiles_() {
  filesToSource=(
    "${HOME}/dotfiles/scripting/helpers/baseHelpers.bash"
    "${HOME}/dotfiles/scripting/helpers/files.bash"
    "${HOME}/dotfiles/scripting/helpers/textProcessing.bash"
    "${HOME}/dotfiles/scripting/helpers/numbers.bash"
  )

  for sourceFile in "${filesToSource[@]}"; do
    [ ! -f "$sourceFile" ] \
      && { echo "error: Can not find sourcefile '$sourceFile'"; }
    source "$sourceFile"
  done

  # Set default usage flags
  quiet=false
  printLog=false
  logErrors=false
  verbose=false
  dryrun=false
  force=false

}
_sourceFiles_
