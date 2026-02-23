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

# Clean up temp files on exit
TMPFILES=()
cleanup() { for f in "${TMPFILES[@]}"; do rm -f "$f" 2>/dev/null; done; }
trap cleanup EXIT

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

# Replace placeholder with actual repo path in patch
RESOLVED_PATCH=$(mktemp)
TMPFILES+=("$RESOLVED_PATCH")
sed "s|{{CLAUDE_INIT_DIR}}|$SCRIPT_DIR|g" "$PATCH_FILE" > "$RESOLVED_PATCH"

# Merge patch into settings (non-destructive — adds to arrays, doesn't overwrite)
MERGE_ERR=$(mktemp)
TMPFILES+=("$MERGE_ERR")
MERGED=$(jq -s '
  .[0] as $existing | .[1] as $patch |
  $existing * $patch |
  .permissions.allow = (
    (($existing.permissions.allow // []) + ($patch.permissions.allow // []))
    | unique
  ) |
  .permissions.deny = (
    (($existing.permissions.deny // []) + ($patch.permissions.deny // []))
    | unique
  ) |
  # Merge hooks arrays: append patch hooks to existing, deduplicate by command
  reduce ($patch.hooks | to_entries[]) as {$key, $value} (.;
    .hooks[$key] = (
      (($existing.hooks[$key] // []) + ($value // []))
      | group_by(.hooks[0].command)
      | map(last)
    )
  )
' "$SETTINGS_FILE" "$RESOLVED_PATCH" 2>"$MERGE_ERR")

rm -f "$RESOLVED_PATCH"

# Validate merged JSON before writing — never corrupt settings.json
if [[ -z "$MERGED" ]] || ! echo "$MERGED" | jq empty 2>/dev/null; then
  echo "  Error: Settings merge failed. Your settings were not modified."
  sed 's/^/  /' "$MERGE_ERR" >&2
  echo "  Backup available at: $BACKUP_FILE"
  exit 1
fi

# Atomic write — write to temp then move to prevent corruption on interrupted writes
SETTINGS_TMP=$(mktemp "$SETTINGS_FILE.tmp.XXXXXX")
TMPFILES+=("$SETTINGS_TMP")
printf '%s\n' "$MERGED" > "$SETTINGS_TMP"
mv "$SETTINGS_TMP" "$SETTINGS_FILE"

echo ""
echo "  Permissions merged into $SETTINGS_FILE"

# ── Step 3: Make global hooks executable ──

echo ""
echo "Step 3: Setting up global hooks"
echo ""

for hook_script in check-update.sh self-update.sh; do
  if [[ -f "$SCRIPT_DIR/global/$hook_script" ]]; then
    chmod +x "$SCRIPT_DIR/global/$hook_script"
    echo "  Made $hook_script executable"
  else
    echo "  Warning: $hook_script not found at $SCRIPT_DIR/global/$hook_script"
  fi
done
echo "  SessionStart hook will notify when projects need re-configuring"

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
echo "    Auto-approved: git reads, ls, gh CLI reads, --version, jq reads"
echo "    Auto-denied: rm -rf /, sudo rm, chmod 777, curl|bash"
echo ""
echo "  Version check hook (global)"
echo "    Notifies at session start when projects need re-configuring"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code for permission changes to take effect"
echo "  2. Open any project: cd ~/my-project && claude"
echo "  3. Run: /claude-init"
echo ""
echo "Global environment setup:"
echo "  Personalize your global Claude Code config: /claude-init global"
echo "  Sets up ~/.claude/CLAUDE.md, agents, commands, rules, and memory"
echo ""
echo "To update: /claude-init update (inside any Claude Code session)"
echo "To uninstall: bash $SCRIPT_DIR/uninstall.sh"
echo "Backup: $BACKUP_FILE"
