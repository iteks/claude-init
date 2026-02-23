---
description: Analyze any project and generate optimal Claude Code integration
---

# Claude Init

Analyze any project and generate optimal Claude Code integration — hooks, rules, agents, skills, settings, and CLAUDE.md. Works for new projects, existing projects without config, and projects with existing Claude Code setup.

---

## Instructions

You are the `claude-init` skill. When invoked, follow this complete workflow.

### Pre-check: `/claude-init update` Command

If the user invoked `/claude-init update` (check if `$ARGUMENTS` contains "update"), run the self-update flow **instead of** the normal pipeline:

1. Resolve the claude-init repo root from the skill symlink:
   ```
   SKILL_LINK="$HOME/.claude/skills/claude-init"
   SKILL_TARGET="$(readlink "$SKILL_LINK")"
   REPO_ROOT — two directories up from the skill target
   ```
2. Get the current local version: `git -C $REPO_ROOT describe --tags --abbrev=0`
3. Fetch tags: `git -C $REPO_ROOT fetch --tags origin`
4. Find the latest tag: `git -C $REPO_ROOT tag -l 'v*' --sort=-version:refname | head -1`
5. If the latest tag matches the current version, report: `claude-init is already up to date ($CURRENT_VERSION).` and stop.
6. Checkout the latest tag: `git -C $REPO_ROOT checkout $LATEST_TAG`
7. Report: `Updated claude-init: $CURRENT_VERSION -> $LATEST_TAG`
8. Ask the user: "Run `/claude-init` to apply updates to this project?"

**Do not continue to Phase 1** when handling the update command. The update flow is complete after step 8.

### Pre-check: `/claude-init global` Command

If the user invoked `/claude-init global` (check if `$ARGUMENTS` contains "global"), run the global environment setup flow **instead of** the normal pipeline:

Skip directly to the **Global Pipeline** section at the bottom of this file (Phase G1). The global pipeline configures `~/.claude/` with personal preferences, universal agents, commands, rules, and memory.

**Do not continue to Phase 1** when handling the global command. The global flow is self-contained.

---

### Execution Strategy — Context Preservation

claude-init's phases involve heavy file reading (scanning lock files, reading templates, extracting conventions). To keep the main session clean for user interaction and reporting, delegate the heavy phases to subagents using the `Task` tool.

**Subagent delegation points:**

| Subagent | Phases | Model | Input | Output |
|---|---|---|---|---|
| Detection | 2B + 2C–2E | `haiku` | Project root path | Structured YAML stack summary + signal scan results |
| Generation | 3 + 4 | `sonnet` | Stack summary + user selections + project root path | List of files created/modified |
| Global Generation | G3 + G4 | `sonnet` | User preferences + selected categories | List of files created |

**What stays in the main session** (requires user interaction or is lightweight):
- Phase 1 — three file-existence checks
- Phase 2A — `AskUserQuestion` prompts (can't delegate)
- User confirmations — stack approval, agent selection
- Phase 5 — display the summary returned by the generation subagent

**For Audit Mode (2C):** Two-step delegation. First, delegate the audit scan as a subagent that reads existing config and returns the audit report. The main session displays the report and collects the user's fix/skip decision. If fixes are approved, delegate a second generation subagent with the fix list.

Audit scan subagent prompt:
```
Audit the existing Claude Code configuration at {path}. Follow the Phase 2F
(Audit Mode) checklist in {skill_path}/SKILL.md.

Return the audit report as structured YAML with these keys:

```yaml
version_check:
  current: "v1.0.0"
  latest: "v1.2.0"
  new_capabilities: ["plugins", "commands"]
findings:
  - category: "hooks"
    severity: "gap"          # gap | warning | suggestion
    item: "guard-migration-django.sh"
    reason: "Django project with migrations/ but no migration guard hook"
    fix: "Create .claude/hooks/guard-migration-django.sh from template"
  - category: "rules"
    severity: "warning"
    item: "testing-pest.md"
    reason: "paths: tests/** matches no files (project uses test/)"
    fix: "Update glob to test/**"
summary:
  gaps: 3
  warnings: 1
  suggestions: 2
```

Do not apply fixes — only report.
```
Use `model: "sonnet"` for the audit scan subagent.

**For New Project Mode (2A):** Skip the detection subagent (the user provides the answers). Only delegate generation (Phase 3 + 4).

**How to delegate:**

Use `Task` with `subagent_type: "general-purpose"` and `mode: "bypassPermissions"`.
Specify the `model` parameter per the table above: `model: "haiku"` for the Detection subagent, `model: "sonnet"` for Generation and Audit subagents.

Detection subagent prompt:
```
Analyze the project at {path}. Follow the detection sequence:
1. Language detection (composer.json, package.json, pyproject.toml, go.mod, Cargo.toml)
2. Framework detection (artisan+laravel, next.config, app.config+expo, manage.py+django, fastapi)
2b. Version extraction — for each detected framework, extract the version from the dependency file (composer.json, package.json, pyproject.toml, requirements.txt)
3. Test framework detection (pestphp, jest, vitest, pytest)
4. Formatter/linter detection (duster, pint, eslint, prettier, ruff, black, gofmt, rustfmt)
4b. Database detection — check .env for DB_CONNECTION, docker-compose.yml for database images, pyproject.toml for database drivers, settings.py for Django backends
5. Package manager detection (bun, pnpm, yarn, npm, pipenv, poetry, uv)
5.5. Dev command extraction — read package.json scripts, composer.json scripts, Makefile targets, Justfile recipes, Taskfile.yml tasks, pyproject.toml scripts, Procfile processes. Map to canonical slots: dev, build, test, lint, format, start, typecheck.
5b. Styling/CSS framework detection — check for tailwind.config.*, nativewind, styled-components, @emotion/react, CSS modules, sass
6. Convention extraction (read 2-3 source files for indent style, naming, imports)
6b. Build & infrastructure detection — check for Makefile, Justfile, Taskfile.yml, Dockerfile/docker-compose.yml, .devcontainer/, monorepo markers (pnpm-workspace.yaml, nx.json, turbo.json, lerna.json), .editorconfig, .tool-versions/.mise.toml
7. Signal scan (migrations, API routes, ORM models, components, CI/CD, docs, dependencies)
8. Plugin & command scan — check for existing .claude/commands/ directory, installed plugins (extraKnownMarketplaces or enabledPlugins in settings), and detect signals for official marketplace plugins: TypeScript (tsconfig.json), Python (pyproject.toml), PHP (composer.json), Go (go.mod), Rust (Cargo.toml) for LSP plugins; GitHub remote for github plugin; Sentry/Slack/Figma SDKs for integration plugins

Return the summary as structured YAML with these exact keys:

```yaml
stack:
  language: "PHP"
  framework: "Laravel"
  test_framework: "Pest"
  formatter: "Duster"
  package_manager: "Composer"
  database: "MySQL"
  styling: null
versions:
  php: "^8.3"
  framework: "^12.0"
dev_commands:
  source: "composer.json"
  map:
    dev: "php artisan serve"
    test: "php artisan test"
    lint: "./vendor/bin/duster lint"
infrastructure:
  build_tools: ["Makefile (12 targets)"]
  containerization: "Docker (docker-compose.yml, 3 services)"
  monorepo: null
  editorconfig: { indent_style: "tab", indent_size: 4 }
  version_manager: ".tool-versions"
conventions:
  indentation: "Tabs"
  naming: "PSR-12"
  import_style: "PSR-4 autoload"
signals:
  migrations: { detected: true, count: 23 }
  api_routes: { detected: true, count: 5 }
  orm_models: { detected: true, count: 12 }
  components: { detected: false }
  ci_cd: { detected: true, path: ".github/workflows/" }
  docs: { detected: false }
  dependencies: { detected: true, count: 45 }
skill_signals:
  new-api-endpoint: { triggered: true, evidence: "routes/api/ detected" }
plugin_signals:
  php-lsp: { suggested: true, reason: "composer.json detected" }
existing_commands: ["review-changes.md"]
```
```

Generation subagent prompt:
```
Generate Claude Code configuration for a {framework} project at {path}.
Stack: {paste detection YAML summary}
Accepted agents: {list from user selection}
Accepted skills: {list from user selection}
Accepted commands: {list from user selection}

Read templates from {skill_path}/templates/ and follow the Phase 3 (Generate)
and Phase 4 (Validate) instructions in {skill_path}/SKILL.md.

Return the result as structured YAML:

```yaml
files_created:
  - path: ".claude/settings.json"
    description: "hooks, permissions, settings"
  - path: ".claude/hooks/guard-env.sh"
    description: "blocks .env edits"
files_skipped:
  - path: ".claude/agents/code-reviewer.md"
    reason: "already exists"
validation:
  passed: 9
  failed: 0
  auto_fixed: 1
  details:
    - check: "hook scripts executable"
      result: "pass"
```
```

---

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

**After gathering answers**, proceed to Phase 3 using the selected framework to choose templates. If the selected framework has no dedicated template in the template selection table (e.g., SvelteKit, Rails, Astro, Flutter), use the **Other** row (generic templates) and populate the generic placeholders with the user's answers.

**Before proceeding to Phase 3**, run the suggestion checks from Phases 2C, 2D, and 2E. Use the selected framework to infer which signals apply (e.g., selecting "Laravel" triggers migration-reviewer and api-reviewer suggestions). If the project has existing code, also scan the filesystem for remaining signals.

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
| (`app.config.*` OR `app.json`) + `package.json` has `expo` | Expo |
| `nuxt.config.*` OR `package.json` has `nuxt` | Nuxt |
| `manage.py` + settings with `django` | Django |
| `pyproject.toml` has `fastapi` OR `requirements.txt` has `fastapi` | FastAPI |
| `Gemfile` has `rails` | Rails (uses generic templates) |
| `package.json` has `express` | Express (uses generic templates) |
| `svelte.config.*` OR `package.json` has `@sveltejs/kit` | SvelteKit (uses generic templates) |

#### Version Extraction

For each detected framework, extract the version from the appropriate source:

| Framework | Version Source |
|---|---|
| PHP | `composer.json` → `require.php` constraint, or `php -v` output |
| Laravel | `composer.json` → `require.laravel/framework` constraint |
| Django | `pyproject.toml` or `requirements.txt` → `django` version |
| FastAPI | `pyproject.toml` or `requirements.txt` → `fastapi` version |
| Next.js | `package.json` → `dependencies.next` version |
| React | `package.json` → `dependencies.react` version |
| Expo | `package.json` → `dependencies.expo` version |

Extract the version string as-is from the dependency file (e.g., "^12.0", "~4.2", ">=3.11"). For PHP, prefer `composer.json` over CLI output.

#### Test Framework Detection
| Check | Test Framework |
|---|---|
| `composer.json` has `pestphp/pest` | Pest |
| `composer.json` has `phpunit/phpunit` (without Pest) | PHPUnit |
| `package.json` has `jest` | Jest |
| `package.json` has `vitest` | Vitest |
| `pyproject.toml` has `pytest` OR `pytest.ini` exists | pytest |
| `go.mod` exists (Go projects use built-in testing) | Go testing |
| `Cargo.toml` exists (Rust projects use built-in testing) | Rust testing |

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

#### Database Detection
| Check | Database |
|---|---|
| `.env` contains `DB_CONNECTION=mysql` or `DB_CONNECTION=mariadb` | MySQL/MariaDB |
| `.env` contains `DB_CONNECTION=pgsql` | PostgreSQL |
| `.env` contains `DB_CONNECTION=sqlite` | SQLite |
| `docker-compose.yml` has `postgres` or `pgsql` image | PostgreSQL |
| `docker-compose.yml` has `mysql` or `mariadb` image | MySQL/MariaDB |
| `pyproject.toml` has `psycopg` or `asyncpg` | PostgreSQL |
| `pyproject.toml` has `pymysql` or `aiomysql` | MySQL |
| `settings.py` has `django.db.backends.postgresql` | PostgreSQL |
| `settings.py` has `django.db.backends.mysql` | MySQL |
| `settings.py` has `django.db.backends.sqlite3` | SQLite |

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

#### Build & Infrastructure Detection
| Check | Signal | Data to Extract |
|---|---|---|
| `Makefile` | Make build system | Target names (parse `^[a-zA-Z_-]+:` lines) |
| `Justfile` | Just command runner | Recipe names |
| `Taskfile.yml` | Task runner | Task names from `tasks:` keys |
| `Dockerfile` or `docker-compose.yml` | Containerized | Service names, base image |
| `.devcontainer/` | Dev container | Presence flag |
| `pnpm-workspace.yaml`, `nx.json`, `turbo.json`, or `lerna.json` | Monorepo | Workspace packages |
| `.editorconfig` | EditorConfig | `indent_style`, `indent_size` (use to confirm/override convention extraction) |
| Majority `.sh` files + `shellcheck` available on PATH | Shell-heavy project | Flag for shellcheck lint hook |
| `.tool-versions` or `.mise.toml` | Version manager | Runtime versions |

#### Dev Command Detection

Extract dev commands from the following sources. For each source found, read and extract the relevant commands:

| Source | Detection | Extraction |
|---|---|---|
| `package.json` | File exists | Read `scripts` object — keys are command names, values are the commands |
| `composer.json` | File exists | Read `scripts` object |
| `Makefile` | File exists | Parse `^[a-zA-Z_-]+:` to get target names |
| `Justfile` | File exists | Parse recipe names (lines starting with identifier followed by `:`) |
| `Taskfile.yml` | File exists | Read `tasks:` top-level keys |
| `pyproject.toml` | `[project.scripts]` or `[tool.poetry.scripts]` section exists | Read script name:command pairs |
| `Procfile` | File exists | Read process:command pairs |

**Key command mapping** — map extracted script names to canonical slots:

| Canonical Slot | Common Script Names |
|---|---|
| `dev` | `dev`, `serve`, `start:dev`, `develop`, `watch` |
| `build` | `build`, `compile`, `production` |
| `test` | `test`, `test:unit`, `test:feature`, `pest`, `jest`, `vitest`, `pytest` |
| `lint` | `lint`, `lint:fix`, `check`, `analyze`, `stan` |
| `format` | `format`, `fmt`, `fix`, `cs-fix`, `prettier` |
| `start` | `start`, `up`, `run` |
| `typecheck` | `typecheck`, `type-check`, `tsc`, `types` |

If the same slot maps from multiple sources, prefer `package.json` > `composer.json` > `Makefile` > others.

#### Styling/CSS Framework Detection
| Check | Styling Framework |
|---|---|
| `tailwind.config.*` exists OR `package.json` has `tailwindcss` | Tailwind CSS |
| `package.json` has `nativewind` | NativeWind (Tailwind for React Native) |
| `package.json` has `styled-components` | styled-components |
| `package.json` has `@emotion/react` or `@emotion/styled` | Emotion |
| `*.module.css` files exist in `src/` or `app/` | CSS Modules |
| `package.json` has `sass` or `node-sass` | Sass/SCSS |

**Convention extraction** — read a few representative source files to detect:
- Indentation style (tabs vs spaces, how many)
- Naming conventions (camelCase, snake_case, PascalCase)
- Import style and organization
- Directory structure patterns
- If `.editorconfig` was found in infrastructure detection, use its `indent_style` and `indent_size` as authoritative values (override source file heuristics)
- If dev commands were extracted, include the command map in the stack summary for use in CLAUDE.md placeholder replacement

**Report findings** to the user before proceeding:
```
Detected stack:
  Language:    PHP 8.3
  Framework:   Laravel 12
  Testing:     Pest
  Formatter:   Duster
  Package Mgr: Composer
  Dev Commands: dev → php artisan serve, test → php artisan test, lint → ./vendor/bin/duster lint
  Infrastructure: Docker (docker-compose.yml), Makefile (12 targets)

Proceed with generating Claude Code config? [Yes / Customize / Skip]
```

Handle the user's response:
- **Yes** — proceed to Phase 3
- **Customize** — ask which fields to override (framework, formatter, test runner, package manager), accept corrections, then proceed to Phase 3 with adjusted values
- **Skip** — abort the pipeline. Display: "Cancelled. Run /claude-init again when ready."

---

### Phase 2C: Suggest Additional Agents

After confirming the detected stack (Phase 2B) or gathering user answers (Phase 2A), scan for structural signals that indicate additional agents beyond the core three would be useful.

**Detection Table** — check each signal and map to suggested agents:

| Signal | Detection Check | Suggested Agent | Source |
|---|---|---|---|
| Database migrations | `database/migrations/` (Laravel), `migrations/` (Django), `prisma/migrations/`, or migration files detected | `migration-reviewer` | Template: `migration-reviewer-{framework}.md` |
| API routes | `routes/api/` or `app/Http/Controllers/Api/` (Laravel), `app/api/` or `pages/api/` (Next.js), `routers/` (FastAPI) | `api-reviewer` | Template: `api-reviewer-{framework}.md` |
| ORM models with relationships | 5+ model files containing relationship methods (`hasMany`, `belongsTo`, `HasOne`, `ForeignKey`, `relationship`, `references`) | `performance-reviewer` | Template: `performance-reviewer-generic.md` |
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

### Phase 2D: Suggest Skills

Scan for patterns that indicate custom skills would be useful. Skills are reusable workflows invoked with `/skill-name`.

**Detection Table:**

| Signal | Detection Check | Suggested Skill | Template |
|---|---|---|---|
| Laravel API routes | `routes/api/` directory + API controllers exist | `new-api-endpoint` | `templates/skills/new-api-endpoint-laravel.md` |
| React/Next/Expo components | `components/` or `src/components/` with 10+ files | `new-component` | `templates/skills/new-component-react.md` |
| Django apps | `manage.py` + 2+ app directories with `models.py` | `new-django-app` | `templates/skills/new-django-app.md` |
| Any test framework | Test framework detected in Phase 2B | `new-test-suite` | `templates/skills/new-test-suite-generic.md` |
| FastAPI routers | `routers/` or `api/` directory with router files | `new-router` | `templates/skills/new-router-fastapi.md` |

**User interaction** — same pattern as agents:

```
Based on your project structure, these custom skills would be useful:

  [1] /new-api-endpoint    — Guided workflow for creating Laravel API endpoints
      Signal: routes/api/ and app/Http/Controllers/Api/ detected

  [2] /new-test-suite      — Scaffold test files matching your Pest conventions
      Signal: Pest test framework detected

Include suggested skills? [All / Pick numbers / None]
```

### Phase 2E: Suggest Plugins & Commands

#### Plugin Suggestions

Suggest official marketplace plugins based on the detected stack. These are installed via `/plugin install`, not generated as files.

**LSP Plugins** (language intelligence — jump to definition, find references, diagnostics):

| Detected Language | Plugin | Binary Required |
|---|---|---|
| TypeScript/JavaScript | `typescript-lsp@claude-plugins-official` | `typescript-language-server` |
| Python | `pyright-lsp@claude-plugins-official` | `pyright-langserver` |
| PHP | `php-lsp@claude-plugins-official` | `intelephense` |
| Go | `gopls-lsp@claude-plugins-official` | `gopls` |
| Rust | `rust-analyzer-lsp@claude-plugins-official` | `rust-analyzer` |

**Integration Plugins** (external service connections):

| Signal | Plugin |
|---|---|
| GitHub remote detected | `github@claude-plugins-official` |
| Sentry SDK in dependencies | `sentry@claude-plugins-official` |
| Slack SDK in dependencies | `slack@claude-plugins-official` |
| Figma references in project | `figma@claude-plugins-official` |

**User interaction:**

```
These official plugins would enhance your Claude Code experience:

  Plugins to install:
  [1] typescript-lsp      — Code intelligence (jump to def, find refs, diagnostics)
  [2] github              — Enhanced GitHub integration

  Install commands will be included in your setup report.

Include plugin suggestions in report? [All / Pick numbers / None]
```

Note: Plugins are not generated as files — they are installed via `/plugin install name@claude-plugins-official`. The Phase 5 report includes the install commands.

#### Command Suggestions

Suggest slash commands (`.claude/commands/`) based on detected project capabilities:

| Signal | Command | Template | Purpose |
|---|---|---|---|
| Any project | `review-changes` | `templates/commands/review-changes.md` | Review uncommitted changes using code-reviewer agent |
| Test framework detected | `run-tests` | `templates/commands/run-tests.md` | Run test suite with detected test command |
| Dev command detected | `dev` | `templates/commands/dev.md` | Start development server with detected command |

Commands are always suggested (they're lightweight and universally useful). User can decline with the same All / Pick / None pattern.

---

### Phase 2F: Audit Mode

The project already has `.claude/` configuration. Scan for gaps and improvements.

**Pre-scan: Detect project stack** — Before scanning categories, run the Phase 2B detection tables (language, framework, test framework, formatter, package manager, database, styling) to establish the project's stack context. This is required because audit checks reference the detected stack (e.g., "missing hooks based on detected stack", "missing rules based on detected directories"). Store the detection results for use throughout the audit.

**Scan the following categories:**

#### 0. Version Check
- Read `.claude/.claude-init-version` if it exists
- Get current claude-init version: `git -C {skill_path}/../.. describe --tags --abbrev=0` (resolve `{skill_path}` from the skill's location — the repo root is two directories up from the skill)
- If both versions are available and differ:
  - Show: `claude-init updated: {old_version} → {new_version}` (e.g., `v1.0.0 → v1.2.0`)
  - Compute new capabilities: compare the project's `capabilities` array against the full set (`hooks`, `rules`, `agents`, `skills`, `commands`, `permissions`, `plugins`)
  - Missing entries = new features added since last generation
  - If new capabilities exist, list them: `New capabilities available: plugins, commands`
  - Display this at the top of the audit report, before category scans
- If the version file doesn't exist, note: `No version stamp found — this project was configured before version tracking was added`
- If versions match, show: `claude-init version: {version} (up to date)`

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
  - All projects: `code-reviewer-generic.md`
  - All projects: `security-reviewer.md`
  - If test framework detected (Pest, Jest, Vitest, pytest): `test-generator.md`
- **Quality checks** — for each existing agent, verify:
  - Uses `tools:` field in frontmatter (not the deprecated `allowed-tools:`)
  - Read-only agents (code-reviewer, security-reviewer) have `permissionMode: plan`
  - Write-capable agents (test-generator) have `permissionMode: acceptEdits`
  - `maxTurns` is set (prevents runaway execution)
  - `description` includes invocation guidance (when/how to use the agent)
  - Tool list is appropriate: reviewers should have `Read, Grep, Glob` (NOT Write/Edit; Bash is allowed for git-only read operations); test-generator should have `Read, Grep, Glob, Write, Edit, Bash`
- **Suggested agents** — check for additional agents that should exist based on detected signals:
  - Run the detection table from Phase 2C against the project
  - For each triggered signal where the corresponding agent doesn't exist in `.claude/agents/`, report it as a suggestion (not a gap — these are optional)
  - Format: `[suggested] migration-reviewer — Signal: database/migrations/ with 23 files`
- Report quality issues alongside missing agents

#### 5. Settings Audit
- Read `.claude/settings.json`
- Check for **missing or incomplete settings**:
  - `permissions.defaultMode` — should be set to `"plan"` for complex stacks (Laravel, Django)
  - Hook definitions — ensure all hooks reference scripts that exist
- Check for `.claude/settings.local.json` — if it exists, verify it's in `.gitignore`
- Check for permission optimizations (read-only command pre-approvals in global `~/.claude/settings.json`)

#### 6. Config Hygiene
- Check if `.claude/settings.local.json` is in `.gitignore`
- Check if `.env` is in `.gitignore`
- Check for any sensitive data patterns in `.claude/` files

#### 7. Skills Audit
- Check if `.claude/skills/` directory exists
- If it exists, verify each subdirectory contains a `SKILL.md` file
- Run skill detection checks from Phase 2D against the project
- For each triggered signal where no corresponding skill exists, report as suggestion
- Report: skills with missing SKILL.md, suggested skills for detected signals

#### 8. Commands Audit
- Check if `.claude/commands/` directory exists
- If it exists, list existing commands
- Check for missing common commands: `review-changes` (always useful), `run-tests` (if test framework detected), `dev` (if dev command detected)
- Report: missing commands for detected capabilities

#### 9. Permissions Audit
- Read `.claude/settings.json` for `permissions.allow` and `permissions.deny` arrays
- Check for missing permission patterns based on detected tools:
  - Test framework detected but no test command pre-approved
  - Formatter detected but no format command pre-approved
  - Package manager detected but no install command pre-approved
  - Framework CLI detected but no CLI command pre-approved
- Check for missing deny patterns:
  - All projects: `Bash(rm -rf *)` should be denied
  - Laravel: `Bash(php artisan migrate:fresh*)` and `Bash(php artisan migrate:reset*)` should be denied
  - Django: `Bash(python manage.py flush*)` should be denied
- Report: missing allow patterns, missing deny patterns

#### 10. Plugin Audit
- Run plugin detection from Phase 2E against the project
- Check if `extraKnownMarketplaces` or `enabledPlugins` exist in `.claude/settings.json`
- For each detected language without a corresponding LSP plugin suggestion, note it
- For each detected integration (GitHub, Sentry, etc.) without a plugin, note it
- Report: suggested plugins that aren't installed

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

Skills
  [checkmark] /new-api-endpoint skill exists
  [suggested] /new-test-suite — Pest detected but no test scaffold skill

Commands
  [checkmark] /review-changes command exists
  [x] Missing: /run-tests (Pest detected)

Permissions
  [checkmark] Test commands pre-approved
  [x] Missing: Bash(./vendor/bin/duster *) not pre-approved
  [x] Missing deny: Bash(php artisan migrate:fresh*) not blocked

Plugins
  [suggested] typescript-lsp — TypeScript detected, LSP plugin available
  [suggested] github — GitHub remote detected

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
| PHP/Laravel | `php-laravel.json` | `universal/*`, `php/format-php.sh` | `php/*` | `php-laravel.md` | `code-reviewer-generic.md`, `security-reviewer-php.md`, `test-generator-pest.md` (if Pest detected) | `migration-reviewer-laravel.md`, `api-reviewer-laravel.md`, `performance-reviewer-generic.md` (conditional on signals) |
| JS/Next.js | `js-nextjs.json` | `universal/*`, `javascript/*` | `javascript/component-conventions-react.md`, `javascript/testing-jest.md` or `javascript/testing-vitest.md` (match detected test framework) | `js-nextjs.md` | `code-reviewer-generic.md`, `security-reviewer-js.md`, `test-generator-jest.md` or `test-generator-vitest.md` (if detected) | `api-reviewer-generic.md`, `performance-reviewer-generic.md` (conditional on signals) |
| JS/Expo | `js-expo.json` | `universal/*`, `javascript/*` | `javascript/component-conventions-react.md`, `javascript/testing-jest.md` or `javascript/testing-vitest.md` (match detected test framework) | `js-expo.md` | `code-reviewer-generic.md`, `security-reviewer-js.md`, `test-generator-jest.md` (if Jest detected) | `api-reviewer-generic.md`, `performance-reviewer-generic.md` (conditional on signals) |
| Python/Django | `python-django.json` | `universal/*`, `python/format-python.sh`, `python/guard-migration-django.sh` | `python/testing-pytest.md`, `python/migration-safety-django.md` | `python-django.md` | `code-reviewer-generic.md`, `security-reviewer-python.md`, `test-generator-pytest.md` (if pytest detected) | `migration-reviewer-django.md`, `api-reviewer-generic.md`, `performance-reviewer-generic.md` (conditional on signals) |
| Python/FastAPI | `python-fastapi.json` | `universal/*`, `python/format-python.sh` | `python/testing-pytest.md`, `python/api-conventions-fastapi.md` | `python-fastapi.md` | `code-reviewer-generic.md`, `security-reviewer-python.md`, `test-generator-pytest.md` (if pytest detected) | `api-reviewer-generic.md`, `performance-reviewer-generic.md` (conditional on signals) |
| JS/Nuxt | `generic.json` | `universal/*`, `javascript/*` | `javascript/component-conventions-react.md`, `javascript/testing-jest.md` or `javascript/testing-vitest.md` (match detected test framework) | `generic.md` | `code-reviewer-generic.md`, `security-reviewer-js.md`, `test-generator-jest.md` or `test-generator-vitest.md` (if detected) | `api-reviewer-generic.md`, `performance-reviewer-generic.md` (conditional on signals) |
| Go | `go.json` | `universal/*`, `go/format-go.sh` | — | `generic.md` | `code-reviewer-generic.md`, `security-reviewer-generic.md` | `performance-reviewer-generic.md` (conditional on signals) |
| Rust | `rust.json` | `universal/*`, `rust/format-rust.sh` | — | `generic.md` | `code-reviewer-generic.md`, `security-reviewer-generic.md` | `performance-reviewer-generic.md` (conditional on signals) |
| Other | `shell.json` (if shell project), `generic.json` + permissions (otherwise) | `universal/*`, `shell/lint-shellcheck.sh` (if shell project) | — | `generic.md` (with populated dev commands) | `code-reviewer-generic.md`, `security-reviewer-generic.md` | (conditional on signals) |

#### File Generation

Create these files in the project (skip any that already exist in merge mode):

**1. `.claude/settings.json`**
- Read the template for the detected stack
- Adjust hook paths to match project structure
- For Laravel monorepos with a `laravel/` subdirectory, adjust paths accordingly

**Permission generation** — add `permissions.allow` and `permissions.deny` arrays based on detected tools:

| Detected Tool | Allow Patterns |
|---|---|
| Test: Pest | `Bash(php artisan test*)`, `Bash(./vendor/bin/pest*)` |
| Test: Jest | `Bash(npx jest*)`, `Bash(npm test*)` |
| Test: Vitest | `Bash(npx vitest*)`, `Bash(npm test*)` |
| Test: pytest | `Bash(pytest*)`, `Bash(python -m pytest*)` |
| Fmt: Duster | `Bash(./vendor/bin/duster fix*)`, `Bash(./vendor/bin/duster lint*)` |
| Fmt: Pint | `Bash(./vendor/bin/pint*)` |
| Fmt: ESLint | `Bash(npx eslint*)` |
| Fmt: Prettier | `Bash(npx prettier*)` |
| Fmt: ruff | `Bash(ruff format*)`, `Bash(ruff check*)` |
| Fmt: black | `Bash(black *)` |
| Pkg: npm | `Bash(npm install*)`, `Bash(npm run *)` |
| Pkg: composer | `Bash(composer install*)`, `Bash(composer require*)` |
| Pkg: poetry | `Bash(poetry install*)`, `Bash(poetry run *)` |
| Pkg: pip/uv | `Bash(pip install*)`, `Bash(uv pip install*)` |
| Pkg: bun | `Bash(bun install*)`, `Bash(bun run *)` |
| Pkg: pnpm | `Bash(pnpm install*)`, `Bash(pnpm run *)` |
| Pkg: yarn | `Bash(yarn install*)`, `Bash(yarn run *)`, `Bash(yarn add*)` |
| Pkg: pipenv | `Bash(pipenv install*)`, `Bash(pipenv run *)` |
| Framework: Laravel | `Bash(php artisan route:list*)`, `Bash(php artisan make:*)`, `Bash(php artisan tinker*)` |
| Framework: Django | `Bash(python manage.py shell*)`, `Bash(python manage.py check*)`, `Bash(python manage.py showmigrations*)` |
| Dev commands | For each detected dev command, add `Bash({command}*)` |

Deny patterns:

| Stack | Deny Pattern |
|---|---|
| Any | `Bash(rm -rf *)` |
| Laravel | `Bash(php artisan migrate:fresh*)`, `Bash(php artisan migrate:reset*)` |
| Django | `Bash(python manage.py flush*)`, `Bash(python manage.py migrate*--fake*)` |

Merge these into the settings template's `permissions` object. Example output structure:

```json
{
  "permissions": {
    "defaultMode": "plan",
    "allow": [
      "Bash(php artisan test*)",
      "Bash(./vendor/bin/pest*)",
      "Bash(./vendor/bin/duster fix*)",
      "Bash(./vendor/bin/duster lint*)",
      "Bash(composer install*)"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(php artisan migrate:fresh*)",
      "Bash(php artisan migrate:reset*)"
    ]
  },
  "hooks": { ... }
}
```

**2. `.claude/hooks/` directory**
- Copy relevant hook scripts from templates
- Adjust the project root detection logic if needed (e.g., `composer.json` location for PHP, `package.json` for JS)
- Make all hook scripts executable: `chmod +x`

**3. `.claude/rules/` directory**
- Copy relevant rule templates
- **Validate glob patterns**: For each rule's `paths:` frontmatter, verify the glob patterns match actual files in the project. If a template's default path doesn't match (e.g., template has `tests/**` but project uses `test/**`), adjust the glob pattern to match the actual directory structure.

**4. `.claude/agents/` directory**

Generate the following agents:

- **Always**: Copy `code-reviewer-generic.md` (universal, works for all stacks)
- **Always**: Copy the security-reviewer agent for the detected stack (`security-reviewer-php.md`, `security-reviewer-js.md`, `security-reviewer-python.md`, or `security-reviewer-generic.md`)
- **Conditionally**: If a test framework was detected in Phase 2B, copy the matching test-generator agent:
  - Pest detected → `test-generator-pest.md`
  - Jest detected → `test-generator-jest.md`
  - Vitest detected → `test-generator-vitest.md`
  - pytest detected → `test-generator-pytest.md`
  - No test framework detected → skip test-generator
- **Suggested agents** (from Phase 2C): For each accepted suggestion:
  - **Template agents** (migration-reviewer, api-reviewer, performance-reviewer): Copy the appropriate template from `templates/agents/` just like core agents. Select the framework-specific variant (e.g., `migration-reviewer-laravel.md` for Laravel, `migration-reviewer-generic.md` as fallback).
  - **Dynamic agents** (accessibility-reviewer, ci-reviewer, documentation-generator, dependency-analyzer): Generate the full agent markdown using the blueprint from Phase 2C. Write YAML frontmatter exactly as specified in the blueprint, then generate review instructions, categories, output format, and guidelines sections following the same structure as template agents.

**5. `CLAUDE.md`**
- Read the template for the detected stack
- Replace all `{{PLACEHOLDER}}` markers with detected/provided values:
  - `{{PROJECT_NAME}}` — from directory name or user input
  - `{{PROJECT_DESCRIPTION}}` — from user input or package.json/composer.json description
  - `{{PHP_VERSION}}`, `{{LARAVEL_VERSION}}` — from detected PHP/Laravel versions
  - `{{PYTHON_VERSION}}`, `{{DJANGO_VERSION}}`, `{{FASTAPI_VERSION}}` — from detected Python framework versions
  - `{{NEXTJS_VERSION}}`, `{{REACT_VERSION}}`, `{{EXPO_VERSION}}` — from detected JS framework versions
  - `{{DEV_URL}}`, `{{DEV_COMMAND}}` — from project config or common defaults
  - `{{BUILD_COMMAND}}`, `{{LINT_COMMAND}}`, `{{TYPECHECK_COMMAND}}` — from dev command detection
  - `{{FORMATTER}}` — display name of the formatter (e.g., "Duster", "Pint", "Prettier", "ruff"). Use in prose text, NOT in commands.
  - `{{FORMATTER_COMMAND}}` — the formatter binary + default subcommand/flags (e.g., "duster lint", "pint --test", "prettier --check .", "ruff check"). Includes everything after the path prefix. Use in command contexts like `./vendor/bin/{{FORMATTER_COMMAND}}` or `npx {{FORMATTER_COMMAND}}` — do NOT append extra subcommands since they're already included.
  - `{{FORMAT_COMMAND}}` — the full project-level format command from dev command detection (e.g., "npm run format", "./vendor/bin/duster fix"). Use in `{{DEV_INSTRUCTIONS}}` lists.
  - `{{DATABASE}}` — from detected database (MySQL, PostgreSQL, SQLite, etc.)
  - `{{PACKAGE_MANAGER}}` — from detected package manager (npm, pnpm, bun, poetry, etc.)
  - `{{STYLING}}`, `{{STYLING_CONVENTIONS}}` — from detected CSS/styling framework
  - `{{INDENT_STYLE}}` — from .editorconfig or source file analysis (e.g., "Tabs (enforced by Duster)", "2 spaces (Prettier)")
  - `{{TEST_FRAMEWORK}}` — from detected test framework (e.g., "Pest", "PHPUnit", "Jest", "Vitest", "pytest + pytest-django", "pytest + httpx")
  - `{{TEST_COMMAND}}` — from detected test command (e.g., "php artisan test --compact", "npx jest", "pytest")
  - `{{PROJECT_SLUG}}` — URL-safe project name (lowercase, hyphens)
  - `{{ARCHITECTURE_NOTES}}` — from reading source code structure
  - `{{CONVENTIONS}}` — from detected coding conventions
  - `{{STACK_DESCRIPTION}}` — combined language + framework + infrastructure summary
  - `{{DIRECTORY_TABLE}}` — markdown table of key directories and their purpose
  - `{{WATCH_ITEMS}}` — project-specific "Things to Watch For" items
- If dev commands were detected, use them for placeholder replacement:
  - `{{DEV_COMMAND}}` — use the detected `dev` or `start` command instead of framework defaults
  - `{{TEST_COMMAND}}` — use the detected `test` command
  - `{{FORMAT_COMMAND}}` — use the detected `format` or `lint` command
  - `{{DEV_INSTRUCTIONS}}` — generate a formatted command list from all detected commands:
    ```
    - **Dev server**: `npm run dev`
    - **Tests**: `npm test`
    - **Lint**: `npm run lint`
    - **Format**: `npm run format`
    - **Build**: `npm run build`
    - **Typecheck**: `npm run typecheck`
    ```
  - For the generic template, detected commands replace the raw `{{DEV_INSTRUCTIONS}}` placeholder entirely, producing useful content instead of empty placeholders
  - If NO dev commands were detected, replace `{{DEV_INSTRUCTIONS}}` with: `Refer to the project README for development setup instructions.`
- If infrastructure was detected, include it in `{{STACK_DESCRIPTION}}`:
  - Append containerization info: "Docker (docker-compose.yml with 3 services)"
  - Append build tool info: "Makefile (12 targets)"
  - Append monorepo info: "pnpm workspace (4 packages)"
- Ensure the final CLAUDE.md is **under 300 lines**
- If content exceeds 300 lines, move detailed conventions into path-scoped rules instead
- **Always include the Workflow Automation section** — this is the most impactful section for daily productivity

**6. `.gitignore` updates**
- If `.gitignore` exists, check if it contains `.claude/settings.local.json`
- If not, suggest adding it (don't modify .gitignore without confirmation)

**7. `.claude/skills/` directory** (if skills were accepted in Phase 2D)
- For each accepted skill, create `.claude/skills/{skill-name}/SKILL.md`
- Read the skill template from `templates/skills/` for the detected framework
- Replace generation-time placeholders with detected values:
  - `{{TEST_FRAMEWORK}}` — detected test framework name
  - `{{TEST_COMMAND}}` — detected test command
  - `{{FORMATTER_COMMAND}}` — detected formatter command
  - `{{LINT_COMMAND}}` — detected lint command
  - `{{TYPECHECK_COMMAND}}` — detected typecheck command
- Leave runtime placeholders intact (replaced when the user invokes the skill):
  - `{{RESOURCE_NAME}}`, `{{RESOURCE_PLURAL}}` — derived from `$ARGUMENTS`
  - `{{COMPONENT_DIR}}` — resolved by the skill at invocation time
  - `{{APP_CONFIG_NAME}}` — derived from `$ARGUMENTS`
- Each skill SKILL.md should include frontmatter with `description` and the skill workflow

**8. `.claude/commands/` directory** (if commands were accepted in Phase 2E)
- For each accepted command, create `.claude/commands/{command-name}.md`
- Read the command template from `templates/commands/`
- Replace placeholders with detected values:
  - `{{TEST_COMMAND}}` — from dev command detection
  - `{{DEV_COMMAND}}` — from dev command detection
- Commands are simple markdown files with a description and prompt text

**9. `.claude/.claude-init-version`**
- Get claude-init version: `git -C {skill_path}/../.. describe --tags --abbrev=0` (resolve `{skill_path}` from the skill's location — the repo root is two directories up from the skill)
- Build the `capabilities` array from what was actually generated in this run (e.g., if hooks were created, include `"hooks"`; if skills were declined, omit `"skills"`)
- Known capability keys: `hooks`, `rules`, `agents`, `skills`, `commands`, `permissions`, `plugins`
- Write JSON file:
  ```json
  {
    "version": "{tag_version}",
    "generated_at": "{ISO_8601_timestamp}",
    "capabilities": ["hooks", "rules", "agents", "skills", "commands", "permissions"]
  }
  ```
  Example: `"version": "v1.2.0"` (semver tag, not a commit hash)
- In merge mode: **ALWAYS overwrite** this file (unlike other config files) — it must reflect the current tool version
- Suggest adding `.claude-init-version` to `.gitignore` (it tracks the generating tool version, not project config)

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
7. **Skills have SKILL.md**: For each generated skill directory, verify it contains a non-empty `SKILL.md`
8. **Commands are valid**: For each generated command, verify the `.md` file exists and is non-empty
9. **Permissions are consistent**: Verify `permissions.allow` patterns don't conflict with `permissions.deny` patterns

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
  .claude/skills/
    new-api-endpoint/SKILL.md — guided API endpoint creation (/new-api-endpoint)
    new-test-suite/SKILL.md   — test scaffold workflow (/new-test-suite)
  .claude/commands/
    review-changes.md         — review uncommitted changes (/review-changes)
    run-tests.md              — run test suite (/run-tests)
    dev.md                    — start dev server (/dev)
  CLAUDE.md                   — project overview + conventions (189 lines)
  .claude/.claude-init-version — tracks tool version for upgrade detection

Next steps:
  1. Review the generated CLAUDE.md and adjust any placeholders
  2. Add project-specific conventions to CLAUDE.md
  3. Try your new commands: /review-changes, /run-tests, /dev
  4. Run: git add .claude/ CLAUDE.md && git commit -m "Add Claude Code configuration"
  5. Install suggested plugins:
     /plugin install typescript-lsp@claude-plugins-official
     /plugin install github@claude-plugins-official
  6. Try your new skills: /new-api-endpoint BookingController
```

If in audit mode, also show what was fixed vs. what was skipped.

---

## Important Notes

- This skill generates configuration that makes Claude Code work better with the project. It does NOT modify source code.
- All generated hooks use `jq` for JSON processing — ensure `jq` is installed on the system.
- The Workflow Automation section in CLAUDE.md is critical — it teaches Claude when to plan, when to review, and when to suggest context management. Always include it.
- Templates are starting points. Encourage the user to customize after generation.
- For monorepos, detect the project structure and adjust paths accordingly (e.g., `laravel/` subdirectory for Laravel projects within a monorepo).

---

## Global Pipeline — `/claude-init global`

This pipeline configures the user's global `~/.claude/` environment with personal preferences, universal agents, commands, rules, and memory. It is completely independent of the project pipeline above.

### Phase G1: Detect Global State

Check for existing global configuration:

1. `~/.claude/CLAUDE.md` — global preferences file
2. `~/.claude/agents/*.md` — global agent definitions
3. `~/.claude/commands/*.md` — global slash commands
4. `~/.claude/rules/*.md` — global rules
5. `~/.claude/memory/MEMORY.md` — persistent memory
6. `~/.claude/skills/` — installed skills (beyond claude-init itself)

**Mode selection:**

| Condition | Mode |
|---|---|
| 3+ of the above categories are populated | **Audit Mode** (G2-Audit) |
| Fewer than 3 categories populated | **Setup Mode** (G2) |

Announce which mode you're entering and what was detected.

---

### Phase G2: User Preferences (Setup Mode)

Gather personal preferences using `AskUserQuestion`. These shape the global CLAUDE.md and determine which categories to generate.

**Question 1 — Coding style:**
- Options: Functional, Object-oriented, Pragmatic, No preference
- Header: "Style"
- "No preference" → produces neutral defaults

**Question 2 — Communication tone:**
- Options: Concise (terse, minimal), Balanced (clear, moderate detail), Detailed (thorough explanations), No preference
- Header: "Tone"

**Question 3 — Default indentation:**
- Options: 2 spaces, 4 spaces, Tabs, Follow project
- Header: "Indent"

**Question 4 — Git workflow** (multi-select):
- Options: Conventional commits, Never auto-commit, Always branch, Prefer rebase
- Header: "Git"
- multiSelect: true

**Question 5 — Tool preferences** (free text via "Other" option):
- Options: No specific preferences, Other
- Header: "Tools"
- This captures things like "always use bun", "prefer pnpm", "use vim keybindings"

**Question 6 — Categories to generate** (multi-select):
- Options: Global CLAUDE.md (Recommended), Universal agents, Universal commands, Universal rules
- Header: "Categories"
- multiSelect: true
- Memory bootstrap is always included (lightweight)

For each "No preference" answer, the corresponding CLAUDE.md section uses a neutral default or is omitted.

**Placeholder mapping** — map answers to template placeholders:

| Placeholder | Source | "No preference" default |
|---|---|---|
| `{{CODING_STYLE}}` | Q1 | "Follow the conventions of each project. No global style preference." |
| `{{COMMUNICATION_TONE}}` | Q2 | "Adapt to the context. Be concise for simple tasks, detailed for complex ones." |
| `{{INDENT_PREFERENCE}}` | Q3 | "Follow each project's conventions. If no project convention exists, use 2 spaces." |
| `{{GIT_CONVENTIONS}}` | Q4 | "Follow each project's git conventions." |
| `{{TOOL_PREFERENCES}}` | Q5 | "No global tool preferences. Use whatever each project specifies." |

**Style answer expansions:**

| Answer | Replacement text |
|---|---|
| Functional | "Prefer functional patterns: pure functions, immutability, composition over inheritance, declarative over imperative." |
| Object-oriented | "Prefer OOP patterns: classes with clear responsibilities, encapsulation, composition, and well-defined interfaces." |
| Pragmatic | "Use whichever paradigm fits best. Prefer simplicity and readability over strict paradigm adherence." |

**Tone answer expansions:**

| Answer | Replacement text |
|---|---|
| Concise | "Be terse. Short answers, minimal explanation. Only elaborate when asked." |
| Balanced | "Be clear and moderately detailed. Explain the 'why' for non-obvious decisions." |
| Detailed | "Be thorough. Explain reasoning, trade-offs, and alternatives. Include context for decisions." |

**Indent answer expansions:**

| Answer | Replacement text |
|---|---|
| 2 spaces | "Default to 2 spaces for indentation when no project convention exists." |
| 4 spaces | "Default to 4 spaces for indentation when no project convention exists." |
| Tabs | "Default to tabs for indentation when no project convention exists." |
| Follow project | "Follow each project's conventions. If no project convention exists, use 2 spaces." |

**Git answer expansions** (combine selected options):

| Answer | Appended text |
|---|---|
| Conventional commits | "Use conventional commit format (feat:, fix:, chore:, etc.)." |
| Never auto-commit | "Never create git commits automatically. Always ask before committing." |
| Always branch | "Always work on a feature branch, never commit directly to main/master." |
| Prefer rebase | "Prefer rebase over merge for integrating changes. Keep history linear." |

---

### Phase G2-Audit: Audit Global State (Audit Mode)

Scan each category for gaps against the template inventory.

**Audit checks:**

1. **CLAUDE.md** — Does `~/.claude/CLAUDE.md` exist? If yes, is it under 80 lines? Does it have a Workflow Automation section?
2. **Agents** — Check for `git-assistant.md`, `quick-reviewer.md`, `research-assistant.md` in `~/.claude/agents/`. Verify frontmatter has required fields.
3. **Commands** — Check for `commit.md`, `pr.md`, `morning-standup.md` in `~/.claude/commands/`. Verify frontmatter has `description`.
4. **Rules** — Check for `git-safety.md`, `file-safety.md` in `~/.claude/rules/`. Verify `paths: ["**"]`.
5. **Memory** — Check for `~/.claude/memory/MEMORY.md`.

**Report format:**

```
Global Environment Audit — ~/.claude/

CLAUDE.md
  [checkmark] Exists (N lines)  OR  [x] Missing
  [checkmark] Under 80 lines  OR  [warning] N lines — consider trimming

Agents
  [checkmark] git-assistant
  [x] Missing: quick-reviewer
  [x] Missing: research-assistant

Commands
  [checkmark] commit
  [x] Missing: pr
  [x] Missing: morning-standup

Rules
  [checkmark] git-safety
  [checkmark] file-safety

Memory
  [checkmark] MEMORY.md exists

Fix gaps? [All / Pick individually / Skip]
```

If the user chooses to fix, proceed to Phase G3 for the missing items only. Existing files are never overwritten.

---

### Phase G3: Generate Global Configuration

**Delegate this phase to a subagent** using `Task` with `subagent_type: "general-purpose"`, `model: "sonnet"`, and `mode: "bypassPermissions"`.

Subagent prompt:
```
Generate global Claude Code configuration at ~/.claude/.
User preferences: {paste Q1-Q5 answers}
Selected categories: {paste Q6 selections}
Template path: {skill_path}/templates/global/

For each selected category:
1. Read the template from templates/global/{category}/
2. Replace {{PLACEHOLDER}} markers with the user's preference text
3. Write to ~/.claude/{appropriate path}
4. NEVER overwrite files that already exist — skip and report as "already configured"

Categories:
- Global CLAUDE.md → Read templates/global/claude-md/global.md, replace placeholders, write to ~/.claude/CLAUDE.md
- Universal agents → Copy templates/global/agents/*.md to ~/.claude/agents/
- Universal commands → Copy templates/global/commands/*.md to ~/.claude/commands/
- Universal rules → Copy templates/global/rules/*.md to ~/.claude/rules/
- Memory bootstrap → Copy templates/global/memory/MEMORY.md to ~/.claude/memory/MEMORY.md (create directory if needed)

After generation, run Phase G4 validation and return a summary of every file created or skipped.
```

**Non-overwrite guarantee**: The subagent must check if each target file exists before writing. If it exists, skip it and include it in the report as "already configured". This is critical — users may have customized their global config.

---

### Phase G4: Validate

After generating files, validate:

1. **Global CLAUDE.md under 80 lines** — shorter than project CLAUDE.md because it loads into every session
2. **Agent files have valid frontmatter** — check for `name`, `description`, `model`, `color`, `tools`, `permissionMode`, `maxTurns`, `memory`
3. **Command files have valid frontmatter** — check for `description`
4. **Rule files have valid frontmatter** — check for `paths: ["**"]`
5. **No existing files overwritten** — verify the generation log shows skips for pre-existing files
6. **Memory directory exists** — `~/.claude/memory/` was created if needed

Fix any validation errors automatically.

---

### Phase G5: Report

Output a summary of everything created:

```
Global Claude Code environment configured — ~/.claude/

Files created:
  ~/.claude/CLAUDE.md                  — personal preferences + workflow automation (N lines)
  ~/.claude/agents/
    git-assistant.md                   — git workflow helper (rebase, conflicts, branches)
    quick-reviewer.md                  — lightweight universal code review
    research-assistant.md              — web research + docs lookup
  ~/.claude/commands/
    commit.md                          — smart commit message generation (/commit)
    pr.md                              — PR creation with auto-generated body (/pr)
    morning-standup.md                 — cross-repo activity summary (/morning-standup)
  ~/.claude/rules/
    git-safety.md                      — never commit .env, no force-push main
    file-safety.md                     — never delete without confirmation
  ~/.claude/memory/
    MEMORY.md                          — starter memory template

[If any files skipped:]
Already configured (not modified):
  ~/.claude/agents/git-assistant.md    — already exists

Next steps:
  1. Review ~/.claude/CLAUDE.md and adjust preferences
  2. Start using your new commands: /commit, /pr, /morning-standup
  3. Try your global agents: "quick review" or "help me with git"
  4. Add notes to ~/.claude/memory/MEMORY.md as you work
  5. Run /claude-init in a project to set up project-specific config
     (project config overrides global preferences)
```

If in audit mode, also show what was fixed vs. what was skipped.
