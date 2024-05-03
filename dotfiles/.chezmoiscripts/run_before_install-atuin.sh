#!/usr/bin/env bash

# This script installs the Atuin binary for better history browsing
# https://docs.atuin.sh/

# check for unzip before we continue
if [ ! "$(command -v curl)" ]; then
    echo 'curl is required but was not found. Install curl first and then run this script again.' >&2
    exit 1
fi

if [ ! "$(command -v unzip)" ]; then
    curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | bash
fi
