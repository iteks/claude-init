#!/bin/bash
# Post-tool hook: auto-format Go files after edits
# Install: .claude/hooks/format-go.sh
# Event: PostToolUse (matcher: Write|Edit)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.go ]]; then
  exit 0
fi

if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

if command -v gofmt &>/dev/null; then
  gofmt -w "$FILE_PATH" 2>&1
elif command -v goimports &>/dev/null; then
  goimports -w "$FILE_PATH" 2>&1
fi
