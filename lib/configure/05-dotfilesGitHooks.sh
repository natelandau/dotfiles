# shellcheck disable=2154

_installGitHooks_() {
  info "Installing git hooks for this repository..."

  GITROOT=$(git rev-parse --show-toplevel 2> /dev/null)

  if [ "${GITROOT}" == "" ]; then
    warning "This does not appear to be a git repo."
    return
  fi

  # Location of hooks
  hooksLocation="${baseDir}/.hooks"

  if ! [ -d "$hooksLocation" ]; then
    warning "Can't find hooks. Exiting."
    return
  fi

  for hook in ${hooksLocation}/*.sh; do
    hook="$(basename ${hook})"

    sourceFile="${hooksLocation}/${hook}"
    destFile="${baseDir}/.git/hooks/${hook%.sh}"

    if [ -e "$destFile" ]; then
      execute "rm $destFile"
    fi
    execute "ln -fs $sourceFile $destFile" "symlink $sourceFile → $destFile"

  done

  unset sourceFile
  unset destFile
  unset hook
  unset hooksLocation
  unset GITROOT
}
_executeFunction_ "_installGitHooks_" "Install Git Hooks"