---
name: python-testing-standards
description: Python testing standards
paths:
- tests/**/*.py
---
## Python testing standards (pytest)

-   Review existing fixtures and reuse them if possible
-   Write single sentence docstrings in imperative voice starting with "Verify"
-   Structure test body with given/when/then comments
-   Use pytest-mock plugin. Do not use unittest.
-   Include unit and integration tests
-   Use fixture factories to create reusable test data
-   Use `@pytest.mark.parametrize` to run the same test with different inputs
-   Ensure tests are stateless and independent
-   Use the `mocker` fixture provided by `pytest-mock` for mocking
-   Mock external dependencies to isolate tests
-   Use `autospec=True` when mocking

### Example of good tests

```python
@pytest.fixture
def user_factory():
    def create_user(username, email):
        return {"username": username, "email": email}
    return create_user

def test_backup_file_creates_backup(tmp_path, mocker, user_factory) -> None:
    """Verify creating backups file with .bak extension."""
    # Given a constant return from module.function
    mock_function = mocker.patch('module.function', autospec=True)
    mock_function.return_value = 'mocked'

    # Given a user
    user = user_factory("testuser", "test@example.com")
    assert user["username"] == "testuser"

    # Given: A test file exists
    file = tmp_path / "test.txt"
    file.write_text("test")

    # When: Creating a backup
    backup_file(file)

    # Then: Backup file exists and original is moved
    expected_backup = file.parent / (file.name + ".bak")
    assert expected_backup.exists()
    assert not file.exists()
```
