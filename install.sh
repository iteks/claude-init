#!/bin/bash
set -euo pipefail

# claude-init: Install global skill + permission optimization
# Creates a symlink so /claude-init is available in every project
# Merges read-only permission pre-approvals into ~/.claude/settings.json

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SOURCE="$SCRIPT_DIR/skills/claude-init"
SKILL_TARGET="$HOME/.claude/skills/claude-init"
SETTINGS_FILE="$HOME/.claude/settings.json"
PATCH_FILE="$SCRIPT_DIR/global/settings-patch.json"
BACKUP_FILE="$SETTINGS_FILE.backup.$(date +%Y%m%d%H%M%S)"

echo "=============================================="
echo "  claude-init"
echo "  Stop configuring Claude Code manually."
echo "=============================================="
echo ""

# Check prerequisites
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed."
  echo "  Install: brew install jq (macOS) or apt install jq (Linux)"
  exit 1
fi

if [[ ! -f "$PATCH_FILE" ]]; then
  echo "Error: Settings patch not found: $PATCH_FILE"
  echo "  Are you running this from the claude-init directory?"
  exit 1
fi

if [[ ! -d "$SKILL_SOURCE" ]]; then
  echo "Error: Skill directory not found: $SKILL_SOURCE"
  exit 1
fi

# ── Step 1: Install the /claude-init skill globally ──

echo "Step 1: Installing /claude-init skill"
echo ""

mkdir -p "$HOME/.claude/skills"

if [[ -L "$SKILL_TARGET" ]]; then
  EXISTING_LINK=$(readlink "$SKILL_TARGET")
  if [[ "$EXISTING_LINK" == "$SKILL_SOURCE" ]]; then
    echo "  Skill already installed (symlink exists)"
  else
    echo "  Updating existing symlink"
    echo "    Old: $EXISTING_LINK"
    echo "    New: $SKILL_SOURCE"
    rm "$SKILL_TARGET"
    ln -s "$SKILL_SOURCE" "$SKILL_TARGET"
    echo "  Symlink updated"
  fi
elif [[ -d "$SKILL_TARGET" ]]; then
  echo "  Warning: $SKILL_TARGET already exists as a directory."
  echo "  Skipping symlink creation to avoid overwriting."
  echo "  Remove it manually if you want to use the symlink instead."
else
  ln -s "$SKILL_SOURCE" "$SKILL_TARGET"
  echo "  Symlinked: $SKILL_TARGET -> $SKILL_SOURCE"
fi

echo ""

# ── Step 2: Merge global permission settings ──

echo "Step 2: Configuring global permissions"
echo ""

mkdir -p "$HOME/.claude"

# Create settings.json if it doesn't exist
if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "{}" > "$SETTINGS_FILE"
  echo "  Created $SETTINGS_FILE"
fi

# Backup existing settings
cp "$SETTINGS_FILE" "$BACKUP_FILE"
echo "  Backed up settings to $BACKUP_FILE"

# Merge patch into settings (non-destructive — adds to arrays, doesn't overwrite)
MERGED=$(jq -s '
  def merge_arrays:
    . as [$a, $b] |
    if ($a | type) == "array" and ($b | type) == "array"
    then ($a + $b) | unique
    elif ($b | type) == "object" and ($a | type) == "object"
    then $a * $b
    else $b
    end;

  .[0] as $existing | .[1] as $patch |
  $existing * $patch |
  if ($existing.permissions.allow // [] | length) > 0 and ($patch.permissions.allow // [] | length) > 0
  then .permissions.allow = ([$existing.permissions.allow, $patch.permissions.allow] | merge_arrays)
  else . end |
  if ($existing.permissions.deny // [] | length) > 0 and ($patch.permissions.deny // [] | length) > 0
  then .permissions.deny = ([$existing.permissions.deny, $patch.permissions.deny] | merge_arrays)
  else . end
' "$SETTINGS_FILE" "$PATCH_FILE")

echo "$MERGED" > "$SETTINGS_FILE"

echo ""
echo "  Permissions merged into $SETTINGS_FILE"

# ── Summary ──

echo ""
echo "=============================================="
echo "  Installation complete"
echo "=============================================="
echo ""
echo "What was installed:"
echo ""
echo "  /claude-init skill (global)"
echo "    Available in every project via: /claude-init"
echo "    Symlink: ~/.claude/skills/claude-init"
echo ""
echo "  Permission pre-approvals (global)"
echo "    Auto-approved: git reads, ls, gh CLI reads, --version, jq"
echo "    Auto-denied: rm -rf /, sudo rm, chmod 777, curl|bash"
echo ""
echo "  Agent Teams (global)"
echo "    Multi-agent orchestration via tmux enabled"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code for permission changes to take effect"
echo "  2. Open any project: cd ~/my-project && claude"
echo "  3. Run: /claude-init"
echo ""
echo "To update: cd $SCRIPT_DIR && git pull"
echo "To uninstall: bash $SCRIPT_DIR/uninstall.sh"
echo "Backup: $BACKUP_FILE"
