#!/bin/bash
# Pre-tool hook: block dangerous Django management commands
# Install: .claude/hooks/guard-migration-django.sh
# Event: PreToolUse (matcher: Bash)
# Prevents flush, migrate --fake, and migrate --run-syncdb on the primary database
# Allows --database=test for test databases

if ! command -v jq &>/dev/null; then
  exit 0
fi

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# Block manage.py flush (destroys all data)
if echo "$COMMAND" | grep -qiE 'manage\.py\s+flush' && ! echo "$COMMAND" | grep -qiE '\-\-database[= ]test'; then
  jq -n --arg reason "manage.py flush is forbidden on the primary database. It deletes all data. Use --database=test for test databases." '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": $reason
    }
  }'
  exit 0
fi

# Block manage.py migrate --fake (can corrupt migration state)
if echo "$COMMAND" | grep -qiE 'manage\.py\s+migrate.*\-\-fake'; then
  jq -n --arg reason "manage.py migrate --fake is dangerous — it marks migrations as applied without running them, which can corrupt migration state. Remove --fake and run migrations normally." '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": $reason
    }
  }'
  exit 0
fi

# Block manage.py migrate --run-syncdb
if echo "$COMMAND" | grep -qiE 'manage\.py\s+migrate.*\-\-run-syncdb'; then
  jq -n --arg reason "manage.py migrate --run-syncdb bypasses the migration system. Use regular migrations instead." '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": $reason
    }
  }'
  exit 0
fi
