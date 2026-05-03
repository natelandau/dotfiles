---
name: git-global-rules
description: Global Git workflow rules. Use this when working with git and git worktrees
---

# Git global rules

- Never push or merge unless explicitly asked
- If pre-commit hooks modify files during commit, re-stage the modified files and retry the commit

## Git commit messages

- The first line of the commit should never be more than 70 characters
- Each commit message consists of a header and a body. The header has a special format that includes a type, an optional scope and a subject: `<type>(<scope>): <subject>`
- The types must be one of the following. No exceptions:
    - **build**: Changes that affect the build system or external dependencies
    - **ci**: Changes to CI configuration files and scripts
    - **docs**: Documentation only changes
    - **feat**: A new feature
    - **fix**: A bug fix
    - **perf**: A code change that improves performance
    - **refactor**: A code change that neither fixes a bug nor adds a feature
    - **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
    - **test**: Adding missing tests or correcting existing tests
- The scope should be the name of the package, feature, codebase, or area that is affected
- Use the imperative, present tense: "change" not "changed" nor "changes"
- Don't capitalize the first letter of the subject
- No dot (.) at the end of the subject
- The body explains the motivation for the change. Explain the WHY not the WHAT.

## Git Worktree Rules

- **Always `cd` into the worktree directory** before running any non-git commands (tests, builds, linters, etc.).
- Use `{project-folder}/.worktrees/` as the default worktree directory.
- Before creating a project-local worktree directory, verify it is git-ignored with `git check-ignore -q .worktrees`. If not ignored, add it to `.gitignore` first.
- Create worktrees with: `git worktree add .worktrees/<branch-name> -b <branch-name>`
- After creating a worktree, `cd` into it immediately and run the project's dependency install and test suite to verify a clean baseline before starting work.
- When finished with a worktree, use `git worktree remove <path>` to clean up. Never manually delete worktree directories.

### Python projects in worktrees

The parent project's `.venv` can leak into worktrees nested under `{project}/.worktrees/`, causing tool resolution failures and broken pre-commit hooks. After `cd`-ing into a new worktree for a Python/uv project, **always run `uv sync`** to create a worktree-local `.venv` before running any tools, tests, or commits. This ensures pre-commit hooks (ruff, pytest, etc.) resolve to the correct environment.

```bash
git worktree add .worktrees/<branch-name> -b <branch-name>
cd .worktrees/<branch-name>
uv sync
```

### Troubleshooting: hooks not found in worktrees

If git cannot find hook scripts in a worktree (not tool failures — those are typically `.venv` issues), manually point the worktree to the shared hooks directory:

```bash
# in the main repo checkout
git config extensions.worktreeconfig true

# then in the worktree
hooks="$(git rev-parse --git-common-dir)/hooks"
git config --worktree core.hookspath "$hooks"
```
