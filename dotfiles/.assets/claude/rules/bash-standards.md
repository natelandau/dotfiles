---
name: Bash style and standards
description: How to write Bash scripts
paths:
    - "**/*.sh"
    - "**/*.bash"
    - "**/*.zsh"
---

## Bash style and standards

- Use parameter expansion for string work (substrings, prefix/suffix removal, replacement), not
  `sed` or `awk`, unless the task needs a regex or multi-line processing.
- Use `[[ ]]`, not `[ ]`, for tests.
- Quote every variable expansion.
- Use `$(command)`, not backticks.
- No `eval`.
- Declare function variables with `local`. Keep globals to configuration and constants.
- Use `set -e` and check the exit status of commands whose failure the script handles itself.
  Exit or return as soon as an error is detected.
- Use `printf`, not `echo`, for output.
- Create temporary files with `mktemp` and remove them on exit with a `trap`.
- Split a long pipeline into steps with named intermediate variables.
