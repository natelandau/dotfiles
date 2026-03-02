---
name: python-testing-standards
description: Python testing standards
paths:
    - tests/**/*.py
---

## Python testing standards (pytest)

- Review existing fixtures and reuse them if possible
- Write single sentence docstrings in imperative voice starting with "Verify"
- Structure test body with given/when/then comments
- Use pytest-mock plugin. Do not use unittest.
- Include unit and integration tests
- Use fixture factories to create reusable test data
- Use `@pytest.mark.parametrize` to run the same test with different inputs
- Ensure tests are stateless and independent
- Use the `mocker` fixture provided by `pytest-mock` for mocking
- Mock external dependencies to isolate tests
- Use `autospec=True` when mocking

## Test Structure

Use the Given/When/Then pattern:

```python
def test_user_can_login():
    """Verify the user can login."""
    # Given a user
    user = create_test_user(email="test@example.com", password="secure123")

    # When the user logs in
    result = login(email="test@example.com", password="secure123")

    # Then the login is successful
    assert result.success is True
    assert result.user.email == "test@example.com"
```

## Unit Tests

- Test individual functions/methods in isolation
- Mock external dependencies
- Fast execution
- High coverage of logic branches

## Integration Tests

- Test component interactions
- Use real dependencies where practical
- Verify data flows correctly

## Edge Cases

- Empty inputs
- Boundary values
- Invalid inputs
- Error conditions
- Concurrent access (if applicable)

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
