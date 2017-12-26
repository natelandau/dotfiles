segmentGit() {
  local fground=$whi
  local bground=$ora
  local enabled=true # If false, this segment will be ignored

  local s=''
  local branchName=''
  # Check if the current directory is in a Git repository.
  if [ "$(
    git rev-parse --is-inside-work-tree &>/dev/null
    echo "${?}"
  )" == '0' ]; then
    # check if the current directory is in .git before running git checks

    if [ "$(git rev-parse --is-inside-git-dir 2>/dev/null)" == 'false' ]; then

      # Ensure the index is up to date.
      git update-index --really-refresh -q &>/dev/null

      # Check for uncommitted changes in the index.
      if ! git diff --quiet --ignore-submodules --cached; then
        s+='+'
      fi

      # Check for unstaged changes.
      if ! git diff-files --quiet --ignore-submodules --; then
        s+='!'
      fi

      # Check for untracked files.
      if [ -n "$(git ls-files --others --exclude-standard)" ]; then
        s+='?'
      fi

      # Check for stashed files.
      if git rev-parse --verify refs/stash &>/dev/null; then
        s+='$'
      fi

      # See how many commits ahead or behind we are
      local stat="$(env LANG=C git status --porcelain --branch | grep --color=never -o '\[.\+\]$')"
      local aheadN="$(echo $stat | grep --color=never -o 'ahead [[:digit:]]\+' | grep --color=never -o '[[:digit:]]\+')"
      local behindN="$(echo $stat | grep --color=never -o 'behind [[:digit:]]\+' | grep --color=never -o '[[:digit:]]\+')"
      [ -n "$aheadN" ] && s+=" ⇡$aheadN"
      [ -n "$behindN" ] && s+=" ⇣$behindN"
    fi

    # Get the short symbolic ref.
    # If HEAD isn’t a symbolic ref, get the short SHA for the latest commit
    # Otherwise, just give up.
    branchName="$(git symbolic-ref --quiet --short HEAD 2>/dev/null \
      || git rev-parse --short HEAD 2>/dev/null \
      || echo '(unknown)')"

    [ -n "${s}" ] && s=" [${s}]"

    # Build the segment
    local promptSegment="  ${1}${branchName}${s}"

    # Output to prompt
    _parseSegments_ "${promptSegment}" "${fground}" "${bground}" "${enabled}"
  fi
}
segmentGit "$@"
