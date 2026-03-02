---
name: python-standards
description: Python coding standards
paths:
    - "**/*.py"
---

## General Python coding standards

- Avoid mutable default arguments
- Use context managers (with statement) for file/resource management
- Use `is` for comparing with None, True, False
- Use f-strings for string formatting
- Use list comprehensions and generator expressions
- Use `enumerate()` instead of manual counter variables
- Use Pathlib for file system operations. Do not use `os.path` or `os.`.
- Use `typing.Protocol` for interfaces

## Python docstring standards

- Include docstrings for all public functions, classes, and methods
- Document function parameters, return values, and exceptions raised
- **Always use Google format docstrings**
- Do not document return when nothing is returned
- **Only write in imperative voice.** Never say "This function ..."
- Docstrings should explain _why_ a developer would use the function, not just what it does
- Do not include raised exceptions unless they are explicitly raised in the code

### Example docstring

```python
def read_config(path: Path = "config.toml", globs: list[str] | None = None) -> list[Path]:
    """Read and validate the TOML configuration file that maps repository names to paths.

    Search the given `path` for files matching any of the glob patterns provided in `globs`. If no globs are provided, returns all files in the directory.

    Args:
        path: The root directory where the search will be conducted.
        globs: A list of glob patterns to match files. Defaults to None.

    Returns:
        list[Path]: A list of Path objects representing the files that match the glob patterns.

    Raises:
        cappa.Exit: If the config file doesn't exist, contains invalid TOML, or has invalid repository paths
    """
```

## Python exceptions standards

- Do not silently swallow exceptions without logging
- Do not use bare except: clauses
- Catch specific exceptions rather than broad exception types
- Use context managers (with statements) for resource cleanup
- Provide meaningful error messages
- Add messages to a variable before adding it to the exception

## Python class style

- Keep classes focused on a single responsibility
- Keep **init** simple; avoid complex logic
- Use dataclasses for simple data containers
- Prefer composition over inheritance
- Avoid creating additional class functions if they are not necessary
- Use @property for computed attributes

## Python typing standards

- Use type hints for all function signatures (parameters and return values)
- Do not use `Any` type unless absolutely necessary. Acceptable uses:
    - `**kwargs` parameters where the values are truly dynamic
    - Interfacing with external libraries that return untyped data
    - When the type is genuinely unknowable at compile time
- Create type aliases for complex union types to improve readability
- Run installed type checkers and resolve all type errors
- Use `T | None` for nullable types
- When you mention a variable for the first time, write the type: `scopes: list[str] = [...]`
- Use lowercase for type names: `list[str]` not `List[str]`
- Use `|` for union types: `str | None` not `Union[str, None]`
- Use `TypeVar` for generic types
- Use `Literal` for literal types

## Python naming conventions

Always follow these standards for Python naming convention.

- Python files: `snake_case.py` (e.g., `user_handlers.py`, `database_utils.py`)
- Class names: `CamelCase` (e.g., `UserHandler`, `DatabaseConnection`).
- Function names: `snake_case` (e.g., `get_user`, `create_product`).
- Variables: `snake_case` (e.g., `user_id`, `product_name`).
- Constants: `UPPER_SNAKE_CASE` (e.g., `DEFAULT_PORT`, `MAX_CONNECTIONS`).

## Python workflow

- After each python file edit, immediately run `uv run ruff check <file>` and `uv run ruff format <file>` on that specific file.
- Before any git commit, run the full test suite and linters and fix any errors. See the example below.

```bash
uv run ruff check src/
uv run ruff format src/ tests/
uv run pytest -x --tb=short

# type checking (pick the tool that is available)
uv run mypy --config-file=pyproject.toml src/
uv run ty src/
```
