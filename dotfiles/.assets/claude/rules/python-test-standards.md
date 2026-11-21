---
name: python-testing-standards
description: Python testing standards
paths:
    - tests/**/*.py
---

## Python testing standards (pytest)

- Use pytest, not `unittest`.
- Reuse existing fixtures before writing one.
- Use fixture factories when tests need variants of the same data.
- Mock with the `mocker` fixture from `pytest-mock`, with `autospec=True`.
- Name tests `test_<unit>_<scenario>`: `test_parse_config_missing_file`.
- Docstring: one imperative sentence starting with "Verify".

## Test file organization

- Top-level folder per test type: `tests/unit/`, `tests/integration/`.
- Mirror the source tree inside each: `src/auth/login.py` -> `tests/unit/auth/test_login.py`.

## Example (illustration)

```python
@pytest.fixture
def user_factory():
    def create_user(username: str, email: str) -> dict[str, str]:
        return {"username": username, "email": email}

    return create_user


def test_backup_file_moves_original(tmp_path, mocker) -> None:
    """Verify backup_file renames the original with a .bak extension."""
    mocker.patch("module.function", autospec=True, return_value="mocked")
    file = tmp_path / "test.txt"
    file.write_text("test")

    backup_file(file)

    assert (tmp_path / "test.txt.bak").exists()
    assert not file.exists()
```
