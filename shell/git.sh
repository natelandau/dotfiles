alias g='git'

# Adding and Committing
alias gm="git add .; git commit -m"           # Add and Commit git changes
alias gcm="git --no-pager commit -m "         # Commit - Short message
alias gc="git --no-pager commit"              # Commit - Long message
alias gcv="git --no-pager commit --no-verify" # Commit - Long message, skips pre-commit hook
alias gshit='git add . ; git commit --amend'  # Appends current changes to the last commit
alias gap='git add -p'                        # step through each change, or hunk
alias unstage='git reset --'                  # unstage a file
ga() { git add "${@:-.}"; }                   # Add all files by default
gac() {
  # Add and Commit a single specified file with a commit message
  git add -A "${1}"
  git commit -m "${2}"
}

# Cloning, Fetching, Pushing, and Pulling
alias gp='git push'
alias gpush='git push'
alias gu='git up'
alias gfu="git fetch origin"                 # Get updates from Origin
alias gcl='git clone --recursive'            # Clone with all submodules
gcheckout() { git checkout "${@:-master}"; } # Checkout master by default

gpull() {
  git up
  git submodule foreach git pull origin master
}

# _gitAliases_() {
#   # This function creates completion-aware g<alias> bash aliases for each of your git aliases.
#   # Taken wholecloth from here:  https://gist.github.com/tyomo4ka/f76ac325ecaa3260808b98e715410067

#   local al __git_aliased_command __git_aliases __git_complete complete_fnc complete_func

#   if [ -f "$(brew --prefix)/share/bash-completion/bash_completion" ]; then
#       . "$(brew --prefix)/share/bash-completion/bash_completion"
#   else
#     echo "no completions"
#     return 0
#   fi

#   function_exists() {
#       declare -f -F $1 > /dev/null
#       return $?
#   }

#   for al in $(__git_aliases); do
#       # shellcheck disable=2139
#       alias g${al}="git $al"
#       complete_func=_git_$(__git_aliased_command ${al})
#       function_exists ${complete_fnc} && __git_complete g${al} ${complete_func}
#   done
# }
# _gitAliases_

# Submodules
alias gsubs='git submodule update --recursive --remote'
alias ginitsubs='git submodule update --init --recursive'

# Status, Logs, and information
alias gs="git --no-pager status -s --untracked-files=all" # Git Status
alias gsearch='git rev-list --all | xargs git grep -F'    # Find a string in Git History
alias gss="git remote update && git status -uno"          # Check local is behind remote
alias gr="git remote -v"                                  # List all configured Git remotes
alias gl="git ll"                                         # A nicer Git Log
alias gb='git branch'                                     # Lists local branches
alias gba='git branch -a'                                 # Lists local and remote branches

# General Commands
if command -v diff-so-fancy &>/dev/null; then
  alias diff="diff-so-fancy"
else
  alias diff="git diff"
fi
alias gdiff="git difftool" # Open file in git's default diff tool
alias gstash='git stash'   # stash git changes and put them into your list
alias gpop='git stash pop' # bring back your changes, but it removes them from your stash
alias greset="git fetch --all;git reset --hard origin/master"

# Cleaning up messes
alias undopush="git push -f origin HEAD^:master" # Undo a `git push`

# Gists

# gist-paste filename.ext -- create private Gist from the clipboard contents
alias gist-paste="gist --private --copy --paste --filename"
# gist-file filename.ext -- create private Gist from a file
alias gist-file="gist --private --copy"

applyGitIgnore() {
  # Applies changes to the git .ignorefile after the files
  # mentioned were already committed to the repo
  git ls-files -ci --exclude-standard -z | xargs -0 git rm --cached
}

gitRevert() {
  # Applies changes to HEAD that revert all changes after specified commit
  git reset "${1}"gg
  git reset --soft HEAD@{1}
  git commit -m "Revert to ${1}"
  git reset --hard
}

gitRollback() {
  # Resets the current HEAD to specified commit

  is_clean() {
    if [[ $(git diff --shortstat 2>/dev/null | tail -n1) != "" ]]; then
      echo "Your branch is dirty, please commit your changes"
      kill -INT $$
    fi
  }

  commit_exists() {
    git rev-list --quiet "$1"
    status=$?
    if [ $status -ne 0 ]; then
      echo "Commit ${1} does not exist"
      kill -INT $$
    fi
  }

  keep_changes() {
    while true; do
      read -r -p "Do you want to keep all changes from rolled back revisions in your working tree? [Y/N]" RESP
      case $RESP in

        [yY])
          echo "Rolling back to commit ${1} with unstaged changes"
          git reset "$1"
          break
          ;;
        [nN])
          echo "Rolling back to commit ${1} with a clean working tree"
          git reset --hard "$1"
          break
          ;;
        *)
          echo "Please enter Y or N"
          ;;
      esac
    done
  }

  if [ -n "$(git symbolic-ref HEAD 2>/dev/null)" ]; then
    is_clean
    commit_exists "$1"

    while true; do
      read -r -p "WARNING: This will change your history and move the current HEAD back to commit ${1}, continue? [Y/N]" RESP
      case $RESP in

        [yY])
          keep_changes "$1"
          break
          ;;
        [nN])
          break
          ;;
        *)
          echo "Please enter Y or N"
          ;;
      esac
    done
  else
    echo "you're currently not in a git repository"
  fi
}

gurl() {
  # Prints URL of current git repository
  local remote remotename host user_repo

  remotename="${*:-origin}"
  remote="$(git remote -v | awk '/^'"${remotename}"'.*\(push\)$/ {print $2}')"
  [[ "$remote" ]] || return
  host="$(echo "$remote" | perl -pe 's/.*@//;s/:.*//')"
  user_repo="$(echo "$remote" | perl -pe 's/.*://;s/\.git$//')"
  echo "https://${host}/${user_repo}"
}

githelp() {
  cat <<TEXT

  Git has no undo feature, but maybe these will help:
  ===================================================

  ## Unstage work

    Unstage a file
    --------------
    ${bold}git reset HEAD <file>${reset}

  ## Uncommit work (leaving changes in working directory):

    Undo the last commit
    --------------------
    ${bold}git reset --soft HEAD^1${reset}

    Undo all commits back to the state of the remote master branch
    --------------------------------------------------------------
    ${bold}git reset --soft origin/master${reset}

  ## Amend a commit

    Change the message
    ------------------
    ${bold}git commit --amend -m 'new message'${reset}

    Add more changes to the commit
    ------------------------------
    ${bold}git add <file>
    git commit --amend${reset}

  ## Discard uncommitted changes

    Discard all uncommitted changes in your working directory
    ---------------------------------------------------------
    ${bold}git reset --hard HEAD${reset}

    Discard uncommitted changes to a file
    -------------------------------------
    ${bold}git checkout HEAD <file>${reset}

  ## Discard committed changes

    Reset the current branch's HEAD to a previous commit
    ----------------------------------------------------
    ${bold}git reset --hard <commit>${reset}

    Reset the current branch's HEAD to origin/master
    ------------------------------------------------
    ${bold}git reset --hard origin/master${reset}

  ## Recovering work after a hard reset

    Restore work after you've done a 'git reset --hard'
    ---------------------------------------------------
    ${bold}$ git reflog${reset}
      1a75c1d... HEAD@{0}: reset --hard HEAD^: updating HEAD
      f6e5064... HEAD@{1}: commit: <some commit message>
    ${bold}$ git reset --hard HEAD@{1}${reset}

TEXT
}
