#!/bin/bash
# Pre-tool hook: block editing .env files, prompt for .env.example
# Install: .claude/hooks/guard-env.sh
# Event: PreToolUse (matcher: Write|Edit)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

FILENAME=$(basename "$FILE_PATH")

case "$FILENAME" in
  .env|.env.local|.env.staging|.env.production|.env.testing)
    jq -n --arg reason "$FILENAME is a secret environment file — editing is blocked. Modify .env.example instead and instruct the user to update their .env manually." '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": $reason
      }
    }'
    ;;
  .env.example)
    jq -n --arg reason "$FILENAME is committed and shared — confirm before modifying" '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": $reason
      }
    }'
    ;;
esac
