alias diff="git difftool"                                          # Open file in git's default diff tool <file>
alias fetch="git fetch origin"                                     # Fetch from origin
alias gc="git --no-pager commit"                                   # Commit w/ message written in EDITOR
alias gcl='git clone --recursive'                                  # Clone with all submodules
alias gcm="git --no-pager commit -m"                               # Commit w/ message from the command line <commit message>
alias gcv="git --no-pager commit --no-verify"                      # Commit without verification
alias ginitsubs='git submodule update --init --recursive'          # Init and update all submodules
alias gundo="git reset --soft HEAD^"                               # Undo last commit
alias gs='git --no-pager status -s --untracked-files=all --branch' # Git status
alias gss='git remote update && git status -uno'                   # Are we behind remote?
alias gsubs='git submodule update --recursive --remote'            # Update all submodules
alias undopush="git push -f origin HEAD^:master"                   # Undo a git push

ga() { git add "${@:-.}"; } # Add file (default: all)

HASH="%C(always,yellow)%h%C(always,reset)"
RELATIVE_TIME="%C(always,green)%ar%C(always,reset)"
AUTHOR="%C(always,bold blue)%an%C(always,reset)"
REFS="%C(always,red)%d%C(always,reset)"
SUBJECT="%s"

FORMAT="$HASH $RELATIVE_TIME{$AUTHOR{$REFS $SUBJECT"

pretty_git_log() {
    git log --graph --pretty="tformat:$FORMAT" \
        | column -t -s '{' \
        | \less -XRS --quit-if-one-screen
}

alias gl="pretty_git_log" # A nicer Git Log

alias gll='git log --pretty=format:"%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]" --decorate --date=short' # A nicer Git Log

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

# Creates a feature branch with date-indexed naming based on $USER.
# Add this function to your .bashrc or .zshrc file for easy access in every terminal session.
#
# Example:
# If $USER is "ckrauter" and today is 2024-11-08:
# Running `fb` creates a branch like `feature/ckrauter/2024-11-08/1`.
# Running `fb utils package` creates `feature/ckrauter/utils-package/2024-11-08/1`.

purge_merged_branches() {
    # DESC:	Purges merged branches no longer available on remote
    if ! git rev-parse --show-toplevel 2>/dev/null; then
        echo "Not in a git repository"
        return 1
    fi

    local main_branch
    main_branch=$(git remote show origin | grep 'HEAD branch' | awk '{print $3;}')
    git fetch -p
    git checkout "${main_branch}"
    if command -v pull >/dev/null; then
        pull
    fi
    for gone_branch in $(git branch -vv | grep ': gone]' | grep -v "\*" | awk '{ print $1; }'); do
        git branch --delete --force "${gone_branch}"
    done
}
alias pmb="purge_merged_branches" # Purge merged branches no longer available on remote

feature_branch() {
    # DESC:	Creates a feature branch with optional <name>
    #       https://gist.github.com/coltenkrauter/3e6a2f71cc6e37b03f227b8c7a8f7825
    # USAGE:  feature_branch <additional_path>
    # Example:
    #   If $USER is "nlandau" and today is 2024-11-08:
    #   Running `fb -ud` creates a branch like `feature/nlandau/2024-11-08/1`.
    #   Running `fb -ud utils package` creates `feature/nlandau/utils-package/2024-11-08/1`.

    local opt
    local OPTIND=1
    local dry_run=false
    local date_indexed=false
    local username_indexed=false
    local index=1
    local new_branch
    local main_branch="main"
    local prefix="feature"
    local today
    local username
    local additional_path
    today=$(date +%Y-%m-%d)
    username=$(echo "$USER" | tr '[:upper:]' '[:lower:]') # Convert $USER to lowercase

    while getopts "hdun" opt; do
        case "$opt" in
            h)
                \cat <<End-Of-Usage
$ ${FUNCNAME[0]} [option] <name (optional)>

Create a feature branch with optional <name>.

Options:
    -h  show this message and exit
    -d  use date-indexed naming
    -u  use username-indexed naming
    -n  dry run: don't create the branch, just print the branch name
End-Of-Usage
                return
                ;;
            d)
                date_indexed=true
                ;;
            u)
                username_indexed=true
                ;;
            n)
                dry_run=true
                ;;
            ?)
                feature_branch -h >&2
                return 1
                ;;
        esac
    done
    shift $((OPTIND - 1))

    additional_path=$(printf "%s" "$*" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]-' '-') # Convert arguments to hyphen-separated string

    # Construct the branch path prefix with optional additional path
    local branch_path="${prefix}"
    if [[ ${username_indexed} == true ]]; then
        branch_path="${branch_path}/${username}"
    fi
    [[ -n $additional_path ]] && branch_path="${branch_path}/${additional_path}"
    if [[ ${date_indexed} == true ]]; then
        branch_path="${branch_path}/${today}"
    fi

    # Switch to main branch and pull latest changes if not on main
    if [[ ${dry_run} == false && "$(git branch --show-current)" != "$main_branch" ]]; then
        echo "Switching to ${main_branch} and pulling latest changes..."
        git checkout "${main_branch}"
        git pull
    fi

    # Find the next available branch index
    while git rev-parse --verify --quiet "${branch_path}/${index}"; do
        index=$((index + 1))
    done

    # Create and switch to the new branch
    new_branch="${branch_path}/${index}"
    if [[ ${dry_run} == false ]]; then
        echo "Creating and checking out ${new_branch}..."
        git checkout -b "$new_branch"
    else
        echo "${new_branch}"
    fi
}
alias fb="feature_branch" # Create a feature branch. Alias for feature_branch

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
