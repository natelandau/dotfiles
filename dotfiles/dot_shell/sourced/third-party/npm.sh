# Run locally installed npm packages
# http://stackoverflow.com/questions/9679932/how-to-use-package-installed-locally-in-node-modules
# usage:
#   $ npm-exec grunt

if command -v npm &>/dev/null; then
    alias npm-exec='PATH=$(npm bin):$PATH'
    alias grunt="npm-exec grunt"
fi
