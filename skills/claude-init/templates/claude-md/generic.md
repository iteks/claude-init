# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Stack

{{STACK_DESCRIPTION}}

## Local Development

{{DEV_INSTRUCTIONS}}

## Architecture

{{ARCHITECTURE_NOTES}}

### Key Directories

{{DIRECTORY_TABLE}}

## Conventions

{{CONVENTIONS}}

## Workflow Automation

### Task Assessment

Use `EnterPlanMode` for any task that:
- Touches 2+ files
- Creates new modules or components
- Involves refactoring across files

### Post-Implementation

After modifying 2+ files:
- Offer to run the project's linter/formatter
- Offer to run relevant tests
- Offer a code review via the code-reviewer agent
- For security-sensitive changes, offer the security-reviewer agent

### Context Management

- After completing a unit of work, suggest `/compact`
- After 5+ exchanges on different topics, suggest `/clear`

## Things to Watch For

{{WATCH_ITEMS}}
