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

**Before proceeding to Phase 3**, run the suggestion check from Phase 2B.5. Use the selected framework to infer which signals apply (e.g., selecting "Laravel" triggers migration-reviewer and api-reviewer suggestions). If the project has existing code, also scan the filesystem for remaining signals.

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

### Phase 2B.5: Suggest Additional Agents

After confirming the detected stack (Phase 2B) or gathering user answers (Phase 2A), scan for structural signals that indicate additional agents beyond the core three would be useful.

**Detection Table** — check each signal and map to suggested agents:

| Signal | Detection Check | Suggested Agent | Source |
|---|---|---|---|
| Database migrations | `database/migrations/` (Laravel), `migrations/` (Django), `prisma/migrations/`, or migration files detected | `migration-reviewer` | Template: `migration-reviewer-{framework}.md` |
| API routes | `routes/api/` or `app/Http/Controllers/Api/` (Laravel), `app/api/` or `pages/api/` (Next.js), `routers/` (FastAPI) | `api-reviewer` | Template: `api-reviewer-{framework}.md` |
| ORM models with relationships | 5+ model files containing relationship methods (`hasMany`, `belongsTo`, `HasOne`, `ForeignKey`, `relationship`, `references`) | `performance-reviewer` | Template: `performance-reviewer.md` |
| Web components (10+ files) | `components/` or `src/components/` with 10+ `.tsx`/`.jsx`/`.vue`/`.blade.php` files | `accessibility-reviewer` | Dynamic (generate from blueprint) |
| CI/CD config | `.github/workflows/`, `.circleci/`, `.gitlab-ci.yml`, `Jenkinsfile` | `ci-reviewer` | Dynamic (generate from blueprint) |
| Sparse documentation | No `docs/` directory AND `README.md` under 20 lines (or missing) | `documentation-generator` | Dynamic (generate from blueprint) |
| 50+ dependencies | Lock file (`package-lock.json`, `composer.lock`, `poetry.lock`, `Cargo.lock`) with 50+ top-level deps | `dependency-analyzer` | Dynamic (generate from blueprint) |

**Signal detection logic:**
1. For each signal, run the detection check using `Glob` and `Grep`
2. Only include signals that match — non-triggered signals are not shown
3. Count files/matches to include in the signal description

**User interaction** — present detected signals:

```
Based on your project structure, these additional agents would be useful:

  [1] migration-reviewer    — Review migrations for data safety and rollback correctness
      Signal: database/migrations/ with 23 migration files

  [2] api-reviewer           — Review API endpoints for consistency and error handling
      Signal: routes/api/ and app/Http/Controllers/Api/ detected

  [3] performance-reviewer   — Detect N+1 queries and algorithmic complexity issues
      Signal: 12 Eloquent models with relationship definitions

Include suggested agents? [All / Pick numbers / None]
```

If the user picks "All" or specific numbers, mark those agents for generation in Phase 3. If "None", skip.

**For New Project Mode (Phase 2A)**: After gathering user answers, infer signals from the selected framework:
- Laravel → always suggest migration-reviewer and api-reviewer
- Django → always suggest migration-reviewer
- Next.js/Expo → suggest api-reviewer if API routes type selected
- All frameworks → check remaining signals via filesystem scan if project has existing code

#### Dynamic Agent Blueprints

For agents marked "Dynamic" in the detection table, generate the agent markdown from these blueprints. Each blueprint specifies the complete frontmatter and focus areas — Claude fills in the detailed review instructions following the same structure as template agents.

**accessibility-reviewer**:
```yaml
frontmatter:
  name: accessibility-reviewer
  description: >-
    Review components for accessibility issues.
    Invoke after creating or modifying UI components, or on demand with "accessibility review".
  model: sonnet
  color: purple
  tools: Read, Grep, Glob
  permissionMode: plan
  maxTurns: 15
  memory: user
focus_areas:
  - WCAG 2.1 AA compliance (missing alt text, form labels, heading hierarchy)
  - Semantic HTML (divs used where nav/main/section/article appropriate)
  - ARIA attributes (missing or incorrect roles, aria-label, aria-describedby)
  - Keyboard navigation (missing tabIndex, onKeyDown handlers, focus traps in modals)
  - Color contrast (hardcoded colors that may fail 4.5:1 ratio)
  - Touch targets (interactive elements smaller than 44x44px on mobile)
output_format: Same P0-P3 structure as code-reviewer with WCAG reference codes
```

**ci-reviewer**:
```yaml
frontmatter:
  name: ci-reviewer
  description: >-
    Review CI/CD configuration for efficiency and safety.
    Invoke after modifying workflow files, or on demand with "review CI config".
  model: haiku
  color: gray
  tools: Read, Grep, Glob
  permissionMode: plan
  maxTurns: 10
  memory: user
focus_areas:
  - Caching strategy (missing or misconfigured dependency caching)
  - Secret management (hardcoded values, overly broad secret access)
  - Test parallelism (sequential jobs that could run in parallel)
  - Deployment safety (missing environment protection, no rollback plan)
  - Resource waste (unnecessary steps, redundant builds)
  - Version pinning (using latest tags instead of pinned versions)
output_format: Same P0-P3 structure as code-reviewer
```

**documentation-generator**:
```yaml
frontmatter:
  name: documentation-generator
  description: >-
    Generate missing documentation for the project.
    Invoke with "generate docs" or when documentation gaps are identified.
  model: sonnet
  color: green
  tools: Read, Grep, Glob, Write, Edit
  permissionMode: acceptEdits
  maxTurns: 20
  memory: user
focus_areas:
  - API documentation (endpoint descriptions, request/response examples)
  - README sections (installation, usage, configuration, contributing)
  - Architecture overview (directory structure, key abstractions, data flow)
  - Environment setup (required env vars, local development steps)
output_format: Generates markdown files directly, reports what was created
```

**dependency-analyzer**:
```yaml
frontmatter:
  name: dependency-analyzer
  description: >-
    Analyze project dependencies for issues.
    Invoke with "analyze dependencies" or periodically for maintenance.
  model: haiku
  color: gray
  tools: Read, Grep, Glob, Bash
  permissionMode: plan
  maxTurns: 10
  memory: user
focus_areas:
  - Known vulnerabilities (check against advisory databases via package manager audit commands)
  - Unused dependencies (imported in lock file but not referenced in source)
  - License conflicts (incompatible licenses in dependency tree)
  - Outdated packages (major version behind, end-of-life)
output_format: Table format grouped by severity (Critical/High/Medium/Low)
```

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
- **Existence checks** — verify these agents exist:
  - All projects: `code-reviewer.md`
  - All projects: `security-reviewer.md`
  - If test framework detected (Pest, Jest, Vitest, pytest): `test-generator.md`
- **Quality checks** — for each existing agent, verify:
  - Uses `tools:` field in frontmatter (not the deprecated `allowed-tools:`)
  - Read-only agents (code-reviewer, security-reviewer) have `permissionMode: plan`
  - Write-capable agents (test-generator) have `permissionMode: acceptEdits`
  - `maxTurns` is set (prevents runaway execution)
  - `description` includes invocation guidance (when/how to use the agent)
  - Tool list is appropriate: reviewers should have `Read, Grep, Glob` only (NOT Write/Edit/Bash); test-generator should have `Read, Grep, Glob, Write, Edit, Bash`
- **Suggested agents** — check for additional agents that should exist based on detected signals:
  - Run the detection table from Phase 2B.5 against the project
  - For each triggered signal where the corresponding agent doesn't exist in `.claude/agents/`, report it as a suggestion (not a gap — these are optional)
  - Format: `[suggested] migration-reviewer — Signal: database/migrations/ with 23 files`
- Report quality issues alongside missing agents

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

| Stack | Settings | Hooks | Rules | CLAUDE.md | Agents | Suggested Agents |
|---|---|---|---|---|---|---|
| PHP/Laravel | `php-laravel.json` | `universal/*`, `php/format-php.sh` | `php/*` | `php-laravel.md` | `code-reviewer.md`, `security-reviewer-php.md`, `test-generator-pest.md` (if Pest detected) | `migration-reviewer-laravel.md`, `api-reviewer-laravel.md`, `performance-reviewer.md` (conditional on signals) |
| JS/Next.js | `js-nextjs.json` | `universal/*`, `javascript/*` | `javascript/*` | `js-nextjs.md` | `code-reviewer.md`, `security-reviewer-js.md`, `test-generator-jest.md` or `test-generator-vitest.md` (if detected) | `api-reviewer-generic.md`, `performance-reviewer.md` (conditional on signals) |
| JS/Expo | `js-expo.json` | `universal/*`, `javascript/*` | `javascript/*` | `js-expo.md` | `code-reviewer.md`, `security-reviewer-js.md`, `test-generator-jest.md` (if Jest detected) | `api-reviewer-generic.md`, `performance-reviewer.md` (conditional on signals) |
| Python/Django | `python-django.json` | `universal/*`, `python/format-python.sh` | `python/*` | `python-django.md` | `code-reviewer.md`, `security-reviewer-python.md`, `test-generator-pytest.md` (if pytest detected) | `migration-reviewer-django.md`, `api-reviewer-generic.md`, `performance-reviewer.md` (conditional on signals) |
| Python/FastAPI | `python-fastapi.json` | `universal/*`, `python/format-python.sh` | `python/*` | `python-fastapi.md` | `code-reviewer.md`, `security-reviewer-python.md`, `test-generator-pytest.md` (if pytest detected) | `api-reviewer-generic.md`, `performance-reviewer.md` (conditional on signals) |
| Go | `generic.json` | `universal/*`, `go/format-go.sh` | — | `generic.md` | `code-reviewer.md`, `security-reviewer-generic.md` | `performance-reviewer.md` (conditional on signals) |
| Rust | `generic.json` | `universal/*`, `rust/format-rust.sh` | — | `generic.md` | `code-reviewer.md`, `security-reviewer-generic.md` | `performance-reviewer.md` (conditional on signals) |
| Other | `generic.json` | `universal/*` | — | `generic.md` | `code-reviewer.md`, `security-reviewer-generic.md` | (conditional on signals) |

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

Generate the following agents:

- **Always**: Copy `code-reviewer.md` (universal, works for all stacks)
- **Always**: Copy the security-reviewer agent for the detected stack (`security-reviewer-php.md`, `security-reviewer-js.md`, `security-reviewer-python.md`, or `security-reviewer-generic.md`)
- **Conditionally**: If a test framework was detected in Phase 2B, copy the matching test-generator agent:
  - Pest detected → `test-generator-pest.md`
  - Jest detected → `test-generator-jest.md`
  - Vitest detected → `test-generator-vitest.md`
  - pytest detected → `test-generator-pytest.md`
  - No test framework detected → skip test-generator
- **Suggested agents** (from Phase 2B.5): For each accepted suggestion:
  - **Template agents** (migration-reviewer, api-reviewer, performance-reviewer): Copy the appropriate template from `templates/agents/` just like core agents. Select the framework-specific variant (e.g., `migration-reviewer-laravel.md` for Laravel, `migration-reviewer-generic.md` as fallback).
  - **Dynamic agents** (accessibility-reviewer, ci-reviewer, documentation-generator, dependency-analyzer): Generate the full agent markdown using the blueprint from Phase 2B.5. Write YAML frontmatter exactly as specified in the blueprint, then generate review instructions, categories, output format, and guidelines sections following the same structure as template agents.

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
    code-reviewer.md          — code quality review agent
    security-reviewer.md      — PHP security review agent
    test-generator.md         — Pest test generation agent
    migration-reviewer.md     — migration safety review agent (suggested)
    api-reviewer.md           — API consistency review agent (suggested)
  CLAUDE.md                   — project overview + conventions (189 lines)

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
