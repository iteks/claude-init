#!/bin/bash
set -uo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0
SKIP=0

# Helper functions
pass() {
  echo -e "${GREEN}[PASS]${NC} $1"
  PASS=$((PASS + 1))
}

fail() {
  echo -e "${RED}[FAIL]${NC} $1"
  FAIL=$((FAIL + 1))
}

skip() {
  echo -e "${YELLOW}[SKIP]${NC} $1"
  SKIP=$((SKIP + 1))
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Running claude-init validation tests..."
echo ""

# ============================================================================
# 1. JSON Validation
# ============================================================================
echo "=== JSON Validation ==="

# Validate template JSON files
while IFS= read -r -d '' json_file; do
  rel_path="${json_file#"$SCRIPT_DIR"/}"
  if jq . "$json_file" > /dev/null 2>&1; then
    pass "Valid JSON: $rel_path"
  else
    fail "Invalid JSON: $rel_path - jq parse failed"
  fi
done < <(find "$SCRIPT_DIR/skills/claude-init/templates" -name "*.json" -print0)

# Validate global settings patch
if [[ -f "$SCRIPT_DIR/global/settings-patch.json" ]]; then
  if jq . "$SCRIPT_DIR/global/settings-patch.json" > /dev/null 2>&1; then
    pass "Valid JSON: global/settings-patch.json"
  else
    fail "Invalid JSON: global/settings-patch.json - jq parse failed"
  fi
else
  skip "global/settings-patch.json not found"
fi

# Validate .claude/settings.json if it exists
if [[ -f "$SCRIPT_DIR/.claude/settings.json" ]]; then
  if jq . "$SCRIPT_DIR/.claude/settings.json" > /dev/null 2>&1; then
    pass "Valid JSON: .claude/settings.json"
  else
    fail "Invalid JSON: .claude/settings.json - jq parse failed"
  fi
else
  skip ".claude/settings.json not found"
fi

echo ""

# ============================================================================
# 2. Shell Script Lint
# ============================================================================
echo "=== Shell Script Lint ==="

if command -v shellcheck > /dev/null 2>&1; then
  # Check hook scripts
  while IFS= read -r -d '' sh_file; do
    rel_path="${sh_file#"$SCRIPT_DIR"/}"
    if shellcheck -S error "$sh_file" > /dev/null 2>&1; then
      pass "shellcheck: $rel_path"
    else
      fail "shellcheck: $rel_path - errors found"
    fi
  done < <(find "$SCRIPT_DIR/skills/claude-init/templates/hooks" -name "*.sh" -print0)

  # Check root scripts
  for script in install.sh uninstall.sh global/check-update.sh; do
    if [[ -f "$SCRIPT_DIR/$script" ]]; then
      if shellcheck -S error "$SCRIPT_DIR/$script" > /dev/null 2>&1; then
        pass "shellcheck: $script"
      else
        fail "shellcheck: $script - errors found"
      fi
    else
      skip "shellcheck: $script - file not found"
    fi
  done
else
  skip "shellcheck not available - shell script linting skipped"
fi

echo ""

# ============================================================================
# 3. Hook Pattern Consistency
# ============================================================================
echo "=== Hook Pattern Consistency ==="

while IFS= read -r -d '' hook_file; do
  rel_path="${hook_file#"$SCRIPT_DIR"/}"

  # Check shebang
  if head -n 1 "$hook_file" | grep -q '^#!/bin/bash'; then
    pass "Shebang check: $rel_path"
  else
    fail "Shebang check: $rel_path - missing or incorrect shebang"
  fi

  # Check stdin reading pattern
  if grep -q 'INPUT=$(cat)' "$hook_file"; then
    pass "Stdin pattern: $rel_path"
  else
    fail "Stdin pattern: $rel_path - missing INPUT=\$(cat)"
  fi

  # Check jq usage
  if grep -q 'jq -r' "$hook_file" || grep -q 'jq -n' "$hook_file"; then
    pass "jq usage: $rel_path"
  else
    fail "jq usage: $rel_path - missing jq -r or jq -n"
  fi
done < <(find "$SCRIPT_DIR/skills/claude-init/templates/hooks" -name "*.sh" -print0)

echo ""

# ============================================================================
# 4. Agent Frontmatter Validation
# ============================================================================
echo "=== Agent Frontmatter Validation ==="

while IFS= read -r -d '' agent_file; do
  rel_path="${agent_file#"$SCRIPT_DIR"/}"

  # Check frontmatter exists
  if head -n 1 "$agent_file" | grep -q '^---$'; then
    pass "Frontmatter exists: $rel_path"
  else
    fail "Frontmatter exists: $rel_path - missing YAML frontmatter"
    continue
  fi

  # Extract frontmatter (between first two --- markers)
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$agent_file" | sed '1d;$d')

  # Check required fields
  required_fields=("name:" "description:" "model:" "tools:")
  for field in "${required_fields[@]}"; do
    if echo "$frontmatter" | grep -q "^$field"; then
      pass "Field '$field' present: $rel_path"
    else
      fail "Field '$field' present: $rel_path - missing required field"
    fi
  done
done < <(find "$SCRIPT_DIR/skills/claude-init/templates/agents" -name "*.md" -print0)

echo ""

# ============================================================================
# 5. Rule Frontmatter Validation
# ============================================================================
echo "=== Rule Frontmatter Validation ==="

while IFS= read -r -d '' rule_file; do
  rel_path="${rule_file#"$SCRIPT_DIR"/}"

  # Check frontmatter exists
  if head -n 1 "$rule_file" | grep -q '^---$'; then
    pass "Frontmatter exists: $rel_path"
  else
    fail "Frontmatter exists: $rel_path - missing YAML frontmatter"
    continue
  fi

  # Extract frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$rule_file" | sed '1d;$d')

  # Check for paths: field
  if echo "$frontmatter" | grep -q '^paths:'; then
    pass "Field 'paths:' present: $rel_path"
  else
    fail "Field 'paths:' present: $rel_path - missing required field"
  fi
done < <(find "$SCRIPT_DIR/skills/claude-init/templates/rules" -name "*.md" -print0)

echo ""

# ============================================================================
# 6. Template Count Verification
# ============================================================================
echo "=== Template Count Verification ==="

check_count() {
  local category="$1" expected="$2" pattern="$3" dir="$4"
  local actual
  actual=$(find "$SCRIPT_DIR/skills/claude-init/templates/$dir" -name "$pattern" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$actual" -eq "$expected" ]]; then
    pass "Template count: $category ($actual/$expected)"
  else
    fail "Template count: $category - expected $expected, found $actual"
  fi
}

check_count "settings" 6 "*.json" "settings"
check_count "hooks" 11 "*.sh" "hooks"
check_count "rules" 9 "*.md" "rules"
check_count "agents" 15 "*.md" "agents"
check_count "claude-md" 6 "*.md" "claude-md"
check_count "skills" 5 "*.md" "skills"
check_count "commands" 3 "*.md" "commands"
check_count "mcp" 4 "*.json" "mcp"

echo ""

# ============================================================================
# Summary
# ============================================================================
echo "========================================"
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped"
echo "========================================"

if [[ $FAIL -gt 0 ]]; then
  exit 1
else
  exit 0
fi
