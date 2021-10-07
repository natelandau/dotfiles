ff() { find . -name "$1"; }     # ff:     Find file under the current directory
ffs() { find . -name "$1"'*'; } # ffs:    Find file whose name starts with a given string
ffe() { find . -name '*'"$1"; } # ffe:    Find file whose name ends with a given string
