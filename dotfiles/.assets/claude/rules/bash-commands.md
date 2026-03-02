---
name: bash-commands
description: Rules for running bash commands in a shell.
---

## Bash command rules

- Never use `echo "---"` or similar echo statements containing sequences of dashes (`---`, `----`, etc.) as success markers or separators in bash commands. These trigger security warnings in Claude Code. Instead, use plain words like `echo "Done"` or `echo "OK"`.
