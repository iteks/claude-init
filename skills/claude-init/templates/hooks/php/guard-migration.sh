#!/bin/bash
# Pre-tool hook: block dangerous migration commands
# Install: .claude/hooks/guard-migration.sh
# Event: PreToolUse (matcher: Bash)
# Prevents migrate:fresh and migrate:reset on the primary database
# Allows --database=testing for test databases

if ! command -v jq &>/dev/null; then exit 0; fi

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

if echo "$COMMAND" | grep -qiE 'migrate:(fresh|reset)' && ! echo "$COMMAND" | grep -qiE '\-\-database[= ]testing'; then
  jq -n --arg reason "migrate:fresh and migrate:reset are forbidden on the primary database. Use 'php artisan migrate' instead, or add --database=testing for test databases." '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": $reason
    }
  }'
fi
