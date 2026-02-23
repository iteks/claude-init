#!/bin/bash
# Post-tool hook: run shellcheck on modified shell scripts
# Install: .claude/hooks/lint-shellcheck.sh
# Event: PostToolUse (matcher: Write|Edit)

if ! command -v jq &>/dev/null; then exit 0; fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Only process .sh files
case "$FILE_PATH" in
  *.sh|*.bash)
    if command -v shellcheck &>/dev/null; then
      LINT_OUTPUT=$(shellcheck -f gcc "$FILE_PATH" 2>&1)
      LINT_EXIT=$?
      if [[ $LINT_EXIT -ne 0 ]]; then
        jq -n --arg msg "shellcheck issues in $FILE_PATH:\n$LINT_OUTPUT" \
          '{ "systemMessage": $msg }'
      fi
    fi
    ;;
esac
