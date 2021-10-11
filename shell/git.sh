# Short commit
alias gcm="git --no-pager commit -m "
# Long commit
alias gc="git --no-pager commit"
# Long commit no verification
alias gcv="git --no-pager commit --no-verify"
alias gshit='git add . ; git commit --amend' # Appends current changes to the last commit
alias gap='git add -p'                       # Step through each change
alias unstage='git reset --'                 # Unstage a file
ga() { git add "${@:-.}"; }                  # Add all files by default
alias gp='git push'
alias gu='git up'
alias gfo="git fetch origin"
# Clone with all submodules
alias gcl='git clone --recursive'
alias gsubs='git submodule update --recursive --remote'
alias ginitsubs='git submodule update --init --recursive'
# Are we behind remote?
alias gs="git --no-pager status -s --untracked-files=all"
# Find a string in Git History
alias gsearch='git rev-list --all | xargs git grep -F'
alias gss="git remote update && git status -uno"
# List all configured Git remotes
alias gr="git remote -v"
# A nicer Git Log
alias gl="git ll"
# Lists local branches
alias gb='git branch'
# Lists local and remote branches
alias gba='git branch -a'
if command -v diff-so-fancy &>/dev/null; then
    alias diff="diff-so-fancy"
else
    alias diff="git diff"
fi
alias gdiff="git difftool" # Open file in git's default diff tool
alias gstash='git stash'
alias gpop='git stash pop'
alias greset="git fetch --all;git reset --hard origin/master" # Reset all changes to origin/remote
alias undopush="git push -f origin HEAD^:master"              # Undo a `git push`

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

# Gists

# gist-paste filename.ext -- create private Gist from the clipboard contents
alias gist-paste="gist --private --copy --paste --filename"
# gist-file filename.ext -- create private Gist from a file
alias gist-file="gist --private --copy"

gitapplyignore() {
    # DESC:   Applies changes to the git .ignorefile after the files mentioned were already committed to the repo
    # ARGS:		None
    # OUTS:		None
    # USAGE:

    git ls-files -ci --exclude-standard -z | xargs -0 git rm --cached
}

gitrevert() {
    # Applies changes to HEAD that revert all changes after specified commit
    git reset "${1}"gg
    git reset --soft HEAD@{1}
    git commit -m "Revert to ${1}"
    git reset --hard
}

gitrollback() {
    # DESC:		Resets the current HEAD to specified commit
    # ARGS:		$1 (Required): Commit to revert to
    # OUTS:		None
    # USAGE:  gitRollback <commit>

    _is_clean_() {
        if [[ $(git diff --shortstat 2>/dev/null | tail -n1) != "" ]]; then
            echo "Your branch is dirty, please commit your changes"
            return 1
        fi
        return 0
    }

    _commit_exists_() {
        git rev-list --quiet "$1"
        status=$?
        if [ $status -ne 0 ]; then
            echo "Commit ${1} does not exist"
            return 1
        fi
        return 0
    }

    _keep_changes_() {
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
        if _is_clean_; then
            if _commit_exists_ "$1"; then

                while true; do
                    read -r -p "WARNING: This will change your history and move the current HEAD back to commit ${1}, continue? [Y/N]" RESP
                    case $RESP in

                        [yY])
                            _keep_changes_ "$1"
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
            fi
        fi
    else
        echo "you're currently not in a git repository"
    fi
}

giturl() {
    # DESC:		Prints URL of current git repository
    # ARGS:		None
    # OUTS:		None

    local remote remotename host user_repo

    remotename="${*:-origin}"
    remote="$(git remote -v | awk '/^'"${remotename}"'.*\(push\)$/ {print $2}')"
    [[ "${remote}" ]] || return
    host="$(echo "${remote}" | perl -pe 's/.*@//;s/:.*//')"
    user_repo="$(echo "${remote}" | perl -pe 's/.*://;s/\.git$//')"
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
