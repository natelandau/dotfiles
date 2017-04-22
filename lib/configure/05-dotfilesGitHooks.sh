# shellcheck disable=2154

_installGitHooks_() {
  info "Installing git hooks for this repository..."

  local GITROOT
  local hook
  GITROOT=$(git rev-parse --show-toplevel 2> /dev/null)

  if [ "${GITROOT}" == "" ]; then
    warning "This does not appear to be a git repo."
    return
  fi

  # Location of hooks
  local hooksLocation="${GITROOT}/.hooks"

  if ! [ -d "$hooksLocation" ]; then
    warning "Can't find hooks. Exiting."
    return
  fi

  for hook in ${hooksLocation}/*.sh; do
    hook="$(basename ${hook})"

    local sourceFile="${hooksLocation}/${hook}"
    local destFile="${GITROOT}/.git/hooks/${hook%.sh}"

    if [ -e "$destFile" ]; then
      _execute_ "rm $destFile"
    fi
    _execute_ "ln -fs \"$sourceFile\" \"$destFile\"" "symlink $sourceFile → $destFile"

  done
}
_installGitHooks_