
prompt_git() {
  local s=''
  local branchName=''

  # Check if the current directory is in a Git repository.
  if [ "$(git rev-parse --is-inside-work-tree &>/dev/null; echo "${?}")" == '0' ]; then
    # check if the current directory is in .git before running git checks

    if [ "$(git rev-parse --is-inside-git-dir 2> /dev/null)" == 'false' ]; then

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
    fi

    # Get the short symbolic ref.
    # If HEAD isn’t a symbolic ref, get the short SHA for the latest commit
    # Otherwise, just give up.
    branchName="$(git symbolic-ref --quiet --short HEAD 2> /dev/null || \
      git rev-parse --short HEAD 2> /dev/null || \
      echo '(unknown)')";

    [ -n "${s}" ] && s=" [${s}]";

    echo -e "${1}${branchName}${s}";
  else
    return;
  fi

}

export PS1="\[$WHITE\]________________________________________________________________________________\n| \
\[${BOLD}${MAGENTA}\]\u \[$WHITE\]at \[$ORANGE\]\h \
\[$WHITE\]in \[$GREEN\]\w\[$WHITE\]\
\$([[ -n \$(git branch 2> /dev/null) ]] && echo \" on \")\
\[$PURPLE\]\$(prompt_git \"$PRUPLE\")\[$WHITE\]\[$RESET\] \
\n\[$WHITE\]| =>\[$RESET\] "
export PS2="\[$WHITE\]→ \[$RESET\]"