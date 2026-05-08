#!/usr/bin/env bash

ruff_args=(
    "--fix"
    "--target-version=py313"
    "--select=ALL"
    "--ignore=ANN204,B006,B008,COM812,CPY001,D107,D213,E501,FIX002,TD002,TD003,UP007,D211"
    "--unfixable=ERA001,F401,F841"
)

format_args=(
    --target-version=py313
    --line-length=100
)

uvx ruff format "${format_args[@]}" "$@"
uvx ruff check "${ruff_args[@]}" "$@"
