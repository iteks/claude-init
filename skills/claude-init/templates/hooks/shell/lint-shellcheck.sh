#!/bin/bash
# Post-tool hook: run shellcheck on modified shell scripts
# Install: .claude/hooks/lint-shellcheck.sh
# Event: PostToolUse (matcher: Write|Edit)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Only process .sh files
case "$FILE_PATH" in
  *.sh|*.bash)
    if command -v shellcheck &>/dev/null; then
      OUTPUT=$(shellcheck -f gcc "$FILE_PATH" 2>&1)
      EXIT_CODE=$?
      if [[ $EXIT_CODE -ne 0 ]]; then
        echo "$OUTPUT"
      fi
    fi
    ;;
esac
