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
    echo "  Skipped — will clean up individual entries instead"
    CLEAN_PERMISSIONS=true
  fi
else
  echo "  No backup files found."
  CLEAN_PERMISSIONS=true
fi

# ── Step 2b: Remove claude-init permission entries ──

if [[ "${CLEAN_PERMISSIONS:-false}" == "true" ]] && [[ -f "$SETTINGS_FILE" ]] && command -v jq &>/dev/null; then
  echo ""
  echo "Step 2b: Removing claude-init permission entries"

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PATCH_FILE="$SCRIPT_DIR/global/settings-patch.json"

  if [[ -f "$PATCH_FILE" ]]; then
    # Remove allow entries that were added by claude-init
    PATCH_ALLOWS=$(jq -r '.permissions.allow // [] | .[]' "$PATCH_FILE" 2>/dev/null)
    PATCH_DENIES=$(jq -r '.permissions.deny // [] | .[]' "$PATCH_FILE" 2>/dev/null)

    CLEANED=$(jq --argjson patch_allows "$(jq '.permissions.allow // []' "$PATCH_FILE")" \
                  --argjson patch_denies "$(jq '.permissions.deny // []' "$PATCH_FILE")" '
      .permissions.allow = ([.permissions.allow // [] | .[] | select(. as $item | $patch_allows | index($item) | not)]) |
      .permissions.deny = ([.permissions.deny // [] | .[] | select(. as $item | $patch_denies | index($item) | not)]) |
      if .permissions.allow | length == 0 then del(.permissions.allow) else . end |
      if .permissions.deny | length == 0 then del(.permissions.deny) else . end |
      if .permissions | length == 0 then del(.permissions) else . end
    ' "$SETTINGS_FILE")
    echo "$CLEANED" > "$SETTINGS_FILE"
    echo "  Removed claude-init permission entries from settings"
  else
    echo "  Patch file not found — skipping permission cleanup"
    echo "  You can manually edit $SETTINGS_FILE to remove unwanted permissions."
  fi

  # Remove env and teammateMode entries
  if jq -e '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' "$SETTINGS_FILE" &>/dev/null; then
    CLEANED=$(jq '
      del(.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS) |
      if .env | length == 0 then del(.env) else . end |
      del(.teammateMode) |
      if . == {} then . else . end
    ' "$SETTINGS_FILE")
    echo "$CLEANED" > "$SETTINGS_FILE"
    echo "  Removed Agent Teams configuration"
  fi
fi

echo ""

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
