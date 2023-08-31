ff() { find . -name "$1"; }     # Find file under the current directory
ffs() { find . -name "$1"'*'; } # Find file whose name starts with a given string
ffe() { find . -name '*'"$1"; } # Find file whose name ends with a given string
