#!/usr/bin/env bash

# This script installs nano syntax highlighting for various languages.

# Check if nano is installed
if ! command -v nano &>/dev/null; then
    echo "nano is not installed. Please install nano first."
    exit 1
fi

# check for unzip before we continue
if [ ! "$(command -v unzip)" ]; then
    echo 'unzip is required but was not found. Install unzip first and then run this script again.' >&2
    exit 1
fi

# Check if the nano syntax highlighting directory exists
if [ ! -d "${HOME}/.nano" ]; then
    mkdir -p "${HOME}/.nano"

    # Download the nano syntax highlighting files
    wget -O /tmp/nanorc.zip https://github.com/scopatz/nanorc/archive/master.zip

    cd "${HOME}/.nano/" || exit

    unzip -o "/tmp/nanorc.zip"
    mv nanorc-master/* ./
    rm -rf nanorc-master
    rm /tmp/nanorc.zip
fi
