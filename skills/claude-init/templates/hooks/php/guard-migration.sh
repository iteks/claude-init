#!/bin/bash
# PreToolUse hook: Block dangerous migration commands
# Prevents migrate:fresh and migrate:reset on the primary database
# Allows --database=testing for test databases

if echo "$TOOL_INPUT" | grep -qiE 'migrate:(fresh|reset)' && ! echo "$TOOL_INPUT" | grep -qiE '\-\-database[= ]testing'; then
  echo "BLOCKED: migrate:fresh and migrate:reset are forbidden on the primary database." >&2
  echo "Use 'php artisan migrate' instead, or add --database=testing for test databases." >&2
  exit 2
fi
