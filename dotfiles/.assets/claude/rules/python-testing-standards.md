---
name: python-testing-standards
description: Python testing standards
paths:
    - tests/**/*.py
---

## Python testing standards (pytest)

- Do not use unittest
- Review existing fixtures and reuse them if possible
- Write single sentence docstrings in imperative voice starting with "Verify"
- Structure test body with given/when/then comments
- Use fixture factories when tests need variants of the same data
- Use `@pytest.mark.parametrize` to run the same test with different inputs
- Use the `mocker` fixture from `pytest-mock` for mocking with `autospec=True`
- Name tests `test_<unit>_<scenario>` (e.g., `test_parse_config_missing_file`, `test_login_invalid_password`)

## Test file organization

- Use top-level folders for test types: `tests/unit/`, `tests/integration/`
- Within each folder, mirror the source tree (e.g., `src/auth/login.py` → `tests/unit/auth/test_login.py`)

## Test structure

Use the Given/When/Then pattern:

```python
def test_login_valid_credentials():
    """Verify successful login with valid credentials."""
    # Given a user
    user = create_test_user(email="test@example.com", password="secure123")

    # When the user logs in
    result = login(email="test@example.com", password="secure123")

    # Then the login is successful
    assert result.success is True
    assert result.user.email == "test@example.com"
```

### Example with fixtures and mocking

```python
@pytest.fixture
def user_factory():
    def create_user(username, email):
        return {"username": username, "email": email}
    return create_user

def test_backup_file_creates_backup(tmp_path, mocker) -> None:
    """Verify backup creates file with .bak extension."""
    # Given a mocked dependency
    mock_function = mocker.patch('module.function', autospec=True)
    mock_function.return_value = 'mocked'

    # Given a test file exists
    file = tmp_path / "test.txt"
    file.write_text("test")

    # When creating a backup
    backup_file(file)

    # Then backup file exists and original is moved
    expected_backup = file.parent / (file.name + ".bak")
    assert expected_backup.exists()
    assert not file.exists()
```
