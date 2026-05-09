#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.14"
# dependencies = []
# ///

"""Stop hook: catch ownership-dodging and permission-seeking phrases.

Reads the assistant's most recent message from the JSONL `transcript_path`
provided on the Stop hook's stdin, matches it against a list of phrase
patterns derived from CLAUDE.md golden rules, and on the first match
emits a `{decision: block, reason: ...}` JSON decision. Claude Code
reads the decision and forces the assistant to keep working with the
correction as its next instruction.

The `last_assistant_message` field used by the prior bash version of
this hook does not exist on Stop hook input. The official `hookify`
plugin reads `transcript_path` instead, and so does this hook.
"""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass(frozen=True, slots=True)
class Violation:
    """A pattern + correction for the Stop hook to enforce.

    `pattern` is a case-insensitive regex; the first violation that
    matches the assistant's last message wins. `correction` is shown
    to the assistant verbatim (with a `STOP HOOK VIOLATION:` prefix)
    as the reason for blocking the stop.
    """

    pattern: str
    correction: str


# === Violations ===
#
# Ordered by severity -- first match wins. Patterns are case-insensitive
# regex, applied to the concatenated text content of the assistant's
# most recent turn.

VIOLATIONS: tuple[Violation, ...] = (
    # === Ownership dodging (#1 problem: dismissing failures as not-my-fault) ===
    Violation(
        "pre-existing",
        "NOTHING IS PRE-EXISTING (CLAUDE.md golden rule). All builds and tests are green upstream. If something fails, YOUR work caused it. Investigate and fix it. Never dismiss a failure as pre-existing.",
    ),
    Violation(
        "not from my changes",
        "NOTHING IS PRE-EXISTING. You own every change. Investigate the failure.",
    ),
    Violation(
        "not my change",
        "NOTHING IS PRE-EXISTING. You own every change. Investigate the failure.",
    ),
    Violation(
        "not caused by my",
        "NOTHING IS PRE-EXISTING. You own every change. Investigate the failure.",
    ),
    Violation(
        "not introduced by my",
        "NOTHING IS PRE-EXISTING. You own every change. Investigate the failure.",
    ),
    Violation(
        "already existed before",
        "NOTHING IS PRE-EXISTING. If you found it broken, fix it or explain exactly what is wrong and what the fix requires.",
    ),
    Violation(
        "before my changes",
        "NOTHING IS PRE-EXISTING. There is no 'before your changes', you own the codebase as it is now.",
    ),
    Violation(
        "prior to my changes",
        "NOTHING IS PRE-EXISTING. There is no 'prior to your changes.'",
    ),
    Violation(
        "unrelated to my changes",
        "NOTHING IS PRE-EXISTING. If it is broken, fix it. If you broke it, fix it. Nothing is unrelated.",
    ),
    Violation(
        "an existing issue",
        "NOTHING IS PRE-EXISTING. Investigate and fix, or explain exactly what is wrong.",
    ),
    Violation(
        "existing bug",
        "NOTHING IS PRE-EXISTING. Investigate and fix.",
    ),
    # === Known limitation dodging ===
    Violation(
        "known limitation",
        "NO KNOWN LIMITATIONS (CLAUDE.md golden rule). Investigate whether it is fixable. Either fix it or explain the specific technical reason it cannot be fixed right now.",
    ),
    Violation(
        "known issue",
        "NO KNOWN LIMITATIONS. Explain the specific technical reason or fix it.",
    ),
    Violation(
        "future work",
        "NO KNOWN LIMITATIONS. Fix it now or describe exactly what the fix requires, not as a TODO but as a technical explanation.",
    ),
    Violation(
        "left as an exercise",
        "NO KNOWN LIMITATIONS. Do the work.",
    ),
    # === Permission-seeking mid-task ===
    # If the only possible answer from the user is "yes, obviously, you
    # haven't finished yet", don't ask.
    Violation(
        r"want to continue.*or ",
        "Do not ask. The task is not done. Continue working.",
    ),
    Violation(
        "or save it for",
        "Do not ask. The task is not done. Continue working.",
    ),
    Violation(
        "should I continue",
        "Do not ask. If the task is not done, continue. The user will interrupt if they want you to stop.",
    ),
    Violation(
        "shall I continue",
        "Do not ask. Continue working until the task is complete.",
    ),
    Violation(
        "shall I proceed",
        "Do not ask. Proceed.",
    ),
    Violation(
        "would you like me to continue",
        "Do not ask. Continue.",
    ),
    Violation(
        "would you like to continue",
        "Do not ask. Continue.",
    ),
    Violation(
        "want me to keep going",
        "Do not ask. Keep going.",
    ),
    Violation(
        "want me to continue",
        "Do not ask. Continue.",
    ),
    Violation(
        "should I keep going",
        "Do not ask. Keep going.",
    ),
    Violation(
        "save it for next time",
        "There is no 'next time.' Sessions are unlimited. Continue working.",
    ),
    Violation(
        "in the next session",
        "There is no 'next session.' This session is unlimited. Continue working.",
    ),
    Violation(
        "next session",
        "There is no 'next session.' This session is unlimited. Continue working.",
    ),
    Violation(
        "next conversation",
        "There is no 'next conversation.' Continue working.",
    ),
    Violation(
        "pick this up later",
        "There is no 'later.' Continue working now.",
    ),
    Violation(
        "come back to this",
        "There is no 'coming back.' Continue working now.",
    ),
    Violation(
        "continue in a follow-up",
        "There is no 'follow-up.' Continue now.",
    ),
    Violation(
        "pause here",
        "Do not pause. The task is not done. Continue.",
    ),
    Violation(
        "stop here for now",
        "Do not stop. The task is not done. Continue.",
    ),
    Violation(
        "wrap up for now",
        "Do not wrap up. The task is not done. Continue.",
    ),
    Violation(
        "call it here",
        "Do not stop. Continue working.",
    ),
)

# Compiled once at import; saves work across invocations within long-lived runners.
_COMPILED: tuple[tuple[re.Pattern[str], Violation], ...] = tuple(
    (re.compile(v.pattern, re.IGNORECASE), v) for v in VIOLATIONS
)


def _last_assistant_text(transcript_path: str) -> str:
    """Return the concatenated text of the most recent assistant turn.

    Each line of the transcript is a JSON object. Assistant turns have
    `type == "assistant"` at the top level and `message.content` as a
    list of blocks; we concatenate `text` from every block whose `type`
    is `text` (skipping `tool_use` blocks).
    """
    p = Path(transcript_path)
    if not p.is_file():
        return ""

    try:
        raw = p.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""

    for raw_line in reversed(raw.splitlines()):
        line = raw_line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue
        if entry.get("type") != "assistant":
            continue
        content = entry.get("message", {}).get("content")
        if not isinstance(content, list):
            continue
        text_parts = [
            block.get("text", "")
            for block in content
            if isinstance(block, dict) and block.get("type") == "text"
        ]
        text = "".join(text_parts).strip()
        if text:
            return text
    return ""


def find_violation(text: str) -> Violation | None:
    """Return the first violation whose pattern matches the text, or None."""
    for compiled, violation in _COMPILED:
        if compiled.search(text):
            return violation
    return None


def main() -> None:
    """Entry point for the Stop hook."""
    try:
        data: dict[str, Any] = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        sys.exit(0)

    # Already fired once this turn; let the assistant stop to avoid loops.
    if data.get("stop_hook_active"):
        sys.exit(0)

    transcript_path = data.get("transcript_path")
    if not transcript_path:
        sys.exit(0)

    text = _last_assistant_text(transcript_path)
    if not text:
        sys.exit(0)

    violation = find_violation(text)
    if violation is None:
        sys.exit(0)

    decision = {
        "decision": "block",
        "reason": f"STOP HOOK VIOLATION: {violation.correction}",
    }
    print(json.dumps(decision))  # noqa: T201
    sys.exit(0)


if __name__ == "__main__":
    main()
