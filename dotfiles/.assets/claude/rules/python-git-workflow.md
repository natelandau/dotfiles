---
name: python-git-workflow
description: Python Git workflow rules
---
## Git Workflow for Python projects

1. After each file edit, immediately run `ruff check <file> --fix` and `ruff format <file>` on that specific file.
2. Before any git commit, run the full validation sequence: `ruff check . --fix && ruff format . && pytest -x --tb=short`
3. If pre-commit hooks modify files during commit, re-stage the modified files and retry the commit - do NOT use `git stash` as it causes conflicts with the pre-commit pytest hook.
4. If a test fails due to changed error messages or output format, check the source code for the actual error string rather than guessing.
5. For git operations, always use `git commit --no-verify` only as a last resort, and document why in the commit body.
6. Never claim a file is updated without re-reading it to verify the changes persisted.

Apply this workflow to all tasks in this session.
