# Global Preferences

Project conventions override these global preferences. This file provides defaults when no project-level CLAUDE.md exists.

<!-- Generation note: When replacing placeholders, if a user selected "No preference" and the
     expansion is the neutral default, collapse the entire section (heading + content) to keep
     the file concise. Only include sections where the user expressed an actual preference. -->

## Coding Style

{{CODING_STYLE}}

## Communication

{{COMMUNICATION_TONE}}

## Formatting

{{INDENT_PREFERENCE}}

## Git Workflow

{{GIT_CONVENTIONS}}

## Tool Preferences

{{TOOL_PREFERENCES}}

## Workflow Automation

### Task Assessment

- Proactively call `EnterPlanMode` for any task touching 2+ files or involving architectural decisions
- Skip plan mode for single-file fixes, formatting, and quick lookups

### Post-Implementation

After creating or modifying 2+ files:
- Offer to review changes for issues
- Suggest running relevant linters and tests

### Context Management

- After completing a unit of work, suggest `/compact` to free context
- After 5+ exchanges on different topics, suggest `/clear` for a fresh window
- Never suggest `/clear` during active implementation

## Safety

- Never commit `.env` files, credentials, or secrets
- Never force-push to main/master without explicit confirmation
- Never run destructive commands (`rm -rf`, `DROP TABLE`, `migrate:fresh`) without confirmation
- Always create new commits rather than amending unless explicitly asked
