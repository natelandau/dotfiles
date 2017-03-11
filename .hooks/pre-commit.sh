#!/usr/bin/env bash

# shellcheck disable=2181

trap _safeExit_ "1" EXIT INT TERM

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

_safeExit_() {
  trap - INT TERM EXIT
  exit ${1:-0}
}

_execute_() {
  $1 #&> /dev/null
  if [ $? -ne 0 ]; then
    echo "Error: '$1'. Commit aborted..."
    _safeExit_ "1"
  fi
}

# Ensure that no symlinks are added. Here we add them to .gitignore
GITROOT=$(git rev-parse --show-toplevel 2> /dev/null)
gitIgnore="$GITROOT/.gitignore"

# Work on files not yet staged
havesymlink=false
for f in $(git status --porcelain | grep '^??' | sed 's/^?? //'); do
  if test -L "$f"; then
    if ! grep "$f" "$gitIgnore"; then
      echo -e "\n$f" >> "$gitIgnore"
    fi
    havesymlink=true
  fi
done

# Work on files that were mistakenly staged
for f in $(git status --porcelain | grep '^A' | sed 's/^A //'); do
  if test -L "$f"; then
    if ! grep "$f" "$gitIgnore"; then
      git reset -q "$f"
      echo -e "\n$f" >> "$gitIgnore"
    fi
    havesymlink=true
  fi
done

if ${havesymlink}; then
  echo "Error: At least one symlink was added to the repo."
  echo "Error: It has been unstaged and added to .gitignore"
  echo "Error: Commit aborted..."
  exit 1
fi

# if you only want to lint the staged changes, not any un-staged changes, use:
# git show ":$file" | <command>


# Lint YAML files
if which yaml-lint >/dev/null; then
  for file in $(git diff --cached --name-only | grep -E '\.(yaml|yml)$'); do
    _execute_ "yaml-lint $file"
  done
fi

# Lint shell scripts
if which shellcheck >/dev/null; then
  for file in $(git diff --cached --name-only | grep -E '\.(sh|bash)$'); do
    if [ -f "$file" ]; then
      _execute_ "shellcheck --exclude=2016,2059,2001,2002,2148,1090,2162,2005,2034,2154,2086,2155,2181,2164,2120,2119,1083 $file"
    fi
  done
fi

# Run BATS where appropriate
for file in $(git diff --cached --name-only | grep -E 'bin/'); do
  filename="$(basename $file)"
  filename="${filename%.*}"
  [ -f "${GITROOT}/test/${filename}.bats" ] && _execute_ "${GITROOT}/test/${filename}.bats -t"
done

exit 0