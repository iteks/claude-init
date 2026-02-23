#!/bin/bash
# Post-tool hook: runs tsc --noEmit and reports errors in the changed file
# Install: .claude/hooks/typecheck-changed.sh
# Event: PostToolUse (matcher: Write|Edit)

if ! command -v jq &>/dev/null; then exit 0; fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.ts && "$FILE_PATH" != *.tsx ]]; then
  exit 0
fi

if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

TSC_OUTPUT=$(npx tsc --noEmit 2>&1 | grep -F "$FILE_PATH" || true)

if [[ -n "$TSC_OUTPUT" ]]; then
  jq -n --arg msg "TypeScript errors in $FILE_PATH:\n$TSC_OUTPUT" \
    '{ "systemMessage": $msg }'
fi
