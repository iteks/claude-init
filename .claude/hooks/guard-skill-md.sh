#!/bin/bash
# Pre-tool hook: prompt before editing SKILL.md
# Install: .claude/hooks/guard-skill-md.sh
# Event: PreToolUse (matcher: Write|Edit)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

if echo "$FILE_PATH" | grep -qE 'skills/claude-init/SKILL\.md$'; then
  jq -n --arg reason "SKILL.md is the core pipeline (~950 lines) — confirm this edit is intentional and maintains phase numbering consistency" '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "ask",
      "permissionDecisionReason": $reason
    }
  }'
fi
