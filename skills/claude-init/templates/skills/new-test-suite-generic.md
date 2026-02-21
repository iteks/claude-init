---
description: Scaffold a test suite for existing code. Analyzes source files and generates tests matching project conventions. Invoke with /new-test-suite followed by the file or module to test.
---

# New Test Suite

Create tests for "$ARGUMENTS".

## Workflow

### 1. Analyze the Target

Read the file or module specified by $ARGUMENTS:
- Identify all public functions, methods, and classes
- Note input types, return types, and side effects
- Identify edge cases (null/empty inputs, boundary values, error conditions)
- Check for existing tests that already cover this code

### 2. Plan Test Coverage

For each public function/method, plan tests for:
- **Happy path**: Normal inputs produce expected outputs
- **Edge cases**: Empty strings, zero values, null, boundary values
- **Error cases**: Invalid inputs, missing data, network failures
- **Integration points**: Database queries, API calls, file operations (mock these)

Present the test plan to the user for confirmation before writing.

### 3. Create Test File

Create the test file following project conventions:
- **Location**: Mirror the source file structure in the test directory
- **Naming**: Follow project's test file naming convention
- **Framework**: Use {{TEST_FRAMEWORK}} syntax and conventions
- **Imports**: Import the code under test and any test utilities
- **Structure**: Group tests by function/method using describe/context blocks

### 4. Write Tests

For each planned test:
- Use descriptive test names that explain the expected behavior
- Follow the Arrange-Act-Assert (AAA) pattern
- Use project's preferred assertion style
- Mock external dependencies (databases, APIs, file system)
- Use factories or fixtures for test data (never hardcode)
- Keep each test focused on one behavior

### 5. Verify

- Run the new tests: `{{TEST_COMMAND}} --filter=$ARGUMENTS`
- Verify all tests pass
- Check that no existing tests were broken

## Output

After completing all steps, report:
- Test file created (with path)
- Number of tests written
- Test results (pass/fail)
- Coverage gaps noted (if any code paths couldn't be easily tested)
