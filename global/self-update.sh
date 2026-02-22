#!/bin/bash
# claude-init: Self-update — fetch latest tag and checkout
# Called by SKILL.md when user runs `/claude-init update`
# Can also be run directly: bash ~/.claude-init/global/self-update.sh

set -euo pipefail

# Resolve claude-init repo path from the global skill symlink
SKILL_LINK="$HOME/.claude/skills/claude-init"
if [[ ! -L "$SKILL_LINK" ]]; then
  echo "Error: claude-init skill not installed (symlink not found at $SKILL_LINK)"
  exit 1
fi

SKILL_TARGET="$(readlink "$SKILL_LINK")"
REPO_ROOT="$(cd "$(dirname "$SKILL_TARGET")/../.." 2>/dev/null && pwd)"

if [[ ! -d "$REPO_ROOT/.git" ]]; then
  echo "Error: claude-init repo not found at $REPO_ROOT"
  exit 1
fi

# Get current local version
CURRENT_VERSION="$(git -C "$REPO_ROOT" describe --tags --abbrev=0 2>/dev/null || echo "unknown")"

# Fetch latest tags from origin
echo "Fetching tags from origin..."
git -C "$REPO_ROOT" fetch --tags origin 2>/dev/null

# Find latest tag sorted by version
LATEST_TAG="$(git -C "$REPO_ROOT" tag -l 'v*' --sort=-version:refname | head -1)"

if [[ -z "$LATEST_TAG" ]]; then
  echo "Error: No version tags found in the repository."
  echo "The repository may not have any releases yet."
  exit 1
fi

if [[ "$CURRENT_VERSION" == "$LATEST_TAG" ]]; then
  echo "claude-init is already up to date ($CURRENT_VERSION)."
  exit 0
fi

# Checkout the latest tag (detached HEAD)
git -C "$REPO_ROOT" checkout "$LATEST_TAG" 2>/dev/null

echo "Updated claude-init: $CURRENT_VERSION -> $LATEST_TAG"

# Reset the daily check timestamp so the next session sees fresh state
LAST_CHECK_FILE="$HOME/.claude/.claude-init-last-check"
if [[ -f "$LAST_CHECK_FILE" ]]; then
  rm -f "$LAST_CHECK_FILE"
fi
