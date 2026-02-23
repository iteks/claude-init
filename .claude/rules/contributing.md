---
paths:
  - "skills/**"
  - "*.sh"
  - "*.json"
---

# Contributing Conventions

## Adding a New Stack

1. Create hook templates in `skills/claude-init/templates/hooks/{language}/`
2. Create rule templates in `skills/claude-init/templates/rules/{language}/`
3. Create a settings template in `skills/claude-init/templates/settings/{framework}.json`
4. Create a CLAUDE.md template in `skills/claude-init/templates/claude-md/{framework}.md`
5. Create agent templates in `skills/claude-init/templates/agents/` (security-reviewer and test-generator variants)
6. Add detection logic to SKILL.md Phase 2B detection tables
7. Add template mapping to Phase 3 template selection table
8. Update README.md supported stacks table

## Naming Conventions

- Hook scripts: `{action}-{target}.sh` (e.g., `guard-env.sh`, `format-php.sh`)
- Agent templates: `{role}-{language/framework}.md` (e.g., `security-reviewer-php.md`)
- Rule templates: `{topic}-{framework}.md` (e.g., `testing-pest.md`, `api-conventions-laravel.md`)
- Settings templates: `{language}-{framework}.json` (e.g., `php-laravel.json`)
- CLAUDE.md templates: `{language}-{framework}.md` or `generic.md`
- Skill templates: `new-{thing}-{framework}.md` (e.g., `new-api-endpoint-laravel.md`)
- Command templates: `{action}.md` (e.g., `review-changes.md`, `run-tests.md`)

## File Organization

- Templates are organized by type first, then by language/framework
- Universal templates (used across all stacks) go in `universal/` or at the type root
- Framework-specific templates include the framework in the filename

## SKILL.md Editing Guidelines

- SKILL.md is ~1285 lines — read fully before editing
- Phase numbering: 1, 2A, 2B, 2C, 2D, 2E, 2F, 3, 4, 5
- Phases 2C–2E handle agent/skill/plugin detection; 2F is audit mode
- Always update the detection subagent prompt when adding new detection steps
- Always update the template selection table when adding new outputs
- Always update the Phase 5 report template when adding new file types
