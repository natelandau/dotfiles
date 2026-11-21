---
name: python-standards
description: Python coding standards
paths:
    - "**/*.py"
---

## General Python coding standards

- Use `pathlib` for file system operations, not `os.path` or `os` file functions.
- Pass keyword arguments in every call with more than one argument.
- Use `enumerate()`, not manual counters; comprehensions and generator expressions, not
  append loops.

## Python docstring standards

- Write Google-format docstrings for every public function, class, and method.

Example (illustration):

```python
def find_files(root: Path, globs: list[str] | None = None) -> list[Path]:
    """Find files under a directory so callers can process them by pattern.

    Search `root` recursively for files matching any pattern in `globs`. Return every file when
    `globs` is None.

    Args:
        root: Directory to search.
        globs: Glob patterns to match. Defaults to None.

    Returns:
        list[Path]: Matching files, sorted by path.

    Raises:
        FileNotFoundError: If `root` does not exist.
    """
    if not root.exists():
        msg = f"Directory not found: {root}"
        raise FileNotFoundError(msg)
    ...
```

## Python exceptions standards

- No bare `except:` and no broad `except Exception` unless re-raising.

## Python code organization

- Group functions that share state, configuration, or arguments into a class (service handlers,
  API clients, data pipelines). Leave single functions and pure utilities as module functions.
- Keep each class to one responsibility. Keep `__init__` free of complex logic.
- Use dataclasses for data containers and `@property` for computed attributes.
- Prefer composition over inheritance.
- Keep the public surface small; make internal helpers private.

## Python typing standards

- Type every function signature (parameters and return).
- Annotate a variable's type where it is first assigned: `scopes: list[str] = [...]`.
- Use built-in generics and `|`: `list[str]`, `str | None`, not `List[str]` or `Optional[str]`.
- Name complex unions with a type alias.
- Use `TypeVar` for generics, `Literal` for literal types, `typing.Protocol` for interfaces.

## Python workflow

- Per-file lint and format: `uv run ruff check <file>` and `uv run ruff format <file>`.
- Pre-commit checks when the project has no task runner:

```bash
uv run ruff check src/
uv run ruff format src/ tests/
uv run pytest -x --tb=short

# type checking: use whichever is installed
uv run mypy --config-file=pyproject.toml src/
uv run ty check src/
```
