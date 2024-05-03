#!/usr/bin/env bash
if command -v pygmentize &>/dev/null; then
    # Original at: https://superuser.com/questions/117841/get-colors-in-less-or-more
    case "$1" in
        *.awk | *.groff | *.java | *.js | *.m4 | *.php | *.pl | *.pm | *.pod | *.sh | \
            *.ad[asb] | *.asm | *.inc | *.[ch] | *.[ch]pp | *.[ch]xx | *.cc | *.hh | \
            *.lsp | *.l | *.pas | *.p | *.xml | *.xps | *.xsl | *.axp | *.ppd | *.pov | \
            *.diff | *.patch | *.py | *.rb | *.sql | *.ebuild | *.eclass | *.html | \
            *.yml | *.json | *.less | *.sass | *.css | *.cfg | *.md | *.markdown)
            pygmentize -f terminal256 -O style=native -g "$1"
            ;;

        .bashrc | .zshrc | *.bash | *.config | *.zsh | *.bats)
            pygmentize -f terminal256 -O style=native -l sh -g "$1"
            ;;

        *.plist)
            pygmentize -f terminal256 -O style=native -l xml -g "$1"
            ;;

        *)
            if grep -q "#\!/bin/bash" "$1" 2>/dev/null; then
                pygmentize -f terminal256 -O style=native -g "$1"
            elif grep -q "#!/usr/bin/env bash" "$1" 2>/dev/null; then
                pygmentize -f terminal256 -O style=native -g "$1"
            else
                exit 1
            fi
            ;;
    esac
fi

exit 0
