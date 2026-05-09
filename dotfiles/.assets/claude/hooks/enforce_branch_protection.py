#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.14"
# dependencies = []
# ///

"""PreToolUse hook: blocks destructive git commands and file modifications.

Blocks destructive git operations (force push, hard reset, clean -f, etc.)
on ALL branches, and blocks file modifications on protected branches
(main/master). Supports git worktrees by checking the branch at the actual
target location.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

PROTECTED_BRANCHES = {"main", "master"}
COMPOUND_SPLIT = r"\s*(?:&&|\|\||;)\s*"

# Single hint appended to every protected-branch block message. Both
# file-modifying tools (Edit/Write/NotebookEdit) and file-modifying bash
# commands point at the same remediation, so the text lives in one place.
PROTECTED_BRANCH_HINT = (
    "Create a new branch first:\n"
    "  git checkout -b <branch-name>\n"
    "Or use a worktree for isolated work:\n"
    "  git worktree add .worktrees/<branch-name> -b <branch-name>"
)

GIT_C_ADVISORY = (
    "WARNING: Avoid using `git -C <path>`. "
    "Check your current working directory and `cd` into the correct "
    "directory first, then run `git` directly. "
    "Only fall back to `git -C` if direct `git` fails."
)
GIT_C_RE = re.compile(r"\bgit\s+-C\b")


@dataclass(frozen=True, slots=True)
class Rule:
    r"""Declarative command-matching rule.

    `pattern` is a regex tested against each compound sub-part of a command
    by default (split on `&&`, `||`, `;`). Set `match_full=True` to test
    against the entire command string instead -- needed for patterns that
    span operators (e.g. output redirects).

    `reason` is shown to the user when a DESTRUCTIVE rule blocks. For
    PROTECTED_FILE_MOD rules the message is always `PROTECTED_BRANCH_HINT`,
    so `reason` is optional.

    `exclude` is a regex that, if it also matches, negates the rule. Use
    for safe variants (e.g. `--dry-run`).

    Example::

        Rule(
            pattern=r"^\\s*git\\s+stash\\s+drop\\b",
            reason="git stash drop permanently discards stashed changes",
        )
    """

    pattern: str
    reason: str = ""
    match_full: bool = False
    exclude: str | None = None


# === RULE DEFINITIONS ===
#
# To add a rule, append a Rule(...) to the appropriate tuple below.
# See the Rule docstring above for field semantics and a syntax example.
#
# DESTRUCTIVE_RULES        -- blocked on every branch; `reason` is shown.
# PROTECTED_FILE_MOD_RULES -- blocked only on main/master; the user always
#                             sees PROTECTED_BRANCH_HINT, so `reason` may
#                             be omitted.

DESTRUCTIVE_RULES: tuple[Rule, ...] = (
    Rule(
        pattern=r"^\s*git\s+push\b.*(?:--force\b|--force-with-lease\b|\s-[a-zA-Z]*f)",
        reason="Force push rewrites remote history and can destroy others' work",
    ),
    Rule(
        pattern=r"^\s*git\s+push\b.*\s\+\S",
        reason="Force push via refspec (+ref) rewrites remote history",
    ),
    Rule(
        pattern=r"^\s*git\s+reset\b.*--hard\b",
        reason="git reset --hard destroys uncommitted changes irrecoverably",
    ),
    Rule(
        pattern=r"^\s*git\s+clean\b.*-[a-zA-Z]*f",
        reason="git clean -f permanently deletes untracked files",
        exclude=r"-[a-zA-Z]*n|--dry-run",
    ),
    Rule(
        pattern=r"^\s*git\s+checkout\s+(--\s+)?\.(\s|$)",
        reason="git checkout . discards all unstaged changes",
    ),
    Rule(
        pattern=r"^\s*git\s+restore\b.*\s\.(\s|$)",
        reason="git restore . discards all working tree changes",
    ),
    Rule(
        pattern=r"^\s*git\s+rebase\b.*--no-verify\b",
        reason="git rebase --no-verify bypasses safety hooks",
    ),
    Rule(
        pattern=r"^\s*git\s+branch\s+-D\s+main(\s|$)",
        reason="Force-deleting the protected branch 'main' is not allowed",
    ),
    Rule(
        pattern=r"^\s*git\s+branch\s+-D\s+master(\s|$)",
        reason="Force-deleting the protected branch 'master' is not allowed",
    ),
)

PROTECTED_FILE_MOD_RULES: tuple[Rule, ...] = (
    Rule(pattern=r"^\s*(rm|rmdir|mv|cp|touch|mkdir|chmod|chown|ln|install)\b"),
    Rule(pattern=r"\bsed\b.*\s-i"),
    Rule(pattern=r"\bperl\b.*\s-i"),
    Rule(pattern=r"\bcurl\b.*\s-[oO]\b"),
    Rule(pattern=r"^\s*wget\b"),
    Rule(pattern=r"\btee\b"),
    Rule(pattern=r"(?<![>&])\s*>(?!&)", match_full=True),
)


# === Helpers ===


def _run_git(*args: str, cwd: str | None = None) -> str:
    """Run a git command and return stripped stdout."""
    cmd = ["git"]
    if cwd:
        cmd.extend(["-C", cwd])
    cmd.extend(args)
    try:
        result = subprocess.run(  # noqa: S603
            cmd, capture_output=True, text=True, timeout=5, check=False
        )
        return result.stdout.strip()
    except (subprocess.SubprocessError, FileNotFoundError):
        return ""


def _resolve_dir(path: str) -> Path | None:
    """Resolve a file or directory path to its nearest existing parent directory."""
    p = Path(path)
    dir_path = p if p.is_dir() else p.parent

    while dir_path != dir_path.parent and not dir_path.is_dir():
        dir_path = dir_path.parent

    return dir_path if dir_path.is_dir() else None


def _block(msg: str) -> None:
    """Print BLOCKED-prefixed message to stderr and exit 2."""
    print(f"BLOCKED: {msg}", file=sys.stderr)  # noqa: T201
    sys.exit(2)


def _allow(advisory: str | None = None) -> None:
    """Print optional advisory to stdout and exit 0."""
    if advisory:
        print(advisory)  # noqa: T201
    sys.exit(0)


def _split_compound(command: str) -> list[str]:
    """Split a compound bash command on &&, ||, and ;."""
    return re.split(COMPOUND_SPLIT, command)


def _is_git_command(part: str) -> bool:
    """Check if a command part is a git or gh command."""
    return bool(re.match(r"^\s*(git|gh)\b", part))


def _is_excluded(rule: Rule, text: str) -> bool:
    """Check if a rule's exclude pattern matches, negating the rule."""
    return bool(rule.exclude and re.search(rule.exclude, text))


def match_rules(
    command: str, rules: tuple[Rule, ...], *, skip_git_parts: bool = False
) -> str | None:
    """Return the first matching rule's reason, or None.

    For per-part rules, split the command on compound operators and test
    each sub-part. For full-command rules, test the entire string.

    Args:
        command: The bash command string to check.
        rules: The rule tuple to match against.
        skip_git_parts: Skip sub-command parts that start with git/gh.
    """
    for rule in rules:
        if rule.match_full:
            if re.search(rule.pattern, command) and not _is_excluded(rule, command):
                return rule.reason
        else:
            for part in _split_compound(command):
                stripped = part.strip()
                if not stripped:
                    continue
                if skip_git_parts and _is_git_command(stripped):
                    continue
                if re.search(rule.pattern, stripped) and not _is_excluded(rule, stripped):
                    return rule.reason
    return None


# === Branch / git-context detection ===


def get_branch_at_path(path: str) -> str:
    """Get the git branch for the repo or worktree containing the given path."""
    dir_path = _resolve_dir(path)
    if not dir_path:
        return ""
    return _run_git("branch", "--show-current", cwd=str(dir_path))


def get_effective_branch(data: dict[str, Any]) -> str:
    """Determine the effective git branch based on tool context.

    For file tools (Edit/Write/NotebookEdit), check the branch at the
    file's location so edits inside a worktree are correctly allowed.
    Falls back to the session's cwd, then the hook process's own cwd.
    """
    tool_name: str = data.get("tool_name", "")
    tool_input: dict[str, Any] = data.get("tool_input", {})
    cwd: str = data.get("cwd", "")

    if tool_name in ("Edit", "Write", "NotebookEdit"):
        file_path = tool_input.get("file_path", "") or tool_input.get("notebook_path", "")
        if file_path:
            return get_branch_at_path(file_path)

    if cwd:
        branch = get_branch_at_path(cwd)
        if branch:
            return branch

    return _run_git("branch", "--show-current")


def _git_dir(cwd: str) -> Path | None:
    """Return absolute git-dir for cwd, or None outside a repo."""
    raw = _run_git("rev-parse", "--git-dir", cwd=cwd)
    if not raw:
        return None
    return Path(raw) if Path(raw).is_absolute() else (Path(cwd) / raw)


def is_in_linked_worktree(cwd: str, git_dir: Path) -> bool:
    """Check if cwd is a linked worktree (not the main repo checkout).

    Compare git-dir to git-common-dir: in a linked worktree git-dir
    points to .git/worktrees/<name> while git-common-dir points to .git/.
    """
    common_dir_raw = _run_git("rev-parse", "--git-common-dir", cwd=cwd)
    if not common_dir_raw:
        return False
    common_dir = (
        Path(common_dir_raw) if Path(common_dir_raw).is_absolute() else Path(cwd) / common_dir_raw
    )
    return git_dir.resolve() != common_dir.resolve()


def is_squash_merge_in_progress(command: str, git_dir: Path | None) -> bool:
    """Detect an in-progress squash merge.

    Two signals:
    1. SQUASH_MSG exists in the git dir (left by a prior `git merge --squash`)
    2. The command itself contains `git merge --squash` before `git commit`
    """
    if git_dir and (git_dir / "SQUASH_MSG").exists():
        return True

    squash_seen = False
    for raw_part in _split_compound(command):
        stripped = raw_part.strip()
        if re.match(r"^\s*git\s+merge\s+--squash\b", stripped):
            squash_seen = True
        if re.match(r"^\s*git\s+commit\b", stripped) and squash_seen:
            return True
    return False


# === Checks ===


def check_destructive(command: str) -> str | None:
    """Return a block reason if the command is destructive, else None."""
    return match_rules(command, DESTRUCTIVE_RULES)


def _contains_git_commit(command: str) -> bool:
    """Check if any sub-part is a `git commit`."""
    return any(re.match(r"^\s*git\s+commit\b", p) for p in _split_compound(command))


def _is_pure_git_command(command: str) -> bool:
    """Check if every sub-part is a git/gh subcommand."""
    if not _is_git_command(command):
        return False
    return all(_is_git_command(p) or not p.strip() for p in _split_compound(command))


def _targets_only_tmp(command: str) -> bool:
    """Check if all file arguments in non-git parts reference /tmp/."""
    for part in _split_compound(command):
        stripped = part.strip()
        if not stripped or _is_git_command(stripped):
            continue
        tokens = stripped.split()
        file_args = [t for t in tokens[1:] if not t.startswith("-")]
        if not file_args:
            return False
        if not all(a.startswith("/tmp/") for a in file_args):  # noqa: S108
            return False
    return True


def check_protected_branch(data: dict[str, Any], branch: str) -> str | None:
    """Return a block reason if the action is forbidden on the protected branch."""
    tool_name: str = data.get("tool_name", "")
    tool_input: dict[str, Any] = data.get("tool_input", {})
    cwd: str = data.get("cwd", "")

    if tool_name in ("Edit", "Write", "NotebookEdit"):
        return f"Cannot modify files on the '{branch}' branch. {PROTECTED_BRANCH_HINT}"

    if tool_name != "Bash":
        return None

    command: str = tool_input.get("command", "")

    if _contains_git_commit(command):
        git_dir = _git_dir(cwd) if cwd else None
        in_worktree = is_in_linked_worktree(cwd, git_dir) if git_dir else False
        is_squash = is_squash_merge_in_progress(command, git_dir)
        if not in_worktree and not is_squash:
            return f"Cannot commit directly to the '{branch}' branch. {PROTECTED_BRANCH_HINT}"

    if _is_pure_git_command(command) or _targets_only_tmp(command):
        return None

    if match_rules(command, PROTECTED_FILE_MOD_RULES, skip_git_parts=True) is not None:
        return f"Cannot modify files on the '{branch}' branch. {PROTECTED_BRANCH_HINT}"

    return None


def main() -> None:
    """Entry point for the PreToolUse hook."""
    try:
        data: dict[str, Any] = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        sys.exit(0)

    tool_name: str = data.get("tool_name", "")
    command: str = data.get("tool_input", {}).get("command", "") if tool_name == "Bash" else ""

    if tool_name == "Bash":
        reason = check_destructive(command)
        if reason:
            _block(f"{reason}. Run this command outside Claude Code if you must.")

    branch = get_effective_branch(data)
    if branch in PROTECTED_BRANCHES:
        reason = check_protected_branch(data, branch)
        if reason:
            _block(reason)

    advisory = GIT_C_ADVISORY if tool_name == "Bash" and GIT_C_RE.search(command) else None
    _allow(advisory)


if __name__ == "__main__":
    main()
