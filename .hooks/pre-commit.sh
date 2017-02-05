#!/usr/bin/env bash

# shellcheck disable=2181
function execute() {
    $1 #&> /dev/null
    if [ $? -ne 0 ]; then
      echo "Error: '$1'"
      echo "Commit aborted..."
      exit 1
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
    execute "yaml-lint $file"
  done
fi

# Lint shell scripts
if which shellcheck >/dev/null; then
  for file in $(git diff --cached --name-only | grep -E '\.(sh|bash)$'); do
    if [ -f "$file" ]; then
      execute "shellcheck --exclude=2016,2059,2001,2002,2148,1090,2162,2005,2034,2154,2086,2155,2181,2164,2120,2119,1083 $file"
    fi
  done
fi

exit 0