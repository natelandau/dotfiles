"""Duty tasks for the project."""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path
from typing import TYPE_CHECKING

from duty import duty

if TYPE_CHECKING:
    from duty.context import Context

PY_SRC_PATHS = (Path(_) for _ in ("src/", "tests/", "duties.py", "scripts/") if Path(_).exists())
PY_SRC_LIST = tuple(str(_) for _ in PY_SRC_PATHS)
CI = os.environ.get("CI", "0") in {"1", "true", "yes", ""}


def strip_ansi(text: str) -> str:
    """Remove ANSI escape sequences from a string.

    Args:
        text (str): String to remove ANSI escape sequences from.

    Returns:
        str: String without ANSI escape sequences.
    """
    ansi_chars = re.compile(r"(\x9B|\x1B\[)[0-?]*[ -\/]*[@-~]")

    # Replace [ with \[ so rich doesn't interpret output as style tags
    return ansi_chars.sub("", text).replace("[", r"\[")


def pyprefix(title: str) -> str:
    """Add a prefix to the title if CI is true.

    Returns:
        str: Title with prefix if CI is true.
    """
    if CI:
        prefix = f"(python{sys.version_info.major}.{sys.version_info.minor})"
        return f"{prefix:14}{title}"
    return title


@duty(silent=True)
def clean(ctx: Context) -> None:
    """Clean the project."""
    ctx.run("find . -name '.DS_Store' -delete")


@duty
def typos(ctx: Context) -> None:
    """Check the code with typos."""
    ctx.run(
        ["typos", "--config", ".typos.toml"],
        title=pyprefix("typos check"),
        command="typos --config .typos.toml",
    )


@duty(skip_if=CI, skip_reason="skip prek in CI environments")
def precommit(ctx: Context) -> None:
    """Run prek hooks."""
    ctx.run(
        "SKIP=mypy,pytest,ruff,ansible-lint,yamllint prek run --all-files",
        title=pyprefix("prek hooks"),
    )


@duty(pre=[typos, precommit], capture=CI)
def lint(ctx: Context) -> None:
    """Run all linting duties."""


@duty(capture=CI)
def update(ctx: Context) -> None:
    """Update the project."""
    ctx.run(["uv", "lock", "--upgrade"], title="update uv lock")
    ctx.run(["uv", "sync"], title="update uv sync")
    ctx.run(["prek", "autoupdate"], title="prek autoupdate")
