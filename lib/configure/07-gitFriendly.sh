if ! command -v pull &> /dev/null; then
  _installGitFriendly_() {
    info "Installing git-friendly...."

    # github.com/jamiew/git-friendly
    # the `push` command which copies the github compare URL to my clipboard is heaven
    _execute_ "bash < <( curl https://raw.github.com/jamiew/git-friendly/master/install.sh)"
  }
  _installGitFriendly_
fi