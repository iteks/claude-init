#!/bin/bash
# Post-tool hook: auto-format PHP files after edits
# Install: .claude/hooks/format-php.sh
# Event: PostToolUse (matcher: Write|Edit)
# Supports: Duster (preferred) or Pint

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.php ]]; then
  exit 0
fi

if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

# Find project root (look for composer.json)
PROJECT_DIR="$FILE_PATH"
while [[ "$PROJECT_DIR" != "/" ]]; do
  PROJECT_DIR=$(dirname "$PROJECT_DIR")
  if [[ -f "$PROJECT_DIR/composer.json" ]]; then
    break
  fi
done

if [[ ! -f "$PROJECT_DIR/composer.json" ]]; then
  exit 0
fi

# Prefer Duster, fall back to Pint
if [[ -f "$PROJECT_DIR/vendor/bin/duster" ]]; then
  FIX_OUTPUT=$(cd "$PROJECT_DIR" && ./vendor/bin/duster fix "$FILE_PATH" 2>&1)
  FIX_EXIT=$?
elif [[ -f "$PROJECT_DIR/vendor/bin/pint" ]]; then
  FIX_OUTPUT=$(cd "$PROJECT_DIR" && ./vendor/bin/pint "$FILE_PATH" 2>&1)
  FIX_EXIT=$?
else
  exit 0
fi

if [[ $FIX_EXIT -ne 0 ]]; then
  jq -n --arg msg "PHP formatting errors in $FILE_PATH:\n$FIX_OUTPUT" \
    '{ "systemMessage": $msg }'
fi
