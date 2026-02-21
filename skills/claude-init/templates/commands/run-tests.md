---
description: Run the project's test suite with smart defaults
disable-model-invocation: true
---

Run the project's test suite.

If $ARGUMENTS is provided, use it as a filter/path to run specific tests:
- `$ARGUMENTS` as a test name filter, file path, or directory

If no arguments are provided:
- Run the full test suite using the project's configured test command: `{{TEST_COMMAND}}`
- If the test command is not configured, detect it from:
  - `package.json` scripts (look for "test")
  - `composer.json` scripts
  - `Makefile` targets (look for "test")
  - Common commands: `php artisan test`, `npx jest`, `npx vitest`, `pytest`

After running:
- Report the results (pass/fail counts)
- If there are failures, read the failing test files and the source code they test
- Suggest fixes for any failures
