---
paths:
  - "**/__tests__/**"
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "**/*.test.js"
  - "**/*.test.jsx"
  - "**/*.spec.ts"
  - "**/*.spec.tsx"
  - "**/*.spec.js"
  - "**/*.spec.jsx"
---

# Vitest Testing Conventions

## Structure

- Use `describe()` / `it()` blocks for organization
- Use `beforeEach()` and `afterEach()` for setup/teardown
- Import test utilities from `vitest`: `import { describe, it, expect, vi } from 'vitest'`

## Assertions

- Use `expect()` with Vitest matchers (Jest-compatible API)
- Use `toMatchInlineSnapshot()` for snapshot testing
- Use `toHaveBeenCalledWith()` for mock verification

## Mocking

- Use `vi.mock()` for module-level mocking
- Use `vi.spyOn()` for method-level mocking
- Use `vi.fn()` for creating mock functions
- Clear mocks in `afterEach()`: `vi.restoreAllMocks()`

## Async Testing

- Use `async/await` in test functions
- Always `await` assertions on async code
- Use `waitFor()` from testing-library for async UI assertions
- Use `vi.useFakeTimers()` and `vi.advanceTimersByTime()` for timer-based tests

## File Organization

- Co-locate tests with source files or use `__tests__/` directories
- Name test files `*.test.ts` or `*.spec.ts`
