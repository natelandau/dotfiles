_installGitFriendly_() {
  info "Installing git-friendly...."

  # github.com/jamiew/git-friendly
  # the `push` command which copies the github compare URL to my clipboard is heaven
  execute "bash < <( curl https://raw.github.com/jamiew/git-friendly/master/install.sh)"
}
_executeFunction_ "_installGitFriendly_" "Install Git Friendly"