#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.14"
# dependencies = []
# ///

r"""PreToolUse hook: blocks destructive git commands and file modifications.

Blocks destructive git operations (force push, hard reset, clean -f, etc.)
on ALL branches, and blocks file modifications on protected branches
(main/master). Supports git worktrees by checking the branch at the actual
target location.

Adding / editing / removing rules
==================================

All command-matching patterns live in the ``RULES`` tuple below. Each entry
is a ``Rule`` dataclass with the following fields:

    category     RuleCategory enum value:
                   DESTRUCTIVE        - blocked on ALL branches
                   PROTECTED_FILE_MOD - blocked on protected branches only
                   WARNING            - non-blocking, printed to stdout
    pattern      Regex tested against each sub-part of a compound command
                 (split on ``&&``, ``||``, ``;``).
    reason       Human-readable message shown when the rule triggers.
                 For DESTRUCTIVE rules this is included in the block output.
                 For PROTECTED_FILE_MOD rules the caller supplies a
                 branch-specific message, so this is only for documentation.
                 For WARNING rules this is printed to stdout verbatim.
    match_full   (default False) When True, test ``pattern`` against the
                 entire command string instead of each sub-part. Use for
                 patterns that span operators (e.g. output redirects).
    exclude      (default None) A regex that, if it also matches, negates
                 the rule. Use for safe variants (e.g. ``--dry-run``).

To add a new rule, append a ``Rule(...)`` to the appropriate section of
``RULES``. Example — block ``git stash drop``::

    Rule(
        category=RuleCategory.DESTRUCTIVE,
        pattern=r"^\\s*git\\s+stash\\s+drop\\b",
        reason="git stash drop permanently discards stashed changes",
    ),

No changes to the checker classes are needed.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Any

PROTECTED_BRANCHES = {"main", "master"}
COMPOUND_SPLIT = r"\s*(?:&&|\|\||;)\s*"


class RuleCategory(Enum):
    """Categories that determine when and how a rule is enforced."""

    DESTRUCTIVE = "destructive"
    PROTECTED_FILE_MOD = "protected_file_mod"
    WARNING = "warning"


@dataclass(frozen=True, slots=True)
class Rule:
    """Declarative command-matching rule.

    Define a regex pattern, the category it belongs to, and a human-readable
    reason. Use `exclude` to negate matches (e.g. allow dry-run variants).
    Use `match_full=True` to test against the entire compound command instead
    of each sub-part.
    """

    category: RuleCategory
    pattern: str
    reason: str
    match_full: bool = False
    exclude: str | None = None


RULES: tuple[Rule, ...] = (
    # === Destructive commands (blocked on ALL branches) ===
    Rule(
        category=RuleCategory.DESTRUCTIVE,
        pattern=r"^\s*git\s+push\b.*(?:--force\b|--force-with-lease\b|-[a-zA-Z]*f)",
        reason="Force push rewrites remote history and can destroy others' work",
    ),
    Rule(
        category=RuleCategory.DESTRUCTIVE,
        pattern=r"^\s*git\s+reset\b.*--hard\b",
        reason="git reset --hard destroys uncommitted changes irrecoverably",
    ),
    Rule(
        category=RuleCategory.DESTRUCTIVE,
        pattern=r"^\s*git\s+clean\b.*-[a-zA-Z]*f",
        reason="git clean -f permanently deletes untracked files",
        exclude=r"-[a-zA-Z]*n|--dry-run",
    ),
    Rule(
        category=RuleCategory.DESTRUCTIVE,
        pattern=r"^\s*git\s+checkout\s+(--\s+)?\.(\s|$)",
        reason="git checkout . discards all unstaged changes",
    ),
    Rule(
        category=RuleCategory.DESTRUCTIVE,
        pattern=r"^\s*git\s+restore\b.*\s\.(\s|$)",
        reason="git restore . discards all working tree changes",
    ),
    Rule(
        category=RuleCategory.DESTRUCTIVE,
        pattern=r"^\s*git\s+rebase\b.*--no-verify\b",
        reason="git rebase --no-verify bypasses safety hooks",
    ),
    Rule(
        category=RuleCategory.DESTRUCTIVE,
        pattern=r"^\s*git\s+branch\s+-D\s+main(\s|$)",
        reason="Force-deleting the protected branch 'main' is not allowed",
    ),
    Rule(
        category=RuleCategory.DESTRUCTIVE,
        pattern=r"^\s*git\s+branch\s+-D\s+master(\s|$)",
        reason="Force-deleting the protected branch 'master' is not allowed",
    ),
    # === File-modifying commands (blocked on protected branches only) ===
    Rule(
        category=RuleCategory.PROTECTED_FILE_MOD,
        pattern=r"^\s*(rm|rmdir|mv|cp|touch|mkdir|chmod|chown|ln|install)\b",
        reason="file system command",
    ),
    Rule(
        category=RuleCategory.PROTECTED_FILE_MOD,
        pattern=r"\bsed\b.*\s-i",
        reason="in-place sed edit",
    ),
    Rule(
        category=RuleCategory.PROTECTED_FILE_MOD,
        pattern=r"\bperl\b.*\s-i",
        reason="in-place perl edit",
    ),
    Rule(
        category=RuleCategory.PROTECTED_FILE_MOD,
        pattern=r"\bcurl\b.*\s-[oO]\b",
        reason="curl file download",
    ),
    Rule(
        category=RuleCategory.PROTECTED_FILE_MOD,
        pattern=r"^\s*wget\b",
        reason="wget file download",
    ),
    Rule(
        category=RuleCategory.PROTECTED_FILE_MOD,
        pattern=r"\btee\b",
        reason="tee file write",
    ),
    Rule(
        category=RuleCategory.PROTECTED_FILE_MOD,
        pattern=r"(?<![>&])\s*>(?!&)",
        reason="output redirect",
        match_full=True,
    ),
    # === Warnings (non-blocking, all branches) ===
    Rule(
        category=RuleCategory.WARNING,
        pattern=r"\bgit\s+-C\b",
        reason=(
            "WARNING: Avoid using `git -C <path>`. "
            "Check your current working directory and `cd` into the correct "
            "directory first, then run `git` directly. "
            "Only fall back to `git -C` if direct `git` fails."
        ),
        match_full=True,
    ),
)


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
    """Print a blocked message to stderr and exit with code 2."""
    print(msg, file=sys.stderr)  # noqa: T201
    sys.exit(2)


def _allow(warnings: list[str] | None = None) -> None:
    """Print any collected warnings to stdout and exit with code 0."""
    if warnings:
        print("\n".join(warnings))  # noqa: T201
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
    command: str, category: RuleCategory, *, skip_git_parts: bool = False
) -> str | None:
    """Check a command against all rules in the given category.

    Iterate over RULES filtered by category. For per-part rules, split the
    command on compound operators and test each sub-part. For full-command
    rules, test the entire string.

    Args:
        command: The bash command string to check.
        category: Only rules with this category are tested.
        skip_git_parts: Skip sub-command parts that start with git/gh.

    Returns:
        The reason string from the first matching rule, or None.
    """
    for rule in RULES:
        if rule.category is not category:
            continue

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


def get_branch_at_path(path: str) -> str:
    """Get the git branch for the repo or worktree containing the given path.

    Resolve to the nearest existing parent directory, then ask git for the
    current branch. Inside a worktree this returns the worktree's branch,
    not the main repo's branch.
    """
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

    # For file tools, check branch at the file's location
    if tool_name in ("Edit", "Write", "NotebookEdit"):
        file_path = tool_input.get("file_path", "") or tool_input.get("notebook_path", "")
        if file_path:
            branch = get_branch_at_path(file_path)
            if branch:
                return branch

    # Fall back to session working directory (reflects cd into worktree)
    if cwd:
        branch = get_branch_at_path(cwd)
        if branch:
            return branch

    # Last resort: hook process's own cwd
    return _run_git("branch", "--show-current")


def is_in_linked_worktree(cwd: str) -> bool:
    """Check if cwd is a linked worktree (not the main repo checkout).

    Compare git-dir to git-common-dir: in a linked worktree git-dir
    points to .git/worktrees/<name> while git-common-dir points to .git/.
    """
    git_dir_raw = _run_git("rev-parse", "--git-dir", cwd=cwd)
    common_dir_raw = _run_git("rev-parse", "--git-common-dir", cwd=cwd)
    if not git_dir_raw or not common_dir_raw:
        return False

    base = Path(cwd)
    git_dir = Path(git_dir_raw) if Path(git_dir_raw).is_absolute() else base / git_dir_raw
    common_dir = (
        Path(common_dir_raw) if Path(common_dir_raw).is_absolute() else base / common_dir_raw
    )
    return git_dir.resolve() != common_dir.resolve()


def is_squash_merge_in_progress(cwd: str, command: str) -> bool:
    """Detect an in-progress squash merge.

    Check two signals:
    1. SQUASH_MSG exists in the git dir (left by a prior `git merge --squash`)
    2. The command chain itself contains `git merge --squash` before `git commit`
    """
    git_dir_raw = _run_git("rev-parse", "--git-dir", cwd=cwd)
    if git_dir_raw:
        base = Path(cwd)
        git_dir = Path(git_dir_raw) if Path(git_dir_raw).is_absolute() else base / git_dir_raw
        if (git_dir / "SQUASH_MSG").exists():
            return True

    # Check if git merge --squash precedes git commit in the same command
    squash_seen = False
    for raw_part in _split_compound(command):
        stripped = raw_part.strip()
        if re.match(r"^\s*git\s+merge\s+--squash\b", stripped):
            squash_seen = True
        if re.match(r"^\s*git\s+commit\b", stripped) and squash_seen:
            return True

    return False


class WarningChecker:
    """Collect non-blocking warnings for any tool invocation."""

    def __init__(self, data: dict[str, Any]) -> None:
        self._tool_name: str = data.get("tool_name", "")
        self._command: str = data.get("tool_input", {}).get("command", "")

    def check(self) -> list[str]:
        """Return all applicable warning messages."""
        warnings: list[str] = []
        if self._tool_name == "Bash":
            reason = match_rules(self._command, RuleCategory.WARNING)
            if reason:
                warnings.append(reason)
        return warnings


class DestructiveCommandChecker:
    """Block destructive git operations on any branch."""

    def __init__(self, command: str) -> None:
        self._command = command

    def check(self) -> str | None:
        """Return a block reason if the command is destructive, or None if safe."""
        return match_rules(self._command, RuleCategory.DESTRUCTIVE)


class ProtectedBranchGuard:
    """Block file modifications and commits on protected branches."""

    def __init__(self, data: dict[str, Any], branch: str) -> None:
        self._tool_name: str = data.get("tool_name", "")
        tool_input: dict[str, Any] = data.get("tool_input", {})
        self._command: str = tool_input.get("command", "")
        self._cwd: str = data.get("cwd", "")
        self._branch = branch

    def check(self) -> str | None:
        """Return a block reason if the action is forbidden, or None if allowed."""
        reason = self._check_file_tools()
        if reason:
            return reason

        if self._tool_name == "Bash":
            return self._check_bash()

        return None

    def _check_file_tools(self) -> str | None:
        """Block Edit/Write/NotebookEdit on protected branches."""
        if self._tool_name in ("Edit", "Write", "NotebookEdit"):
            return (
                f"Cannot modify files on the '{self._branch}' branch. "
                "Create a new branch first:\n"
                "  git checkout -b <branch-name>\n"
                "Or use a worktree for isolated work:\n"
                "  git worktree add .worktrees/<branch-name> -b <branch-name>"
            )
        return None

    def _check_bash(self) -> str | None:
        """Orchestrate bash-specific checks on protected branches."""
        reason = self._check_git_commit()
        if reason:
            return reason

        if self._is_pure_git_command():
            return None

        return self._check_file_modifying_command()

    def _check_git_commit(self) -> str | None:
        """Block git commit unless in a worktree or squash merge."""
        if not self._contains_git_commit():
            return None

        in_worktree = is_in_linked_worktree(self._cwd) if self._cwd else False
        is_squash = is_squash_merge_in_progress(self._cwd, self._command) if self._cwd else False

        if not in_worktree and not is_squash:
            return (
                f"Cannot commit directly to the '{self._branch}' branch. "
                "Create a new branch first:\n"
                "  git checkout -b <branch-name>\n"
                "Or use a worktree for isolated work:\n"
                "  git worktree add .worktrees/<branch-name> -b <branch-name>"
            )
        return None

    def _contains_git_commit(self) -> bool:
        """Check if the command includes a git commit."""
        return any(re.match(r"^\s*git\s+commit\b", p) for p in _split_compound(self._command))

    def _is_pure_git_command(self) -> bool:
        """Check if the entire command is only git/gh subcommands."""
        if not _is_git_command(self._command):
            return False
        parts = _split_compound(self._command)
        return all(_is_git_command(p) or not p.strip() for p in parts)

    def _check_file_modifying_command(self) -> str | None:
        """Block bash commands that modify files."""
        if match_rules(self._command, RuleCategory.PROTECTED_FILE_MOD, skip_git_parts=True):
            return (
                f"Cannot modify files on the '{self._branch}' branch. "
                "Create a new branch first:\n"
                "  git checkout -b <branch-name>\n"
                "Or use a worktree for isolated work:\n"
                "  git worktree add .worktrees/<branch-name> -b <branch-name>"
            )
        return None


def main() -> None:
    """Entry point for the PreToolUse hook."""
    try:
        data: dict[str, Any] = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        sys.exit(0)

    tool_name: str = data.get("tool_name", "")

    # Collect workflow warnings (any branch)
    warnings: list[str] = WarningChecker(data).check()

    if tool_name == "Bash":
        command: str = data.get("tool_input", {}).get("command", "")

        # Destructive git command checks (apply on ALL branches)
        reason = DestructiveCommandChecker(command).check()
        if reason:
            _block(f"BLOCKED: {reason}. Run this command outside Claude Code if you must.")

    # Branch protection checks
    branch = get_effective_branch(data)
    is_protected = branch and branch in PROTECTED_BRANCHES

    if not is_protected:
        _allow(warnings)

    reason = ProtectedBranchGuard(data, branch).check()
    if reason:
        _block(f"BLOCKED: {reason}")

    _allow(warnings)


if __name__ == "__main__":
    main()
