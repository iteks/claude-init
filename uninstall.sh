#!/bin/bash
set -euo pipefail

# claude-init: Uninstall global skill + revert permission settings

SKILL_TARGET="$HOME/.claude/skills/claude-init"
SETTINGS_FILE="$HOME/.claude/settings.json"

echo "=============================================="
echo "  claude-init — Uninstall"
echo "=============================================="
echo ""

# ── Step 1: Remove the /claude-init skill symlink ──

echo "Step 1: Removing /claude-init skill"

if [[ -L "$SKILL_TARGET" ]]; then
  rm "$SKILL_TARGET"
  echo "  Removed symlink: $SKILL_TARGET"
elif [[ -d "$SKILL_TARGET" ]]; then
  echo "  $SKILL_TARGET is a directory, not a symlink."
  echo "  Skipping — remove manually if desired."
else
  echo "  Skill not installed (symlink not found)"
fi

echo ""

# ── Step 2: Revert global settings ──

echo "Step 2: Reverting global settings"

LATEST_BACKUP=$(ls -t "$SETTINGS_FILE".backup.* 2>/dev/null | head -1)

if [[ -n "$LATEST_BACKUP" ]]; then
  echo "  Found backup: $LATEST_BACKUP"
  read -p "  Restore this backup? (y/N) " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    cp "$LATEST_BACKUP" "$SETTINGS_FILE"
    echo "  Restored settings from backup"
  else
    echo "  Skipped — settings not reverted"
  fi
else
  echo "  No backup files found."
  echo "  You can manually edit $SETTINGS_FILE to remove unwanted permissions."
fi

# ── Step 3: Remove SessionStart hook from global settings ──

echo "Step 3: Removing SessionStart hook"

if [[ -f "$SETTINGS_FILE" ]] && command -v jq &>/dev/null; then
  if jq -e '.hooks.SessionStart' "$SETTINGS_FILE" &>/dev/null; then
    CLEANED=$(jq '
      .hooks.SessionStart = [
        .hooks.SessionStart[] |
        .hooks = [.hooks[] | select(.command | test("check-update\\.sh") | not)] |
        select(.hooks | length > 0)
      ] |
      if .hooks.SessionStart | length == 0 then del(.hooks.SessionStart) else . end |
      if .hooks | length == 0 then del(.hooks) else . end
    ' "$SETTINGS_FILE")
    echo "$CLEANED" > "$SETTINGS_FILE"
    echo "  Removed check-update.sh hook from settings"
  else
    echo "  No SessionStart hooks found"
  fi
else
  echo "  Skipped — jq not available or settings file not found"
fi

echo ""
echo "Uninstall complete."
echo "Restart Claude Code for changes to take effect."
