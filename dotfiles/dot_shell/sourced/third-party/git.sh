alias diff="git difftool"                                 # Open file in git's default diff tool <file>
alias fetch="git fetch origin"                            # Fetch from origin
alias gc="git --no-pager commit"                          # Commit w/ message written in EDITOR
alias gcl='git clone --recursive'                         # Clone with all submodules
alias gcm="git --no-pager commit -m"                      # Commit w/ message from the command line <commit message>
alias gcv="git --no-pager commit --no-verify"             # Commit without verification
alias ginitsubs='git submodule update --init --recursive' # Init and update all submodules
alias gundo="git reset --soft HEAD^"                      # Undo last commit
alias gs='git --no-pager status -s --untracked-files=all' # Git status
alias gss='git remote update && git status -uno'          # Are we behind remote?
alias gsubs='git submodule update --recursive --remote'   # Update all submodules
alias undopush="git push -f origin HEAD^:master"          # Undo a git push

ga() { git add "${@:-.}"; } # Add file (default: all)

alias gl='git log --pretty=format:"%C(yellow)%h\\ %ad%Cred%d\\ %Creset%s%Cblue\\ [%cn]" --decorate --date=short' # A nicer Git Log

applyignore() {
    # DESC:   Applies changes to the git .ignorefile after the files mentioned were already committed to the repo
    git ls-files -ci --exclude-standard -z | xargs -0 git rm --cached
}

rollback() {
    # DESC:	  Resets the current HEAD to specified commit
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

gurl() {
    # DESC:		Prints URL of current git repository
    local remote remotename host user_repo

    remotename="${*:-origin}"
    remote="$(git remote -v | awk '/^'"${remotename}"'.*\(push\)$/ {print $2}')"
    [[ "${remote}" ]] || return
    host="$(echo "${remote}" | perl -pe 's/.*@//;s/:.*//')"
    user_repo="$(echo "${remote}" | perl -pe 's/.*://;s/\.git$//')"
    echo "https://${host}/${user_repo}"
}

gnuke() {
    # DESC:		Nuke everything in local and reset from origin
    git fetch --all
    ORIGIN_HEAD=$(git remote show origin | grep --color=never -Po 'HEAD branch:\K[^"]*' | sed 's/ //g')
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD | sed 's/ //g')

    if [[ ${ORIGIN_HEAD} == "${CURRENT_BRANCH}" ]]; then
        git reset --hard origin/"${CURRENT_BRANCH}"
    else
        warning "Current branch '${CURRENT_BRANCH}' is not the same as origin HEAD '${ORIGIN_HEAD}'"
        return 1
    fi
}

# From Git-Extras (https://github.com/tj/git-extras)
alias obliterate='git obliterate'       # Completely remove a file from the repository, including past commits and tags
alias release='git-release'             # Create release commit with the given <tag> and other options
alias rename-branch='git rename-branch' # Rename a branch and sync with remote. <old name> <new name>
alias rename-tag='git rename-tag'       # Rename a tag (locally and remotely). <old name> <new name>
alias ignore='git ignore'               # Add files to .gitignore. Run without arguments to list ignored files.
alias ginfo='git info --no-config'      # Show information about the current repository.
alias del-sub='git delete-submodule'    # Delete a submodule. <name>
alias del-tag='git delete-tag'          # Delete a tag. <name>
alias changelog='git changelog'         # Generate a Changelog from tags and commit messages. -h for help.
alias garchive='git archive'            # Creates a zip archive of the current git repository. The name of the archive will depend on the current HEAD of your git repository.
alias greset='git reset'                # Reset one file to HEAD or certain commit. <file> <commit (optional)>
alias gclear='git clear-soft'           # Does a hard reset and deletes all untracked files from the working directory, excluding those in .gitignore.
alias gbrowse='git browse'              # Opens the current git repository website in your default web browser.
alias gtimes='git utimes'               # Change files modification time to their last commit date.
