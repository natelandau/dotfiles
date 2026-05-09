#!/usr/bin/env -S uv run --script
import json
import sys


def main() -> None:
    """Main function."""
    # Read the tool use data from stdin
    data = json.load(sys.stdin)

    # Claude Code PreToolUse payloads use `tool_name` and `tool_input`
    if data.get("tool_name") != "Bash":
        sys.exit(0)

    command = data.get("tool_input", {}).get("command", "")

    # Detect problematic patterns
    patterns = {
        "python ": "uv run",
        "pip install": "uv add",
        "pytest": "uv run pytest",
        "ruff": "uv run ruff",
    }

    for old, new in patterns.items():
        if old in command:
            print(f"⚠️  Detected '{old}' in command.", file=sys.stderr)  # noqa: T201
            print(f"💡 In uv projects, use '{new}' instead.", file=sys.stderr)  # noqa: T201
            sys.exit(1)


if __name__ == "__main__":
    main()
