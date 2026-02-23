#!/bin/bash
# Intentionally only set -u (not -e or pipefail) — this is a SessionStart hook
# that must never abort Claude Code's startup. Errors are silently swallowed
# so the user's session always starts cleanly.
set -u
# claude-init: SessionStart hook — notify when tool has updates
# Two-tier detection: local tag comparison + throttled remote check
#
# Tier 1 (every session, no network):
#   Compare project's stamped version against local `git describe --tags`
#
# Tier 2 (once per day, network):
#   Run `git ls-remote --tags origin` to discover latest remote tag
#   Store last-check epoch-day in ~/.claude/.claude-init-last-check
#
# Requires: git, jq, sort -V (GNU coreutils 7.0+ / macOS 12+)

# Opt-out: skip checks entirely
if [[ "${CLAUDE_INIT_NO_UPDATE_CHECK:-}" == "1" ]] || [[ "${CI:-}" == "true" ]]; then
  exit 0
fi

# Verify sort -V is available (GNU coreutils 7.0+ / macOS 12+)
if ! printf '1.0\n2.0\n' | sort -V >/dev/null 2>&1; then
  exit 0
fi

# Resolve claude-init repo path from the global skill symlink
SKILL_LINK="$HOME/.claude/skills/claude-init"
if [[ ! -L "$SKILL_LINK" ]]; then
  exit 0
fi

SKILL_TARGET="$(readlink "$SKILL_LINK")"
# Resolve relative symlink targets against symlink's parent directory
if [[ "$SKILL_TARGET" != /* ]]; then
  SKILL_TARGET="$(cd "$(dirname "$SKILL_LINK")" && cd "$(dirname "$SKILL_TARGET")" && pwd)/$(basename "$SKILL_TARGET")"
fi
REPO_ROOT="$(cd "$(dirname "$SKILL_TARGET")/.." 2>/dev/null && pwd)"

if [[ ! -d "$REPO_ROOT/.git" ]]; then
  exit 0
fi

# Get the current local tag version
LOCAL_VERSION="$(git -C "$REPO_ROOT" describe --tags --abbrev=0 2>/dev/null)"
if [[ -z "$LOCAL_VERSION" ]]; then
  exit 0
fi

# ── Tier 2: Throttled remote check (once per day) ──

LAST_CHECK_FILE="$HOME/.claude/.claude-init-last-check"
TODAY_EPOCH_DAY=$(( $(date +%s) / 86400 ))
LAST_CHECK_DAY=0

if [[ -f "$LAST_CHECK_FILE" ]]; then
  LAST_CHECK_DAY=$(cat "$LAST_CHECK_FILE" 2>/dev/null || echo 0)
fi

if ! [[ "$LAST_CHECK_DAY" =~ ^[0-9]+$ ]]; then
  LAST_CHECK_DAY=0
fi

if [[ "$TODAY_EPOCH_DAY" -gt "$LAST_CHECK_DAY" ]]; then
  # Fetch latest remote tag (hook timeout in settings-patch.json caps total runtime)
  REMOTE_TAGS="$(git -C "$REPO_ROOT" ls-remote --tags origin 'refs/tags/v*' 2>/dev/null || true)"

  if [[ -n "$REMOTE_TAGS" ]]; then
    # Extract tag names, sort by version, take the latest
    LATEST_REMOTE="$(echo "$REMOTE_TAGS" \
      | sed 's|.*refs/tags/||' \
      | grep -v '\^{}$' \
      | sort -V \
      | tail -1)"

    if [[ -n "$LATEST_REMOTE" && "$LATEST_REMOTE" != "$LOCAL_VERSION" ]]; then
      # Compare versions: only notify if remote is actually newer
      HIGHER="$(printf '%s\n%s\n' "$LOCAL_VERSION" "$LATEST_REMOTE" | sort -V | tail -1)"
      if [[ "$HIGHER" == "$LATEST_REMOTE" && "$HIGHER" != "$LOCAL_VERSION" ]]; then
        echo "claude-init $LATEST_REMOTE available (you have $LOCAL_VERSION). Run: /claude-init update"
      fi
    fi
  fi

  # Update last-check timestamp regardless of result
  mkdir -p "$HOME/.claude"
  echo "$TODAY_EPOCH_DAY" > "$LAST_CHECK_FILE"
fi

# ── Tier 1: Local check (every session) ──

VERSION_FILE="$PWD/.claude/.claude-init-version"
if [[ ! -f "$VERSION_FILE" ]]; then
  exit 0
fi

PROJECT_VERSION="$(jq -r '.version // empty' "$VERSION_FILE" 2>/dev/null)"

if [[ -z "$PROJECT_VERSION" ]]; then
  exit 0
fi

if [[ "$LOCAL_VERSION" != "$PROJECT_VERSION" ]]; then
  # Only notify if local is newer than project stamp (tool was updated)
  HIGHER="$(printf '%s\n%s\n' "$PROJECT_VERSION" "$LOCAL_VERSION" | sort -V | tail -1)"
  if [[ "$HIGHER" == "$LOCAL_VERSION" && "$HIGHER" != "$PROJECT_VERSION" ]]; then
    echo "claude-init updated to $LOCAL_VERSION (project configured with $PROJECT_VERSION). Run /claude-init to upgrade this project."
  fi
fi
