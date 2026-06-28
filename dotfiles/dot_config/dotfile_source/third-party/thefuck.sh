# Lazy-load thefuck: invoking it cold-starts a Python interpreter (hundreds of
# ms). Defer that to first use of `fuck` instead of paying it every shell start.
if [[ "$(command -v thefuck)" ]]; then
    fuck() {
        eval "$(thefuck --alias)"
        fuck "$@"
    }
fi
