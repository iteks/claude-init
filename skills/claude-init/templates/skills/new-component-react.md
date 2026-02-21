---
description: Scaffold a new React component with props interface, implementation, and tests. Invoke with /new-component followed by the component name.
---

# New Component

Create a new React component named "$ARGUMENTS".

## Workflow

### 1. Plan the Component

Determine the component structure:
- **Component name**: $ARGUMENTS (PascalCase)
- **Location**: Choose the appropriate directory based on project structure (`components/`, `src/components/`, or a feature directory)
- **Props**: Ask the user what props the component needs
- **Type**: Presentational, container, or layout component
- Ask the user to confirm before proceeding

### 2. Create the Component File

Create `{{COMPONENT_DIR}}/$ARGUMENTS/$ARGUMENTS.tsx` (or `.jsx` if no TypeScript):

- Define a Props interface/type for all component props
- Use functional component syntax with explicit return type
- Follow existing component patterns in the project:
  - Check if project uses default or named exports
  - Check if project uses arrow functions or function declarations
  - Check styling approach (CSS modules, Tailwind, styled-components, NativeWind)
- Include proper TypeScript types for all props
- Add JSDoc comment if the component's purpose isn't obvious from the name

### 3. Create the Test File

Create `{{COMPONENT_DIR}}/$ARGUMENTS/$ARGUMENTS.test.tsx`:

- Use {{TEST_FRAMEWORK}} with `@testing-library/react` (or `@testing-library/react-native` for Expo)
- Test that the component renders without crashing
- Test that props are applied correctly
- Test user interactions (clicks, inputs) if applicable
- Test conditional rendering logic
- Follow existing test patterns in the project

### 4. Create Index File (if project uses barrel exports)

If the project uses index.ts barrel exports in component directories, create or update the index file to export the new component.

### 5. Verify

- Run the tests: `{{TEST_COMMAND}} --testPathPattern=$ARGUMENTS`
- Check for lint errors: `{{LINT_COMMAND}}`
- Check for type errors: `{{TYPECHECK_COMMAND}}`

## Output

After completing all steps, report:
- Files created (with paths)
- Test results
- Any follow-up suggestions (e.g., "Add to a page/screen to use this component")
