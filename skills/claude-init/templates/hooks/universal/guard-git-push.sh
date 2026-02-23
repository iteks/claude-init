#!/bin/bash
# Pre-tool hook: prompt before git push
# Install: .claude/hooks/guard-git-push.sh
# Event: PreToolUse (matcher: Bash)

if ! command -v jq &>/dev/null; then exit 0; fi

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

if echo "$COMMAND" | grep -qE '\bgit\s+push\b'; then
  jq -n --arg reason "git push detected — confirm before pushing to remote" '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "ask",
      "permissionDecisionReason": $reason
    }
  }'
fi
