#!/bin/bash
# Post-tool hook: auto-format Python files after edits
# Install: .claude/hooks/format-python.sh
# Event: PostToolUse (matcher: Write|Edit)
# Supports: ruff (preferred) or black

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.py ]]; then
  exit 0
fi

if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

if command -v ruff &>/dev/null; then
  FIX_OUTPUT=$(ruff format "$FILE_PATH" 2>&1)
  FIX_EXIT=$?
  LINT_OUTPUT=$(ruff check --fix "$FILE_PATH" 2>&1)
  if [[ $? -ne 0 ]]; then
    FIX_OUTPUT="$FIX_OUTPUT\n$LINT_OUTPUT"
    FIX_EXIT=1
  fi
elif command -v black &>/dev/null; then
  FIX_OUTPUT=$(black "$FILE_PATH" 2>&1)
  FIX_EXIT=$?
else
  exit 0
fi

if [[ $FIX_EXIT -ne 0 ]]; then
  jq -n --arg msg "Python formatting errors in $FILE_PATH:\n$FIX_OUTPUT" \
    '{ "systemMessage": $msg }'
fi
