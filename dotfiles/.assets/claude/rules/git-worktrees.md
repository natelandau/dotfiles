---
name: git-worktrees
description: Git worktree workflow rules
---
## Git Worktree Rules

When working with git worktrees, follow these rules:

1. **Always `cd` into the worktree directory** before running any non-git commands (tests, builds, linters, etc.). The bash-command-guard hook checks the branch of the current working directory - running commands from the main repo on `main` will be blocked even if the target is a worktree.
2. Use `.worktrees/` (hidden, project-local) as the default worktree directory. If it doesn't exist, check for `worktrees/`. If neither exists, ask before creating one.
3. Before creating a project-local worktree directory, verify it is git-ignored with `git check-ignore -q .worktrees`. If not ignored, add it to `.gitignore` first.
4. Create worktrees with: `git worktree add .worktrees/<branch-name> -b <branch-name>`
5. After creating a worktree, `cd` into it immediately and run the project's dependency install and test suite to verify a clean baseline before starting work.
6. When finished with a worktree, use `git worktree remove <path>` to clean up. Never manually delete worktree directories.
7. To list active worktrees: `git worktree list`
