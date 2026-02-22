#!/bin/bash
# claude-init: SessionStart hook — notify when tool has updates
# Checks .claude/.claude-init-version against current repo HEAD

# Resolve claude-init repo path from the global skill symlink
SKILL_LINK="$HOME/.claude/skills/claude-init"
if [[ ! -L "$SKILL_LINK" ]]; then
  exit 0
fi

SKILL_TARGET="$(readlink "$SKILL_LINK")"
REPO_ROOT="$(cd "$(dirname "$SKILL_TARGET")/../.." 2>/dev/null && pwd)"

if [[ ! -d "$REPO_ROOT/.git" ]]; then
  exit 0
fi

# Check for version stamp in the current project
VERSION_FILE="$PWD/.claude/.claude-init-version"
if [[ ! -f "$VERSION_FILE" ]]; then
  exit 0
fi

# Compare versions
CURRENT_VERSION="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null)"
PROJECT_VERSION="$(jq -r '.version // empty' "$VERSION_FILE" 2>/dev/null)"

if [[ -z "$CURRENT_VERSION" || -z "$PROJECT_VERSION" ]]; then
  exit 0
fi

if [[ "$CURRENT_VERSION" != "$PROJECT_VERSION" ]]; then
  echo "claude-init has updates since this project was configured (${PROJECT_VERSION} → ${CURRENT_VERSION}). Run /claude-init to upgrade."
fi
