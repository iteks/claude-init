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

---

### Execution Strategy — Context Preservation

claude-init's phases involve heavy file reading (scanning lock files, reading templates, extracting conventions). To keep the main session clean for user interaction and reporting, delegate the heavy phases to subagents using the `Task` tool.

**Subagent delegation points:**

| Subagent | Phases | Model | Input | Output |
|---|---|---|---|---|
| Detection | 2B + 2B.5–2B.9 | `haiku` | Project root path | Structured stack summary + signal scan results |
| Generation | 3 + 4 | `sonnet` | Stack summary + user selections + project root path | List of files created/modified |

**What stays in the main session** (requires user interaction or is lightweight):
- Phase 1 — three file-existence checks
- Phase 2A — `AskUserQuestion` prompts (can't delegate)
- User confirmations — stack approval, agent selection
- Phase 5 — display the summary returned by the generation subagent

**For Audit Mode (2C):** Delegate the entire audit scan + fix cycle as a single subagent. It reads existing config, produces the audit report text, and generates fixes if the user approves. The main session only handles displaying the report and collecting the user's fix/skip decision.

**For New Project Mode (2A):** Skip the detection subagent (the user provides the answers). Only delegate generation (Phase 3 + 4).

**How to delegate:**

Use `Task` with `subagent_type: "general-purpose"` and `mode: "bypassPermissions"`.

Detection subagent prompt:
```
Analyze the project at {path}. Follow the detection sequence:
1. Language detection (composer.json, package.json, pyproject.toml, go.mod, Cargo.toml)
2. Framework detection (artisan+laravel, next.config, app.config+expo, manage.py+django, fastapi)
3. Test framework detection (pestphp, jest, vitest, pytest)
4. Formatter/linter detection (duster, pint, eslint, prettier, ruff, black, gofmt, rustfmt)
5. Package manager detection (bun, pnpm, yarn, npm, pipenv, poetry, uv)
5.5. Dev command extraction — read package.json scripts, composer.json scripts, Makefile targets, Justfile recipes, Taskfile.yml tasks, pyproject.toml scripts, Procfile processes. Map to canonical slots: dev, build, test, lint, format, start, typecheck.
6. Convention extraction (read 2-3 source files for indent style, naming, imports)
6b. Build & infrastructure detection — check for Makefile, Justfile, Taskfile.yml, Dockerfile/docker-compose.yml, .devcontainer/, monorepo markers (pnpm-workspace.yaml, nx.json, turbo.json, lerna.json), .editorconfig, .tool-versions/.mise.toml
7. Signal scan (migrations, API routes, ORM models, components, CI/CD, docs, dependencies)
7b. MCP dependency scan — check for Sentry SDK (@sentry/node, sentry-sdk, sentry/sentry-laravel), GitHub remote in .git/config, Slack SDK (@slack/web-api, @slack/bolt), Figma references (figma.com URLs in .md/source files, figma-api in deps)
8. Plugin & command scan — check for existing .claude/commands/ directory, installed plugins (extraKnownMarketplaces or enabledPlugins in settings), and detect signals for official marketplace plugins: TypeScript (tsconfig.json), Python (pyproject.toml), PHP (composer.json), Go (go.mod), Rust (Cargo.toml) for LSP plugins; GitHub remote for github plugin; Sentry/Slack/Figma (reuse MCP signals) for integration plugins

Return a structured summary:
  Stack: Language, Framework, Test Framework, Formatter, Package Manager
  Dev Commands: Source file, command map (dev, build, test, lint, format, start, typecheck)
  Infrastructure: Build tools, containerization, monorepo type, editorconfig settings, version manager
  Conventions: Indentation, Naming, Import Style
  Signals: For each of the 7 signals, state detected/not-detected with file counts
  MCP Signals: For each of the 4 MCP checks, state detected/not-detected with package name
  Skill Signals: For each applicable skill template, state triggered/not-triggered with evidence
  Plugin Signals: For each official marketplace plugin, state suggested/not-needed with reason
  Existing Commands: List any .claude/commands/ files found
```

Generation subagent prompt:
```
Generate Claude Code configuration for a {framework} project at {path}.
Stack: {paste detection summary}
Accepted agents: {list from user selection}

Read templates from {skill_path}/templates/ and follow the Phase 3 (Generate)
and Phase 4 (Validate) instructions in {skill_path}/SKILL.md.
Return a summary of every file created or modified with a one-line description each.
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

### Phase 2B.7: Suggest MCP Servers

After confirming agents, check if the project uses services that have official Anthropic MCP servers. Only suggest well-maintained official servers.

**Detection Table:**

| Signal | Detection Check | MCP Server |
|---|---|---|
| Sentry SDK | `@sentry/node` in package.json, `sentry-sdk` in pyproject.toml, `sentry/sentry-laravel` in composer.json | `@anthropic/claude-code-sentry` |
| GitHub remote | `.git/config` contains `github.com` | `@anthropic/claude-code-github` |
| Slack SDK | `@slack/web-api` or `@slack/bolt` in package.json | `@anthropic/claude-code-slack` |
| Figma references | `figma.com/design/` or `figma.com/file/` in .md/source files, or `figma-api` in deps | `@anthropic/claude-code-figma` |

**User interaction** — present detected MCP servers:

```
Based on your project dependencies, these MCP server integrations are available:

  [1] Sentry     — Error tracking integration (sentry/sentry-laravel detected)
  [2] GitHub     — Enhanced GitHub integration (github.com remote detected)

Include MCP server configs? [All / Pick numbers / None]
```

For each accepted server, generate an `.mcp.json` entry in Phase 3. Add `.mcp.json` to the `.gitignore` suggestion list (it contains auth tokens).

### Phase 2B.8: Suggest Skills

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

### Phase 2B.9: Suggest Plugins & Commands

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

### Phase 2C: Audit Mode

The project already has `.claude/` configuration. Scan for gaps and improvements.

**Scan the following categories:**

#### 0. Version Check
- Read `.claude/.claude-init-version` if it exists
- Get current claude-init version: `git -C {skill_path}/../.. describe --tags --abbrev=0` (resolve `{skill_path}` from the skill's location — the repo root is two directories up from the skill)
- If both versions are available and differ:
  - Show: `claude-init updated: {old_version} → {new_version}` (e.g., `v1.0.0 → v1.2.0`)
  - Compute new capabilities: compare the project's `capabilities` array against the full set (`hooks`, `rules`, `agents`, `mcp`, `skills`, `commands`, `permissions`, `plugins`)
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

#### 7. MCP Audit
- Check if `.mcp.json` exists in project root
- If it doesn't exist, run MCP detection checks from Phase 2B.7
- If it exists, verify it contains valid JSON and check for placeholder tokens (`YOUR_*_TOKEN`, `YOUR_*_KEY`) that haven't been replaced
- Report: missing MCP configs for detected services, unreplaced placeholder tokens

#### 8. Skills Audit
- Check if `.claude/skills/` directory exists
- If it exists, verify each subdirectory contains a `SKILL.md` file
- Run skill detection checks from Phase 2B.8 against the project
- For each triggered signal where no corresponding skill exists, report as suggestion
- Report: skills with missing SKILL.md, suggested skills for detected signals

#### 9. Commands Audit
- Check if `.claude/commands/` directory exists
- If it exists, list existing commands
- Check for missing common commands: `review-changes` (always useful), `run-tests` (if test framework detected), `dev` (if dev command detected)
- Report: missing commands for detected capabilities

#### 10. Permissions Audit
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

#### 11. Plugin Audit
- Run plugin detection from Phase 2B.9 against the project
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

MCP Servers
  [checkmark] .mcp.json configured with [N] servers
  [x] Missing: Sentry MCP (sentry/sentry-laravel detected in composer.json)

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
| PHP/Laravel | `php-laravel.json` | `universal/*`, `php/format-php.sh` | `php/*` | `php-laravel.md` | `code-reviewer.md`, `security-reviewer-php.md`, `test-generator-pest.md` (if Pest detected) | `migration-reviewer-laravel.md`, `api-reviewer-laravel.md`, `performance-reviewer.md` (conditional on signals) |
| JS/Next.js | `js-nextjs.json` | `universal/*`, `javascript/*` | `javascript/*` | `js-nextjs.md` | `code-reviewer.md`, `security-reviewer-js.md`, `test-generator-jest.md` or `test-generator-vitest.md` (if detected) | `api-reviewer-generic.md`, `performance-reviewer.md` (conditional on signals) |
| JS/Expo | `js-expo.json` | `universal/*`, `javascript/*` | `javascript/*` | `js-expo.md` | `code-reviewer.md`, `security-reviewer-js.md`, `test-generator-jest.md` (if Jest detected) | `api-reviewer-generic.md`, `performance-reviewer.md` (conditional on signals) |
| Python/Django | `python-django.json` | `universal/*`, `python/format-python.sh` | `python/*` | `python-django.md` | `code-reviewer.md`, `security-reviewer-python.md`, `test-generator-pytest.md` (if pytest detected) | `migration-reviewer-django.md`, `api-reviewer-generic.md`, `performance-reviewer.md` (conditional on signals) |
| Python/FastAPI | `python-fastapi.json` | `universal/*`, `python/format-python.sh` | `python/*` | `python-fastapi.md` | `code-reviewer.md`, `security-reviewer-python.md`, `test-generator-pytest.md` (if pytest detected) | `api-reviewer-generic.md`, `performance-reviewer.md` (conditional on signals) |
| Go | `generic.json` | `universal/*`, `go/format-go.sh` | — | `generic.md` | `code-reviewer.md`, `security-reviewer-generic.md` | `performance-reviewer.md` (conditional on signals) |
| Rust | `generic.json` | `universal/*`, `rust/format-rust.sh` | — | `generic.md` | `code-reviewer.md`, `security-reviewer-generic.md` | `performance-reviewer.md` (conditional on signals) |
| Other | `generic.json` + permissions | `universal/*`, `shell/lint-shellcheck.sh` (if shell project) | — | `generic.md` (with populated dev commands) | `code-reviewer.md`, `security-reviewer-generic.md` | (conditional on signals) |

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
| Framework: Laravel | `Bash(php artisan route:list*)`, `Bash(php artisan make:*)`, `Bash(php artisan tinker*)` |
| Framework: Django | `Bash(python manage.py shell*)`, `Bash(python manage.py check*)`, `Bash(python manage.py showmigrations*)` |
| Dev commands (Gap 5) | For each detected dev command, add `Bash({command}*)` |

Deny patterns:

| Stack | Deny Pattern |
|---|---|
| Any | `Bash(rm -rf *)` |
| Laravel | `Bash(php artisan migrate:fresh*)`, `Bash(php artisan migrate:reset*)` |
| Django | `Bash(python manage.py flush*)` |

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
  - `{{PHP_VERSION}}`, `{{LARAVEL_VERSION}}` — from detected PHP/Laravel versions
  - `{{PYTHON_VERSION}}`, `{{DJANGO_VERSION}}`, `{{FASTAPI_VERSION}}` — from detected Python framework versions
  - `{{NEXTJS_VERSION}}`, `{{REACT_VERSION}}`, `{{EXPO_VERSION}}` — from detected JS framework versions
  - `{{DEV_URL}}`, `{{DEV_COMMAND}}` — from project config or common defaults
  - `{{BUILD_COMMAND}}`, `{{LINT_COMMAND}}`, `{{TYPECHECK_COMMAND}}` — from dev command detection
  - `{{FORMATTER}}`, `{{FORMATTER_COMMAND}}` — from detected formatter
  - `{{DATABASE}}` — from detected database (MySQL, PostgreSQL, SQLite, etc.)
  - `{{PACKAGE_MANAGER}}` — from detected package manager (npm, pnpm, bun, poetry, etc.)
  - `{{STYLING}}`, `{{STYLING_CONVENTIONS}}` — from detected CSS/styling framework
  - `{{INDENT_STYLE}}` — from .editorconfig or source file analysis
  - `{{PROJECT_SLUG}}` — URL-safe project name (lowercase, hyphens)
  - `{{ARCHITECTURE_NOTES}}` — from reading source code structure
  - `{{CONVENTIONS}}` — from detected coding conventions
  - `{{STACK_DESCRIPTION}}` — combined language + framework + infrastructure summary
  - `{{DIRECTORY_TABLE}}` — markdown table of key directories and their purpose
  - `{{WATCH_ITEMS}}` — project-specific "Things to Watch For" items
- If dev commands were detected (Gap 5), use them for placeholder replacement:
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
- If infrastructure was detected (Gap 2), include it in `{{STACK_DESCRIPTION}}`:
  - Append containerization info: "Docker (docker-compose.yml with 3 services)"
  - Append build tool info: "Makefile (12 targets)"
  - Append monorepo info: "pnpm workspace (4 packages)"
- Ensure the final CLAUDE.md is **under 300 lines**
- If content exceeds 300 lines, move detailed conventions into path-scoped rules instead
- **Always include the Workflow Automation section** — this is the most impactful section for daily productivity

**6. `.gitignore` updates**
- If `.gitignore` exists, check if it contains `.claude/settings.local.json`
- If not, suggest adding it (don't modify .gitignore without confirmation)

**7. `.mcp.json`** (if MCP servers were accepted in Phase 2B.7)
- Read the MCP config templates from `templates/mcp/` for each accepted server
- Combine them into a single `.mcp.json` file at the project root
- Each server entry uses placeholder tokens (e.g., `YOUR_SENTRY_AUTH_TOKEN`) that the user must fill in
- Structure:

```json
{
  "mcpServers": {
    "sentry": {
      "command": "npx",
      "args": ["-y", "@anthropic/claude-code-sentry"],
      "env": {
        "SENTRY_AUTH_TOKEN": "YOUR_SENTRY_AUTH_TOKEN",
        "SENTRY_ORG": "YOUR_SENTRY_ORG",
        "SENTRY_PROJECT": "YOUR_SENTRY_PROJECT"
      }
    }
  }
}
```

- Add `.mcp.json` to the `.gitignore` suggestion list (alongside `settings.local.json`)

**8. `.claude/skills/` directory** (if skills were accepted in Phase 2B.8)
- For each accepted skill, create `.claude/skills/{skill-name}/SKILL.md`
- Read the skill template from `templates/skills/` for the detected framework
- Replace placeholders with detected values:
  - `{{TEST_FRAMEWORK}}` — detected test framework name
  - `{{TEST_COMMAND}}` — detected test command
  - `{{FRAMEWORK}}` — detected framework name
  - `{{LANGUAGE}}` — detected language
- Each skill SKILL.md should include frontmatter with `description` and the skill workflow

**9. `.claude/commands/` directory** (if commands were accepted in Phase 2B.9)
- For each accepted command, create `.claude/commands/{command-name}.md`
- Read the command template from `templates/commands/`
- Replace placeholders with detected values:
  - `{{TEST_COMMAND}}` — from dev command detection
  - `{{DEV_COMMAND}}` — from dev command detection
  - `{{REVIEW_SCOPE}}` — default to "uncommitted changes"
- Commands are simple markdown files with a description and prompt text

**10. `.claude/.claude-init-version`**
- Get claude-init version: `git -C {skill_path}/../.. describe --tags --abbrev=0` (resolve `{skill_path}` from the skill's location — the repo root is two directories up from the skill)
- Build the `capabilities` array from what was actually generated in this run (e.g., if hooks were created, include `"hooks"`; if MCP was declined, omit `"mcp"`)
- Known capability keys: `hooks`, `rules`, `agents`, `mcp`, `skills`, `commands`, `permissions`, `plugins`
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
- Add `.claude-init-version` to the `.gitignore` suggestion list (version stamp is machine-specific)

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
7. **MCP config is valid**: If `.mcp.json` was generated, verify it parses as valid JSON and contains placeholder tokens
8. **Skills have SKILL.md**: For each generated skill directory, verify it contains a non-empty `SKILL.md`
9. **Commands are valid**: For each generated command, verify the `.md` file exists and is non-empty
10. **Permissions are consistent**: Verify `permissions.allow` patterns don't conflict with `permissions.deny` patterns

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
  .mcp.json                   — MCP server configs (Sentry, GitHub)
    ⚠ Replace placeholder tokens before use — see setup instructions below
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
  5. Configure MCP servers:
     - Open .mcp.json and replace placeholder tokens
     - Sentry: Get auth token from https://sentry.io/settings/auth-tokens/
     - GitHub: Uses gh CLI auth (run `gh auth login` if needed)
  6. Install suggested plugins:
     /plugin install typescript-lsp@claude-plugins-official
     /plugin install github@claude-plugins-official
  7. Try your new skills: /new-api-endpoint BookingController
```

If in audit mode, also show what was fixed vs. what was skipped.

---

## Important Notes

- This skill generates configuration that makes Claude Code work better with the project. It does NOT modify source code.
- All generated hooks use `jq` for JSON processing — this is a standard tool available on most systems.
- The Workflow Automation section in CLAUDE.md is critical — it teaches Claude when to plan, when to review, and when to suggest context management. Always include it.
- Templates are starting points. Encourage the user to customize after generation.
- For monorepos, detect the project structure and adjust paths accordingly (e.g., `laravel/` subdirectory for Laravel projects within a monorepo).
