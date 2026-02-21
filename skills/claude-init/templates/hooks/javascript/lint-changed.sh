#!/bin/bash
# Post-tool hook: runs ESLint on changed files
# Install: .claude/hooks/lint-changed.sh
# Event: PostToolUse (matcher: Write|Edit)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs) ;;
  *) exit 0 ;;
esac

if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

LINT_OUTPUT=$(npx eslint --fix "$FILE_PATH" 2>&1)
LINT_EXIT=$?

if [[ $LINT_EXIT -ne 0 ]]; then
  jq -n --arg msg "ESLint errors remain in $FILE_PATH after auto-fix:\n$LINT_OUTPUT" \
    '{ "systemMessage": $msg }'
fi
