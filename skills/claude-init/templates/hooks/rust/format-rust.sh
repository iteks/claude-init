#!/bin/bash
# Post-tool hook: auto-format Rust files after edits
# Install: .claude/hooks/format-rust.sh
# Event: PostToolUse (matcher: Write|Edit)

if ! command -v jq &>/dev/null; then exit 0; fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.rs ]]; then
  exit 0
fi

if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

if command -v rustfmt &>/dev/null; then
  FIX_OUTPUT=$(rustfmt "$FILE_PATH" 2>&1)
  FIX_EXIT=$?
else
  exit 0
fi

if [[ $FIX_EXIT -ne 0 ]]; then
  jq -n --arg msg "Rust formatting errors in $FILE_PATH:\n$FIX_OUTPUT" \
    '{ "systemMessage": $msg }'
fi
