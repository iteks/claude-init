#!/bin/bash
set -euo pipefail

# claude-init: Uninstall global skill + revert permission settings

SKILL_TARGET="$HOME/.claude/skills/claude-init"
SETTINGS_FILE="$HOME/.claude/settings.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Clean up temp files on exit
TMPFILES=()
cleanup() { for f in "${TMPFILES[@]}"; do rm -f "$f" 2>/dev/null; done; }
trap cleanup EXIT

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

LATEST_BACKUP=$(ls -t "$SETTINGS_FILE".backup.* 2>/dev/null | head -1 || true)

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

  # Create backup before modifying
  BACKUP_FILE="$SETTINGS_FILE.pre-uninstall.$(date +%Y%m%d%H%M%S)"
  cp "$SETTINGS_FILE" "$BACKUP_FILE"
  echo "  Backed up settings to $BACKUP_FILE"

  PATCH_FILE="$SCRIPT_DIR/global/settings-patch.json"

  if [[ -f "$PATCH_FILE" ]]; then
    # Resolve placeholder before comparing — the installed settings have the actual path
    RESOLVED_PATCH=$(mktemp)
    TMPFILES+=("$RESOLVED_PATCH")
    sed "s|{{CLAUDE_INIT_DIR}}|$SCRIPT_DIR|g" "$PATCH_FILE" > "$RESOLVED_PATCH"

    # Remove allow/deny entries, env, teammateMode, and SessionStart hook in one pass
    CLEANED=$(jq --argjson patch_allows "$(jq '.permissions.allow // []' "$RESOLVED_PATCH")" \
                  --argjson patch_denies "$(jq '.permissions.deny // []' "$RESOLVED_PATCH")" '
      .permissions.allow = ([.permissions.allow // [] | .[] | select(. as $item | $patch_allows | index($item) | not)]) |
      .permissions.deny = ([.permissions.deny // [] | .[] | select(. as $item | $patch_denies | index($item) | not)]) |
      if .permissions.allow | length == 0 then del(.permissions.allow) else . end |
      if .permissions.deny | length == 0 then del(.permissions.deny) else . end |
      if (.permissions | length == 0) or (.permissions == {"defaultMode": .permissions.defaultMode} and (.permissions.defaultMode == null)) then del(.permissions) else . end |
      del(.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS) |
      if (.env // {} | length) == 0 then del(.env) else . end |
      del(.teammateMode) |
      if .hooks.SessionStart then
        .hooks.SessionStart = [
          .hooks.SessionStart[] |
          .hooks = [.hooks[] | select(.command | test("check-update\\.sh") | not)] |
          select(.hooks | length > 0)
        ] |
        if .hooks.SessionStart | length == 0 then del(.hooks.SessionStart) else . end |
        if (.hooks // {} | length) == 0 then del(.hooks) else . end
      else . end
    ' "$SETTINGS_FILE")

    # Atomic write
    SETTINGS_TMP=$(mktemp "$SETTINGS_FILE.tmp.XXXXXX")
    TMPFILES+=("$SETTINGS_TMP")
    printf '%s\n' "$CLEANED" > "$SETTINGS_TMP"
    mv "$SETTINGS_TMP" "$SETTINGS_FILE"
    echo "  Removed claude-init permission entries from settings"
    echo "  Removed Agent Teams configuration"
    echo "  Removed SessionStart hook"
  else
    echo "  Patch file not found — skipping permission cleanup"
    echo "  You can manually edit $SETTINGS_FILE to remove unwanted permissions."
  fi
fi

echo ""
echo "Uninstall complete."
echo "Restart Claude Code for changes to take effect."
