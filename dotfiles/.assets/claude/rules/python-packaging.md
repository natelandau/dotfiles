---
name: python-packaging
description: Python packaging standards
---
## Python Package Management Instructions

Use uv exclusively for Python package management.

-   Install dependencies: `uv add <package>`
-   Remove dependencies: `uv remove <package>`
-   Sync dependencies: `uv sync`
-   Run a Python script: `uv run <script-name>.py`
-   Run Python tools: `uv run pytest` or `uv run ruff`
-   Launch a Python repl: `uv run python`

Never use pip, pip-tools, poetry, or conda directly for dependency management.
