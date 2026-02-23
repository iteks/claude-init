---
paths:
  - "skills/claude-init/templates/**"
---

# Template Conventions

## Hook Scripts

- Shebang: `#!/bin/bash`
- Comment header: description, install path (`# Install: .claude/hooks/...`), event type (`# Event: PreToolUse|PostToolUse`)
- Check jq availability: `if ! command -v jq &>/dev/null; then exit 0; fi`
- Read stdin: `INPUT=$(cat)`
- Extract fields with `jq -r`: `FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')`
- PreToolUse output: JSON with `permissionDecision` (deny/ask/allow) via `jq -n`
- PostToolUse hooks: execute commands, capture output, non-zero exit signals issues
- Always check for empty input before processing

## Agent Definitions

- YAML frontmatter fields (required): `name`, `description`, `model`, `color`, `tools`, `permissionMode`, `maxTurns`, `memory`
- Read-only agents (reviewers): `tools: Read, Grep, Glob`, `permissionMode: plan`
- Write-capable agents (generators): `tools: Read, Grep, Glob, Write, Edit, Bash`, `permissionMode: acceptEdits`
- Sections: intro paragraph, Workflow, Categories (P0-P3), Output Format, Summary, Guidelines
- Description should include invocation guidance ("Invoke with..." or "Invoke proactively after...")

## Rules

- YAML frontmatter with `paths:` array containing glob patterns
- Validate that glob patterns match actual files in target projects
- Organize by language subdirectory (`php/`, `javascript/`, `python/`)

## CLAUDE.md Templates

- Use `{{PLACEHOLDER}}` syntax (double curly braces, UPPER_SNAKE_CASE)
- Must produce output under 300 lines after placeholder replacement
- Always include Workflow Automation section

## Skill Templates

- Frontmatter: `description` (required)
- Use `$ARGUMENTS` for user-provided input
- Structured workflow with numbered steps
- Include a Verify step and Output summary

## Command Templates

- Frontmatter: `description` (required), `disable-model-invocation: true` for user-invoked commands
- Use `$ARGUMENTS` for user-provided input
- Concise prompt text — commands are simpler than skills

## Settings Templates

- JSON with `hooks` object (PostToolUse, PreToolUse arrays)
- Each hook entry: `matcher` (tool pattern), `hooks` array with `type`, `command`, `timeout`
- Complex stacks include `permissions.defaultMode: "plan"`

