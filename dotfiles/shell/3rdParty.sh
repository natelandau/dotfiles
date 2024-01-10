# RVM complains if it's not here
[[ -s "${HOME}/.rvm/scripts/rvm" ]] && source "${HOME}/.rvm/scripts/rvm"

# ASDF Package Manager
[[ -s "${HOME}/.asdf/asdf.sh" ]] && source "$HOME/.asdf/asdf.sh"
[[ -s "${HOME}/.asdf/completions/asdf.bash" ]] && source "$HOME/.asdf/completions/asdf.bash"

# Use Java JDK 1.8
if [[ "$(java -version &>/dev/null)" ]] && [[ -e "/usr/libexec/java_home" ]]; then
    JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
    export JAVA_HOME
fi

[[ "$(command -v thefuck)" ]] \
    && eval "$(thefuck --alias)"

# Git-Friendly Auto Completions
# https://github.com/jamiew/git-friendly
if [[ ${SHELL##*/} == "bash" ]]; then
    if type __git_complete &>/dev/null; then
        _branch() {
            delete="${words[1]}"
            if [ "${delete}" == "-d" ] || [ "${delete}" == "-D" ]; then
                _git_branch
            else
                _git_checkout
            fi
        }
        __git_complete branch _branch
        __git_complete merge _git_merge
    fi
# elif [[ ${SHELL##*/} == "zsh" ]] && [[ $OSTYPE == "darwin"* ]]; then
#     fpath=($(brew --prefix)/share/zsh/functions "${fpath}")
#     autoload -Uz _git && _git
#     compdef __git_branch_names branch
fi
