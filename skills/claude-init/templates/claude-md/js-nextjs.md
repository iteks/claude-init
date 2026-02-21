# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Stack

- Next.js {{NEXTJS_VERSION}} / React {{REACT_VERSION}}
- Language: TypeScript
- Styling: {{STYLING}}
- Testing: {{TEST_FRAMEWORK}}
- Package Manager: {{PACKAGE_MANAGER}}

## Local Development

- **Dev**: `{{DEV_COMMAND}}`
- **Build**: `{{BUILD_COMMAND}}`
- **Tests**: `{{TEST_COMMAND}}`
- **Lint**: `{{LINT_COMMAND}}`

## Architecture

{{ARCHITECTURE_NOTES}}

### Key Directories

| Directory | Purpose |
|---|---|
| `app/` | App Router pages and layouts |
| `components/` | Reusable UI components |
| `lib/` | Shared utilities and helpers |
| `hooks/` | Custom React hooks |
| `types/` | TypeScript type definitions |
| `public/` | Static assets |

## Conventions

- **Indentation**: {{INDENT_STYLE}}
- **Components**: Functional components with hooks, named exports
- **Files**: PascalCase for components, camelCase for utilities
- **Styling**: {{STYLING_CONVENTIONS}}
- **State**: Prefer server components; use `'use client'` only when needed
- **Data fetching**: Use Server Components and Server Actions

## Workflow Automation

### Task Assessment

Use `EnterPlanMode` for any task that:
- Touches 2+ files
- Creates a new page, component, or API route
- Involves refactoring across files

### Post-Implementation

After modifying 2+ files:
- Offer to run `{{LINT_COMMAND}}`
- Offer to run `{{TEST_COMMAND}}`
- Offer a code review via the code-reviewer agent
- For security-sensitive changes (auth, input handling, API routes), offer the security-reviewer agent
- For new code lacking test coverage, offer the test-generator agent

### Agent Teams

For complex tasks that benefit from parallel work, spawn an agent team:

**When to use teams:**
- Full-page features touching pages, components, API routes, and styles simultaneously
- Parallel component work (2+ independent components for the same feature)
- Multi-concern reviews (accessibility + performance + test coverage)

**When NOT to use teams:**
- Single-file changes, quick fixes, sequential work
- Changes where each step depends on the previous

**Example pattern — new page with API:**
- **Pages** teammate (Sonnet): page component and layout in `app/`, API route in `app/api/`
- **Components** teammate (Sonnet): shared components in `components/` and hooks in `hooks/`
- Assign exclusive file ownership per teammate to prevent conflicts
- Use task dependencies (`blockedBy`) for sequential steps

### Context Management

- After completing a unit of work, suggest `/compact`
- After 5+ exchanges on different topics, suggest `/clear`

## Things to Watch For

- **Client vs Server**: Don't use hooks in Server Components
- **Environment variables**: Use `NEXT_PUBLIC_` prefix for client-exposed vars
- **Config files**: Always confirm before modifying `next.config.*`, `tsconfig.json`, `package.json`
- **API routes**: Validate input, handle errors with proper status codes
