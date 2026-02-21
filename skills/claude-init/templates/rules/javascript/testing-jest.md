---
paths:
  - "**/__tests__/**"
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "**/*.test.js"
  - "**/*.test.jsx"
  - "**/*.spec.ts"
  - "**/*.spec.tsx"
---

# Jest Testing Conventions

## Structure

- Use `describe()` / `it()` blocks for organization
- Group related tests with nested `describe()` blocks
- Use `beforeEach()` and `afterEach()` for setup/teardown

## Assertions

- Use `expect()` with specific matchers:
  - `toBe()` for primitives, `toEqual()` for objects/arrays
  - `toHaveBeenCalledWith()` for mock verification
  - `toThrow()` for error testing
- Avoid `toBeTruthy()` / `toBeFalsy()` — use specific matchers

## Mocking

- Use `jest.mock()` for module-level mocking
- Use `jest.spyOn()` for method-level mocking
- Clear mocks in `afterEach()`: `jest.restoreAllMocks()`

## Async Testing

- Use `async/await` in test functions
- Always `await` assertions on async code
- Use `waitFor()` from testing-library for async UI assertions

## File Organization

- Co-locate tests with source files or use `__tests__/` directories
- Test files mirror the source structure
- Name test files `*.test.ts` or `*.test.tsx`
