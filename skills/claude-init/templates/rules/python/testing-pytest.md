---
paths:
  - "tests/**"
  - "**/test_*.py"
  - "**/*_test.py"
---

# Pytest Testing Conventions

## Structure

- Use plain functions with `test_` prefix — no class-based tests unless grouping is needed
- Group related tests with `class TestFeatureName:` (no inheritance needed)
- Use fixtures (`@pytest.fixture`) for shared setup

## Assertions

- Use plain `assert` statements — pytest rewrites them for detailed output
- Prefer specific comparisons: `assert result == expected` over `assert result`
- Use `pytest.raises()` for exception testing
- Use `pytest.approx()` for floating point comparisons

## Fixtures

- Define fixtures in `conftest.py` at appropriate directory levels
- Use `scope` parameter for expensive fixtures: `@pytest.fixture(scope="module")`
- Prefer factory fixtures over complex setup

## Parametrize

- Use `@pytest.mark.parametrize` for data-driven tests
- Keep parameter names descriptive

## File Organization

- Test files mirror the source structure under `tests/`
- Name test files `test_*.py` (prefix convention)
- Use `conftest.py` for shared fixtures at each directory level
