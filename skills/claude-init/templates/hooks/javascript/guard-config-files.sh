#!/bin/bash
# Pre-tool hook: prompt before modifying build/config files
# Install: .claude/hooks/guard-config-files.sh
# Event: PreToolUse (matcher: Write|Edit)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

FILENAME=$(basename "$FILE_PATH")

case "$FILENAME" in
  next.config.*|nuxt.config.*|vite.config.*|webpack.config.*|rollup.config.*|app.config.*|tailwind.config.*|postcss.config.*|metro.config.*|babel.config.*|tsconfig.json|package.json|.eslintrc*|eslint.config.*)
    jq -n --arg reason "$FILENAME is a protected config file — confirm before modifying" '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": $reason
      }
    }'
    ;;
esac
