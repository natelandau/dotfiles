_sourceFiles_() {
  filesToSource=(
    ${HOME}/dotfiles/scripting/helpers/baseHelpers.bash
    ${HOME}/dotfiles/scripting/helpers/files.bash
    ${HOME}/dotfiles/scripting/helpers/textProcessing.bash
  )

  for sourceFile in "${filesToSource[@]}"; do
    [ ! -f "$sourceFile" ] \
      &&  { echo "error: Can not find sourcefile '$sourceFile'. Exiting."; exit 1; }

    source "$sourceFile"
  done

quiet=false
printLog=false
logErrors=false
verbose=false
dryrun=false

}
_sourceFiles_