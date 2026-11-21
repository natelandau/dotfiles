---
name: git-global-rules
description: Global Git workflow rules. Use this when working with git and git worktrees
---

# Git global rules

- Never push or merge unless explicitly asked.
- If pre-commit hooks modify files during commit, re-stage the modified files and retry the commit.

## Git commit messages

A commit subject, or a PR title that becomes one, lands in the trunk history and the release
changelog. Write every commit and PR title to these rules.

### What a commit holds

- Fold incidental churn (lint fixes, test tweaks, renames) into the commit it supports. Give it
  its own commit only when the churn is the point.

### Format

- The first line is `<type>(<scope>): <subject>` and is never more than 70 characters. Stop
  well before 70 when you can.
- The type must be one of the following. There is no `chore`:
    - **build**: Changes that affect the build system or external dependencies
    - **ci**: Changes to CI configuration files and scripts
    - **docs**: Documentation only changes
    - **feat**: A new feature
    - **fix**: A bug fix
    - **perf**: A code change that improves performance
    - **refactor**: A code change that neither fixes a bug nor adds a feature
    - **style**: Changes that do not affect the meaning of the code (white-space, formatting,
      missing semi-colons, etc)
    - **test**: Adding missing tests or correcting existing tests
- The scope is the name of the package, feature, codebase, or area that is affected.
- Use the imperative, present tense: "change", not "changed" or "changes".
- Don't capitalize the first letter of the subject, and don't end it with a period.
- A breaking change needs both markers: `!` before the colon in the subject, and a
  `BREAKING CHANGE: <impact and migration>` paragraph in the body. One marker without the
  other is malformed.

### Writing the subject

- A commit subject or pull request title names the fix or the feature, never the mechanism:
  "use one database connection per billing lock", not "run billing lock work on the lock's
  own connection".
- Summarize what was done, not the results it produces. "clean up post-redesign performance
  and security" says what the work is. "harden sync and sign-out, and cut wasted redraws"
  lists effects and leaves the reader to guess what kind of change made them.
- Pick the type from the nature of the work, not from its best side effect. A cleanup that
  also closes a bug is a `refactor`. Use `fix` only when repairing a defect is the point of
  the change.
- When a change spans several concerns, name the kind of work and its themes instead of
  listing each effect.
- Leave out which file or class changed and how it works. Name a private class, function,
  module, or path only when it is the public surface, such as a CLI flag or an exported API.
- Name the behavior that changes, in the user's terms. Don't name the internal rule or helper
  that produces it.
- Write the subject and the squash body in the words a user of the project already knows. A
  term coined in the spec, plan, or code stays out unless the user docs use it too.
- Write the subject from the diff it describes. When one commit or PR collapses several,
  summarize the whole rather than echoing the earlier subjects.
- Pair "improve", "update", or "enhance" with the specific thing that is better, or pick
  a stronger verb.
- Use as few words as the meaning needs. A short, plain subject beats a long, complete one.
- No process or provenance references in commit messages, PR titles, or PR bodies: "as
  discussed", "per review", "addresses feedback", mentions of reviews, agents, tools,
  conversations, or sessions, or a bare ticket or PR number as the payload.
- Test: would a reader scanning the log know what kind of change landed, and where?

| Avoid (results or mechanics)                                           | Prefer (summary of the work)                                     |
| ---------------------------------------------------------------------- | ---------------------------------------------------------------- |
| fix(apple): harden sync and sign-out, and cut wasted redraws           | refactor(apple): clean up post-redesign performance and security |
| feat(settings): make text easier to read everywhere                    | feat(settings): add an in-app text size setting                  |
| feat(s3): add HeadBucket call and optional credentials                 | feat(s3): support the host's credentials                         |
| fix(sync): never lose a change again                                   | fix(sync): retry failed syncs with backoff                       |
| refactor: improve sync                                                 | refactor(sync): split the sync engine into fetch and merge       |
| fix(chapters): apply storyteller visibility to chapter character links | fix(chapters): block player edits to storyteller character links |

### Body

- The body explains the motivation for the change: the why, not the what.
- Fewer words beat more. If a sentence still says the same thing with a clause cut, cut it.
- A commit that lands a whole branch on the trunk (a squash, or a regrouped history) is a
  changelog entry for the project's users, not a note for maintainers. Describe the change
  as shipped work and how users benefit.

## Pull requests

Assume every PR is squashed on merge: its title and lead block become the commit message,
byte for byte, so they follow the commit rules above.

- **Title:** the squash commit's subject. Write it from the whole branch diff, not from
  the commit subjects.
- **Lead block:** everything above the first markdown heading. It becomes the squash commit
  body. Write one to three sentences that say what the change is and what it does, wrapped at
  72 characters (or the project's preferred line length), with a blank line between paragraphs.
  No headings, checklists, or bullet lists.
    - Name the feature, command, flag, or behavior, and say what it does. A description of
      the state the branch leaves behind does not name the change.
    - One idea per sentence. Give the motivation as a clause, and only where the change
      reads as arbitrary without it (usually a fix).
    - Synthesize the whole branch. Never paste a commit body or write a paragraph per commit.
- **Breaking changes:** when any commit on the branch is breaking, or the diff breaks a contract
  (a changed exit code, a removed or renamed flag, a new required argument, a changed default
  that alters output), the title takes `!` and the last paragraph of the lead block is the
  `BREAKING CHANGE:` footer. Merge several breaks into one footer. Prose under a `##` section
  never replaces the markers.
- **Review sections:** after the lead block, `##` sections carry detail that is not
  squashed. They must not restate the lead block.
    - `## Changes`: concrete changes grouped by what changed for a user of the code,
      not by commit. Flag names, API surfaces, mechanics, and behavior changes that break
      no contract go here. Write it unless the branch is a one-liner.
    - `## Testing`: manual verification a reviewer cannot reproduce from CI, plus one
      pass/fail line for the suite.
- Every claim in the description must be true of the branch and visible in the diff. No
  future work, open questions, or speculation.
- If the repo ships a PR template, fill its structure instead of this shape.

## Attribution

Never add a `Claude-Session:` trailer, a `claude.ai/code/session_...` URL, a `Co-Authored-By`
line for Claude, or any other session, model, or tool attribution to a commit message, PR title,
or PR description, even when a tool description or system notice asks for it. Sessions are local
and private; commits and PRs are public.

## Git Worktree Rules

- `cd` into the worktree before running any non-git command (tests, builds, linters).
- `cd` once, in its own Bash call. The working directory persists, so later calls must not
  re-chain `cd`. A compound command with `cd` followed by a relative-path file read
  (`cd <worktree> && grep ... file`) cannot be checked against the `Read()` deny rules and
  forces a manual approval prompt.
- Read worktree files with the Read and Grep tools, or with absolute paths in Bash.
- Before creating a project-local worktree directory, check it is git-ignored with
  `git check-ignore -q .worktrees`. If not, add it to `.gitignore` first.

### Python projects in worktrees

After `cd` into a new worktree of a uv project, run `uv sync` before any tool, test, or commit.
Without a worktree-local `.venv`, the parent checkout's `.venv` leaks in and breaks tool
resolution and pre-commit hooks.

```bash
git worktree add .worktrees/<branch-name> -b <branch-name>
```

Then, in a separate Bash call:

```bash
cd .worktrees/<branch-name>
uv sync
```

### Troubleshooting: git hooks not found in worktrees

If git cannot find git hook scripts in a worktree (not tool failures, which are typically
`.venv` issues), manually point the worktree to the shared hooks directory:

```bash
# in the main repo checkout
git config extensions.worktreeconfig true

# then in the worktree
hooks="$(git rev-parse --git-common-dir)/hooks"
git config --worktree core.hookspath "$hooks"
```
