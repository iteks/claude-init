# Claude Init

Analyze any project and generate optimal Claude Code integration — hooks, rules, agents, skills, settings, and CLAUDE.md. Works for new projects, existing projects without config, and projects with existing Claude Code setup.

---

## Instructions

You are the `claude-init` skill. When invoked, follow this complete workflow.

### Pre-check: Global Settings

Before project analysis, quickly check if `~/.claude/settings.json` has permission pre-approvals (look for `Bash(git status*)` in `permissions.allow`). If not found, display:

```
Tip: Global permission optimizations not detected.
     Run: bash ~/.claude-init/install.sh
     This auto-approves read-only commands and adds safety denials.
```

This is informational only — continue to Phase 1 regardless.

### Phase 1: Detect Current State

Determine which mode to operate in:

1. **Check for existing `.claude/` directory** in the project root
2. **Check for existing `CLAUDE.md`** in the project root
3. **Check if the project has any source code** (not an empty repo)

Based on findings, enter one of three modes:

| Condition | Mode |
|---|---|
| No source code, no `.claude/` | **New Project Mode** |
| Source code exists, no `.claude/` | **Existing Project Mode** |
| `.claude/` directory exists | **Audit Mode** |

Announce which mode you're entering and why.

---

### Phase 2A: New Project Mode

The project is empty or has minimal boilerplate. Prompt the user to understand their intent.

**Ask these questions** (use `AskUserQuestion` tool):

1. **Project type**: Web app, API, Mobile app, CLI tool, Library/Package, Monorepo
2. **Primary framework**: Based on project type, offer relevant options:
   - Web app: Next.js, Nuxt, SvelteKit, Laravel, Django, Rails, Astro
   - API: Laravel, Django/DRF, FastAPI, Express, Go/Gin, Rust/Axum
   - Mobile: Expo/React Native, Flutter, Swift, Kotlin
   - CLI: Node.js, Python, Go, Rust
   - Library: Node.js, Python, Go, Rust
3. **Brief description**: What will this project do? (free text)
4. **Testing preference**: Based on framework, offer relevant options:
   - PHP: Pest, PHPUnit
   - JS/TS: Jest, Vitest
   - Python: pytest, unittest
   - Go: built-in testing
   - Rust: built-in testing

**After gathering answers**, proceed to Phase 3 using the selected framework to choose templates.

---

### Phase 2B: Existing Project Mode

The project has source code but no Claude Code configuration. Detect the stack automatically.

**Detection sequence** — check for these files/patterns:

#### Language Detection
| Check | Language |
|---|---|
| `composer.json` | PHP |
| `package.json` | JavaScript/TypeScript |
| `pyproject.toml` OR `requirements.txt` OR `setup.py` | Python |
| `go.mod` | Go |
| `Cargo.toml` | Rust |

#### Framework Detection
| Check | Framework |
|---|---|
| `artisan` file + `composer.json` has `laravel/framework` | Laravel |
| `next.config.*` OR `package.json` has `next` | Next.js |
| `app.config.*` + `package.json` has `expo` | Expo |
| `nuxt.config.*` OR `package.json` has `nuxt` | Nuxt |
| `manage.py` + settings with `django` | Django |
| `package.json` has `fastapi` OR `pyproject.toml` has `fastapi` | FastAPI |

#### Test Framework Detection
| Check | Test Framework |
|---|---|
| `composer.json` has `pestphp/pest` | Pest |
| `composer.json` has `phpunit/phpunit` (without Pest) | PHPUnit |
| `package.json` has `jest` | Jest |
| `package.json` has `vitest` | Vitest |
| `pyproject.toml` has `pytest` OR `pytest.ini` exists | pytest |

#### Formatter/Linter Detection
| Check | Tool |
|---|---|
| `composer.json` has `tightenco/duster` | Duster |
| `composer.json` has `laravel/pint` | Pint |
| `package.json` has `eslint` | ESLint |
| `package.json` has `prettier` | Prettier |
| `pyproject.toml` has `ruff` OR `ruff.toml` exists | ruff |
| `pyproject.toml` has `black` | black |
| Go project (any) | gofmt (built-in) |
| Rust project (any) | rustfmt (built-in) |

#### Package Manager Detection
| Check | Manager |
|---|---|
| `bun.lockb` OR `bun.lock` | bun |
| `pnpm-lock.yaml` | pnpm |
| `yarn.lock` | yarn |
| `package-lock.json` | npm |
| `Pipfile.lock` | pipenv |
| `poetry.lock` | poetry |
| `uv.lock` | uv |

**Convention extraction** — read a few representative source files to detect:
- Indentation style (tabs vs spaces, how many)
- Naming conventions (camelCase, snake_case, PascalCase)
- Import style and organization
- Directory structure patterns

**Report findings** to the user before proceeding:
```
Detected stack:
  Language:    PHP 8.3
  Framework:   Laravel 12
  Testing:     Pest
  Formatter:   Duster
  Package Mgr: Composer

Proceed with generating Claude Code config? [Yes / Customize / Skip]
```

Then proceed to Phase 3.

---

### Phase 2C: Audit Mode

The project already has `.claude/` configuration. Scan for gaps and improvements.

**Scan the following categories:**

#### 1. Hooks Audit
- Read `.claude/settings.json` (or `.claude/settings.local.json`) for existing hooks
- Check for **missing hooks** based on detected stack:
  - Format-on-save hook for the detected formatter (Duster, Pint, ESLint, Prettier, ruff, black, gofmt, rustfmt)
  - `guard-env.sh` — blocks `.env` edits
  - `guard-git-push.sh` — prompts before `git push`
  - `guard-config-files.sh` — prompts before modifying config files (JS/TS projects)
  - Migration guard — blocks `migrate:fresh`/`migrate:reset` (Laravel/Django)
- Check that hook scripts referenced in settings **actually exist** on disk
- Check that hook scripts are **executable** (`chmod +x`)

#### 2. Rules Audit
- Read all files in `.claude/rules/`
- Check for **missing rules** based on detected directories:
  - `tests/` directory exists: needs testing conventions rule
  - `database/migrations/` exists: needs migration safety rule
  - `app/Http/Controllers/Api/` or `routes/api/` exists: needs API conventions rule
  - `src/components/` or `components/` exists: needs component conventions rule
- Check for **dead rules** — read each rule's `paths:` frontmatter and verify the glob patterns match actual files in the project using `Glob`
- Report dead rules with the non-matching patterns

#### 3. CLAUDE.md Audit
- Count lines in `CLAUDE.md`
- If **over 300 lines**: warn that Claude may start ignoring rules; recommend splitting into path-scoped rules and skills
- Check for **missing sections**:
  - Stack description
  - Local development instructions
  - Architecture overview
  - Conventions
  - Workflow Automation (plan mode triggers, post-implementation review, context management)
- Check for **Workflow Automation section** specifically — this is the most commonly missing section

#### 4. Agents Audit
- Read all files in `.claude/agents/` (if directory exists)
- Check for **missing agents** based on stack:
  - All projects: security-reviewer agent
  - JS/TS projects: api-reviewer agent (if API layer exists)

#### 5. Settings Audit
- Read `.claude/settings.json`
- Check for **missing or incomplete settings**:
  - `permissions.defaultMode` — should be set to `"plan"` for complex stacks (Laravel, Django)
  - Hook definitions — ensure all hooks reference scripts that exist
  - MCP server configurations (`.mcp.json`) — check if project uses any MCP servers
- Check for `.claude/settings.local.json` — if it exists, verify it's in `.gitignore`
- Check for permission optimizations (read-only command pre-approvals in global `~/.claude/settings.json`)

#### 6. Config Hygiene
- Check if `.claude/settings.local.json` is in `.gitignore`
- Check if `.env` is in `.gitignore`
- Check for any sensitive data patterns in `.claude/` files

**Output the audit report** in this format:

```
Claude Code Integration Audit — [project path]

Stack: [detected stack summary]

Hooks
  [checkmark] [existing hook description]
  [x] Missing: [missing hook] ([reason])

Rules
  [checkmark] [existing rule] (paths match [checkmark])
  [x] Missing: [missing rule] ([reason])
  [warning] Dead rule: [rule name] — pattern "[glob]" matches no files

CLAUDE.md
  [checkmark] [line count] lines (within limit)  OR  [warning] [count] lines — recommend splitting
  [x] Missing: [section name]

Agents
  [checkmark] [existing agent]
  [x] Missing: [missing agent]

Settings
  [checkmark] [setting description]
  [x] Missing: [missing setting] ([reason])
  [warning] settings.local.json not in .gitignore

Fix all gaps? [Yes / Pick individually / Skip]
```

If the user chooses to fix, proceed to Phase 3 in **merge mode** (only create missing files, never overwrite existing ones).

---

### Phase 3: Generate Configuration

Based on the detected/selected framework, generate the Claude Code configuration.

#### Template Selection

Templates are located at `./templates/` relative to this SKILL.md file. Read the appropriate template files for the detected stack:

| Stack | Settings | Hooks | Rules | CLAUDE.md | Agent |
|---|---|---|---|---|---|
| PHP/Laravel | `php-laravel.json` | `universal/*`, `php/format-php.sh` | `php/*` | `php-laravel.md` | `security-reviewer-php.md` |
| JS/Next.js | `js-nextjs.json` | `universal/*`, `javascript/*` | `javascript/*` | `js-nextjs.md` | `security-reviewer-js.md` |
| JS/Expo | `js-expo.json` | `universal/*`, `javascript/*` | `javascript/*` | `js-expo.md` | `security-reviewer-js.md` |
| Python/Django | `python-django.json` | `universal/*`, `python/format-python.sh` | `python/*` | `python-django.md` | `security-reviewer-python.md` |
| Python/FastAPI | `python-fastapi.json` | `universal/*`, `python/format-python.sh` | `python/*` | `python-fastapi.md` | `security-reviewer-python.md` |
| Go | `generic.json` | `universal/*`, `go/format-go.sh` | — | `generic.md` | `security-reviewer-generic.md` |
| Rust | `generic.json` | `universal/*`, `rust/format-rust.sh` | — | `generic.md` | `security-reviewer-generic.md` |
| Other | `generic.json` | `universal/*` | — | `generic.md` | `security-reviewer-generic.md` |

#### File Generation

Create these files in the project (skip any that already exist in merge mode):

**1. `.claude/settings.json`**
- Read the template for the detected stack
- Adjust hook paths to match project structure
- For Laravel monorepos with a `laravel/` subdirectory, adjust paths accordingly

**2. `.claude/hooks/` directory**
- Copy relevant hook scripts from templates
- Adjust the project root detection logic if needed (e.g., `composer.json` location for PHP, `package.json` for JS)
- Make all hook scripts executable: `chmod +x`

**3. `.claude/rules/` directory**
- Copy relevant rule templates
- **Validate glob patterns**: For each rule's `paths:` frontmatter, verify the glob patterns match actual files in the project. If a template's default path doesn't match (e.g., template has `tests/**` but project uses `test/**`), adjust the glob pattern to match the actual directory structure.

**4. `.claude/agents/` directory**
- Copy the security-reviewer agent for the detected stack
- Adjust tool permissions if needed

**5. `CLAUDE.md`**
- Read the template for the detected stack
- Replace all `{{PLACEHOLDER}}` markers with detected/provided values:
  - `{{PROJECT_NAME}}` — from directory name or user input
  - `{{PROJECT_DESCRIPTION}}` — from user input or package.json/composer.json description
  - `{{PHP_VERSION}}`, `{{LARAVEL_VERSION}}`, etc. — from detected versions
  - `{{DEV_URL}}`, `{{DEV_COMMAND}}` — from project config or common defaults
  - `{{FORMATTER}}`, `{{FORMATTER_COMMAND}}` — from detected formatter
  - `{{ARCHITECTURE_NOTES}}` — from reading source code structure
  - `{{CONVENTIONS}}` — from detected coding conventions
- Ensure the final CLAUDE.md is **under 300 lines**
- If content exceeds 300 lines, move detailed conventions into path-scoped rules instead
- **Always include the Workflow Automation section** — this is the most impactful section for daily productivity

**6. `.gitignore` updates**
- If `.gitignore` exists, check if it contains `.claude/settings.local.json`
- If not, suggest adding it (don't modify .gitignore without confirmation)

#### Merge Mode Behavior (Audit fixes)

When fixing audit gaps:
- **Never overwrite** existing files
- Add missing hooks alongside existing ones in settings.json (merge the hooks arrays)
- Add missing rules as new files
- Add missing agents as new files
- Append missing sections to CLAUDE.md only if it stays under 300 lines
- If CLAUDE.md would exceed 300 lines, create the content as a path-scoped rule instead
- Merge missing settings entries into settings.json (hooks, permissions)

---

### Phase 4: Validate

After generating all files, validate:

1. **Hook scripts are executable**: Run `ls -la .claude/hooks/` and verify the `x` permission bit
2. **JSON files are valid**: Read each `.json` file and verify it parses correctly
3. **Rule paths match files**: For each rule, run the glob pattern and verify matches exist
4. **CLAUDE.md line count**: Verify under 300 lines
5. **No duplicate hooks**: Check settings.json doesn't have duplicate hook entries
6. **Hook scripts exist**: Every script referenced in settings.json exists on disk

Fix any validation errors automatically.

---

### Phase 5: Report

Output a summary of everything that was created or modified:

```
Claude Code configuration generated for [project name]

Project config created:
  .claude/settings.json      — hooks, permissions, settings
  .claude/hooks/
    guard-git-push.sh         — prompts before git push
    guard-env.sh              — blocks .env edits
    format-php.sh             — auto-formats PHP with Duster
  .claude/rules/
    testing-pest.md           — Pest testing conventions (tests/**)
    migration-safety.md       — migration safety rules (database/migrations/**)
    api-conventions.md        — API conventions (app/Http/Controllers/Api/**)
  .claude/agents/
    security-reviewer.md      — PHP security review agent
  CLAUDE.md                   — project overview + conventions (187 lines)

Next steps:
  1. Review the generated CLAUDE.md and adjust any placeholders
  2. Add project-specific conventions to CLAUDE.md
  3. Consider adding custom skills for repeated workflows
  4. Run: git add .claude/ CLAUDE.md && git commit -m "Add Claude Code configuration"
```

If in audit mode, also show what was fixed vs. what was skipped.

---

## Important Notes

- This skill generates configuration that makes Claude Code work better with the project. It does NOT modify source code.
- All generated hooks use `jq` for JSON processing — this is a standard tool available on most systems.
- The Workflow Automation section in CLAUDE.md is critical — it teaches Claude when to plan, when to review, and when to suggest context management. Always include it.
- Templates are starting points. Encourage the user to customize after generation.
- For monorepos, detect the project structure and adjust paths accordingly (e.g., `laravel/` subdirectory for Laravel projects within a monorepo).
