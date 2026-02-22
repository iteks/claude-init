# claude-init

**Stop configuring Claude Code manually. Start building.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Analyze any project and generate optimal Claude Code integration — hooks, rules, agents, skills, commands, MCP servers, settings, and CLAUDE.md — in one command.

---

## What It Does

- **Detects your stack** — language, framework, test runner, linter, formatter, package manager
- **Generates `.claude/` config** — format-on-save hooks, safety guards, path-scoped rules, security review agents
- **Detects dev commands** — extracts scripts from package.json, Makefile, composer.json, and more
- **Suggests MCP servers** — detects Sentry, GitHub, Slack, Figma dependencies and generates `.mcp.json`
- **Generates slash commands** — creates `/review-changes`, `/run-tests`, `/dev` commands
- **Scaffolds skills** — creates guided workflows like `/new-api-endpoint` for detected patterns
- **Suggests plugins** — recommends official marketplace plugins (LSP, GitHub, Sentry, etc.)
- **Tunes permissions** — auto-approves test/lint/format commands, blocks dangerous operations
- **Optimizes global settings** — permission pre-approvals, safety denials, Agent Teams
- **Keeps CLAUDE.md under 300 lines** — distributes conventions into rules and skills so Claude actually follows them

## Quick Start

```bash
# Clone and install (one-time)
git clone https://github.com/iteks/claude-init.git ~/.claude-init
bash ~/.claude-init/install.sh

# In any project:
cd ~/my-project && claude
/claude-init
```

That's it. The install creates a global `/claude-init` skill available in every project, plus permission optimizations so you stop clicking "Allow" on every read-only command.

**To update:** `/claude-init update` (inside any Claude Code session)
**To uninstall:** `bash ~/.claude-init/uninstall.sh`

---

## What Install Does

The `install.sh` script does two things:

**1. Installs the `/claude-init` skill globally**
- Symlinks `~/.claude/skills/claude-init` to the cloned repo
- Makes `/claude-init` available in every Claude Code session
- Updates via `/claude-init update` — fetches latest release and applies it

**2. Optimizes global permissions**
- Auto-approves read-only commands: `git status`, `ls`, `gh pr view`, `jq`, etc.
- Auto-denies dangerous commands: `rm -rf /`, `sudo rm`, `chmod 777`, `curl|bash`
- Enables Agent Teams (multi-agent orchestration via tmux)

---

## Three Modes

### 1. New Project (empty repo)

```
/claude-init
> No source code detected — entering New Project Mode

? Project type: API
? Framework: Laravel
? Description: A booking platform for local services
? Testing: Pest

Generating Claude Code config for Laravel API...
```

Prompts for your intent and generates config from the planned stack.

### 2. Existing Project (no Claude Code config)

```
/claude-init
> Source code detected, no .claude/ directory — entering Existing Project Mode

Detected stack:
  Language:    PHP 8.3
  Framework:   Laravel 12
  Testing:     Pest
  Formatter:   Duster
  Package Mgr: Composer

Proceed with generating Claude Code config? [Yes / Customize / Skip]
```

Reads your code to extract conventions, then generates config that matches your actual patterns.

### 3. Existing Config (audit mode)

```
/claude-init
> Existing .claude/ directory detected — entering Audit Mode

Claude Code Integration Audit — ~/my-project

Stack: PHP 8.3 / Laravel 12 / Pest / Duster

Hooks
  [ok] guard-git-push.sh exists
  [missing] format-php.sh (Duster detected but no auto-format hook)
  [missing] guard-env.sh (.env files are unprotected)

Rules
  [ok] testing-conventions.md (paths match)
  [missing] migration-safety.md (database/migrations/ exists)
  [warning] Dead rule: api-conventions.md — pattern "src/api/**" matches no files

CLAUDE.md
  [warning] 347 lines — recommend splitting to under 300
  [missing] Workflow Automation section

Agents
  [missing] code-reviewer agent
  [missing] security-reviewer agent
  [missing] test-generator agent (Pest detected)

Settings
  [ok] plan mode enabled
  [missing] guard-env.sh hook (detected .env files)

Fix all gaps? [Yes / Pick individually / Skip]
```

Scans your existing setup, reports gaps, and offers to fix them without overwriting anything.

---

## What Gets Generated

```
.claude/
├── settings.json              # Hooks, permissions (allow + deny), settings
├── hooks/
│   ├── guard-git-push.sh      # Prompts before git push
│   ├── guard-env.sh           # Blocks .env edits (use .env.example)
│   ├── format-php.sh          # Auto-formats PHP with Duster/Pint on every edit
│   └── lint-shellcheck.sh     # Runs shellcheck on shell scripts (shell projects)
├── rules/
│   ├── testing-pest.md        # Pest conventions scoped to tests/**
│   ├── migration-safety.md    # Migration safety scoped to database/migrations/**
│   └── api-conventions.md     # API conventions scoped to routes/api/**, Controllers/Api/**
├── agents/
│   ├── code-reviewer.md       # Code quality review agent (all projects)
│   ├── security-reviewer.md   # Security review agent for your stack
│   ├── test-generator.md      # Test generation agent (when test framework detected)
│   └── ...                    # Additional agents based on project signals
├── skills/                    # Guided workflows (when patterns detected)
│   ├── new-api-endpoint/      # /new-api-endpoint — scaffold API endpoints
│   └── new-test-suite/        # /new-test-suite — scaffold test files
└── commands/                  # Slash commands
    ├── review-changes.md      # /review-changes — review uncommitted changes
    ├── run-tests.md           # /run-tests — run test suite
    └── dev.md                 # /dev — start dev server

.mcp.json                      # MCP server configs (Sentry, GitHub, Slack, Figma)
CLAUDE.md                      # Project overview, conventions, workflow automation (<300 lines)
```

### Why Each File Matters

| File | What It Does | Impact |
|---|---|---|
| `format-*.sh` | Auto-formats on every edit | Eliminates formatting conversations entirely |
| `guard-env.sh` | Blocks `.env` edits | Prevents accidental secret exposure |
| `guard-git-push.sh` | Prompts before push | Catches premature pushes |
| `testing-*.md` | Path-scoped test conventions | Claude follows your test patterns exactly |
| `migration-safety.md` | Blocks dangerous migrations | Prevents `migrate:fresh` on production data |
| `code-reviewer.md` | On-demand code quality review | Catches bugs, logic errors, and convention violations |
| `security-reviewer.md` | On-demand security audit | Catches OWASP Top 10 in code reviews |
| `test-generator.md` | On-demand test generation | Creates tests matching your framework and conventions |
| `CLAUDE.md` | Project context + workflow automation | Claude plans, reviews, and manages context proactively |
| `lint-shellcheck.sh` | Runs shellcheck after editing `.sh` files | Catches shell script bugs automatically |
| `skills/*/SKILL.md` | Guided workflows for common project tasks | `/new-api-endpoint` scaffolds a complete endpoint |
| `commands/*.md` | Quick slash commands | `/review-changes` reviews uncommitted changes |
| `.mcp.json` | MCP server integrations | Connects Claude to Sentry, GitHub, Slack, Figma |
| `permissions.allow` | Pre-approved commands | Stops "Allow?" prompts for test/lint/format commands |
| `permissions.deny` | Blocked commands | Prevents `rm -rf`, `migrate:fresh`, dangerous ops |

---

### Codebase-Aware Agent Suggestions

Beyond the core three agents (code-reviewer, security-reviewer, test-generator), claude-init scans your project structure for signals that indicate additional agents would be useful.

| Signal | What's Detected | Agent Generated |
|---|---|---|
| Database migrations | `database/migrations/`, `prisma/migrations/`, etc. | `migration-reviewer` — reviews migrations for data safety and rollback correctness |
| API routes | `routes/api/`, `app/Http/Controllers/Api/`, `pages/api/`, etc. | `api-reviewer` — reviews API endpoints for consistency and error handling |
| ORM relationships | 5+ models with relationship definitions | `performance-reviewer` — detects N+1 queries and complexity issues |
| Web components | 10+ component files | `accessibility-reviewer` — checks WCAG 2.1 AA compliance |
| CI/CD config | `.github/workflows/`, `.circleci/`, etc. | `ci-reviewer` — reviews pipeline efficiency and safety |
| Sparse docs | Missing or minimal README/docs | `documentation-generator` — generates missing documentation |
| 50+ dependencies | Large dependency tree in lock file | `dependency-analyzer` — checks for CVEs, unused deps, license conflicts |

Agents are suggested — not forced. You choose which to include during setup.

---

### MCP Server Integration

claude-init detects project dependencies that have official Anthropic MCP servers and generates `.mcp.json` configuration:

| Signal | Detection | MCP Server |
|---|---|---|
| Sentry SDK | `@sentry/node`, `sentry-sdk`, `sentry/sentry-laravel` in deps | `@anthropic/claude-code-sentry` |
| GitHub remote | `github.com` in `.git/config` | `@anthropic/claude-code-github` |
| Slack SDK | `@slack/web-api`, `@slack/bolt` in deps | `@anthropic/claude-code-slack` |
| Figma references | Figma URLs in source files, `figma-api` in deps | `@anthropic/claude-code-figma` |

MCP configs include placeholder tokens that you fill in after generation. `.mcp.json` is added to `.gitignore` (it contains auth tokens).

---

### Custom Skill Generation

When common project patterns are detected, claude-init generates guided skill workflows:

| Signal | Skill Generated | Usage |
|---|---|---|
| Laravel API routes | `/new-api-endpoint` | Scaffolds route + controller + resource + form request + tests |
| React/Expo components (10+) | `/new-component` | Scaffolds component + props + test file |
| Django apps | `/new-django-app` | Scaffolds app with models + views + URLs + tests |
| Any test framework | `/new-test-suite` | Scaffolds tests for existing code |
| FastAPI routers | `/new-router` | Scaffolds router + schemas + service + tests |

---

### Slash Commands

Every project gets useful slash commands generated in `.claude/commands/`:

| Command | Purpose | Available When |
|---|---|---|
| `/review-changes` | Review uncommitted changes for bugs and quality | Always |
| `/run-tests` | Run the test suite with smart defaults | Test framework detected |
| `/dev` | Start the development server | Dev command detected |

---

### Plugin Suggestions

claude-init detects your stack and suggests official marketplace plugins to install:

**LSP Plugins** (code intelligence — jump to definition, find references, diagnostics):

| Language | Plugin | Install |
|---|---|---|
| TypeScript | `typescript-lsp` | `/plugin install typescript-lsp@claude-plugins-official` |
| Python | `pyright-lsp` | `/plugin install pyright-lsp@claude-plugins-official` |
| PHP | `php-lsp` | `/plugin install php-lsp@claude-plugins-official` |
| Go | `gopls-lsp` | `/plugin install gopls-lsp@claude-plugins-official` |
| Rust | `rust-analyzer-lsp` | `/plugin install rust-analyzer-lsp@claude-plugins-official` |

**Integration Plugins**: `github`, `sentry`, `slack`, `figma` — suggested when corresponding dependencies are detected.

Plugin install commands are included in the Phase 5 report.

---

### Per-Project Permissions

claude-init generates `permissions.allow` and `permissions.deny` arrays in `.claude/settings.json` based on detected tools:

```json
{
  "permissions": {
    "allow": [
      "Bash(php artisan test*)",
      "Bash(./vendor/bin/pest*)",
      "Bash(./vendor/bin/duster fix*)",
      "Bash(composer install*)"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(php artisan migrate:fresh*)",
      "Bash(php artisan migrate:reset*)"
    ]
  }
}
```

This eliminates "Allow?" prompts for safe commands while blocking dangerous operations.

---

### Dev Command Detection

claude-init reads your project's command sources and maps them to canonical slots:

| Source | Commands Extracted |
|---|---|
| `package.json` scripts | dev, build, test, lint, format, start, typecheck |
| `composer.json` scripts | test, lint, format |
| `Makefile` targets | Any matching canonical slot names |
| `Justfile` recipes | Any matching canonical slot names |
| `Taskfile.yml` tasks | Any matching canonical slot names |
| `pyproject.toml` scripts | Any matching canonical slot names |

Detected commands populate CLAUDE.md dev instructions, generate permission allow patterns, and configure `/run-tests` and `/dev` command templates.

---

## Supported Stacks

| Stack | Hooks | Rules | Agents | Skills | Commands | MCP | Permissions |
|---|---|---|---|---|---|---|---|
| PHP / Laravel | format-php, guard-env, guard-push, migration-guard | testing-pest, migration-safety, api-conventions | code-reviewer, security-reviewer-php, test-generator-pest + suggested | new-api-endpoint, new-test-suite | review-changes, run-tests, dev | Sentry, GitHub | test, format, artisan |
| JS / Next.js | lint-changed, typecheck-changed, guard-config, guard-env, guard-push | testing-jest/vitest, component-conventions | code-reviewer, security-reviewer-js, test-generator + suggested | new-component, new-test-suite | review-changes, run-tests, dev | GitHub | test, lint, npm |
| JS / Expo | lint-changed, typecheck-changed, guard-config, guard-push | testing-jest, component-conventions | code-reviewer, security-reviewer-js, test-generator-jest + suggested | new-component, new-test-suite | review-changes, run-tests, dev | GitHub | test, lint, npm |
| Python / Django | format-python, guard-env, guard-push | testing-pytest | code-reviewer, security-reviewer-python, test-generator-pytest + suggested | new-django-app, new-test-suite | review-changes, run-tests, dev | Sentry, GitHub | test, format, manage.py |
| Python / FastAPI | format-python, guard-env, guard-push | testing-pytest | code-reviewer, security-reviewer-python, test-generator-pytest + suggested | new-router, new-test-suite | review-changes, run-tests, dev | GitHub | test, format, pip |
| Go | format-go, guard-env, guard-push | — | code-reviewer, security-reviewer-generic + suggested | new-test-suite | review-changes, run-tests | GitHub | test, go |
| Rust | format-rust, guard-env, guard-push | — | code-reviewer, security-reviewer-generic + suggested | new-test-suite | review-changes, run-tests | GitHub | test, cargo |
| Other | guard-env, guard-push, shellcheck (if shell) | — | code-reviewer, security-reviewer-generic | new-test-suite (if tests) | review-changes | GitHub (if remote) | detected tools |

**Adding a new stack?** See [Contributing](#contributing).

---

## How It Works

```
/claude-init
      |
      v
+-- Phase 1: Detect State ------+
| Has .claude/?  Has source?     |  (main session — lightweight)
| -> New / Existing / Audit      |
+---------------+----------------+
                |
         +------+------+
         v             v
  +-- Phase 2A --+  +-- Phase 2B --------+
  | Prompt user  |  | Detect stack       |
  | (main        |  | + dev commands     |
  |  session)    |  | + infrastructure   |
  +---------+----+  | (subagent: haiku)  |
            |       +--------+-----------+
            |                |
            |    +-- Phase 2B.5-2B.9 ------+
            |    | Signal scan             |
            |    | Agent suggestions       |
            |    | MCP server suggestions  |
            |    | Skill suggestions       |
            |    | Plugin + cmd suggestions|
            |    | (same subagent)         |
            |    +--------+----------------+
            +------+------+
                   v
          User confirms stack
          User selects agents, skills,
          MCP servers, commands, plugins
            (main session)
                   |
                   v
          +-- Phase 3+4 -----------+
          | Generate + Validate    |
          | (subagent: sonnet)     |
          | -> settings.json       |
          |    hooks, rules, agents|
          |    skills, commands    |
          |    .mcp.json, CLAUDE.md|
          |    permissions         |
          +---------+--------------+
                    v
          +-- Phase 5 -------------+
          | Report results         |  (main session)
          | Plugin install cmds    |
          | Suggest next steps     |
          +------------------------+
```

---

## Context Preservation

claude-init delegates heavy file-scanning and template-generation phases to subagents. This keeps the main session's context window clean:

- **Detection** (Phase 2B + 2B.5-2B.9) runs in a haiku subagent — all lock file reading, convention extraction, signal scanning, and MCP/skill/plugin detection happens outside the main context
- **Generation** (Phase 3 + 4) runs in a sonnet subagent — template reading, placeholder replacement, file writing, permission generation, and validation happen outside the main context
- **The main session** handles only Phase 1 (three file checks), user interaction (prompts, confirmations), and Phase 5 (displaying the summary)

After `/claude-init` completes, the session is ready for productive work without needing `/compact` or `/clear`.

---

## Audit Mode Deep Dive

The audit is the key differentiator for teams already using Claude Code. Here's what it checks:

| Category | What It Looks For | Example Gap |
|---|---|---|
| **Hooks** | Missing format-on-save for detected formatter | Duster installed but no auto-format hook |
| **Hooks** | Missing safety guards | No guard-env.sh blocking .env edits |
| **Hooks** | Broken references | settings.json references hook that doesn't exist |
| **Rules** | Missing conventions for key directories | `tests/` exists but no testing rule |
| **Rules** | Dead rules — globs that match nothing | Rule for `src/api/**` but API is at `app/Http/` |
| **CLAUDE.md** | Over 300 lines | Claude starts ignoring rules unpredictably |
| **CLAUDE.md** | Missing Workflow Automation section | No plan mode triggers or review offers |
| **Agents** | Missing code-reviewer, security-reviewer, or test-generator | No review or test generation agents for the stack |
| **Agents** | Incorrect frontmatter (`allowed-tools` instead of `tools`) | Agent may not function correctly |
| **Settings** | Missing hooks or permissions | Detected formatter but no auto-format hook |
| **Hygiene** | `settings.local.json` not in `.gitignore` | Machine-specific config being committed |
| **MCP** | MCP configs for detected services | Sentry SDK found but no `.mcp.json` entry |
| **Skills** | Skills for detected project patterns | API routes exist but no `/new-api-endpoint` skill |
| **Commands** | Common slash commands | No `/review-changes` or `/run-tests` commands |
| **Permissions** | Allow/deny patterns for detected tools | Pest detected but no test command pre-approved |
| **Plugins** | Official marketplace plugins for detected stack | TypeScript project without LSP plugin |

### Merge Behavior

When fixing gaps:
- **Never overwrites** existing files
- Adds missing hooks alongside existing ones
- Adds missing rules as new files
- Appends missing CLAUDE.md sections (if under 300 line limit)
- Merges missing entries into settings.json

---

## Comparison

| Feature | claude-init | [claude-bootstrap](https://github.com/alinaqi/claude-bootstrap) | [starter-kit](https://github.com/cloudnative-co/claude-code-starter-kit) | [cc-bootstrap](https://github.com/vinodismyname/ClaudeCodeBootstrap) |
|---|---|---|---|---|
| Stack detection | Automatic | None | None | LLM-based |
| Format-on-save hooks | Per-language | None | Generic | None |
| Path-scoped rules | With validation | None | None | None |
| Rule validation | Verifies globs match files | — | — | — |
| Existing config audit | Full gap analysis | None | None | None |
| Permission optimization | Read-only pre-approvals | None | None | None |
| CLAUDE.md right-sizing | Under 300 lines | No limit | No limit | No limit |
| Empty project support | Prompted flow | None | Prompted | Prompted |
| External dependencies | Minimal (bash + jq) | None | None | Python 3.12 + API keys |
| MCP server detection | Automatic | None | None | None |
| Skill generation | Framework-specific | None | None | None |
| Command generation | Common workflows | None | None | None |
| Plugin suggestions | Official marketplace | None | None | None |
| Permission tuning | Per-project allow/deny | None | None | None |
| Dev command extraction | Multi-source | None | None | None |
| Self-configuration | Full .claude/ setup | None | None | None |
| Distribution | Git clone + global skill | Git clone | Git clone | pip install |

---

## Global Permission Details

The `install.sh` script merges these into `~/.claude/settings.json`:

**Auto-approved (read-only, zero side effects):**
- Git reads: `status`, `log`, `diff`, `branch`, `show`, `rev-parse`, `ls-files`, `remote`, `tag`, `describe`
- Git update ops: `fetch`, `ls-remote`, `checkout v*` (for self-update)
- Filesystem: `ls`, `wc`, `sort`, `uniq`, `pwd`, `which`
- GitHub CLI: `issue view/list`, `pr view/list/checks`, `repo view`, `api`
- Metadata: `--version`, `--help`
- Data processing: `jq`

**Auto-denied (universally dangerous):**
- `rm -rf /`, `rm -rf ~*`, `sudo rm`, `chmod 777`, `curl|bash`, `wget|bash`

**Environment:**
- Agent Teams enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)

---

## FAQ

**Does it overwrite my existing config?**
No. In audit/merge mode, it only adds missing files and entries. Existing files are never modified without confirmation.

**What if I don't like a generated hook or rule?**
Delete it. Each hook and rule is an independent file. Remove the file and its reference in `.claude/settings.json`.

**Can I customize templates?**
Yes. Fork the repo, modify templates in `skills/claude-init/templates/`, and point your symlink at your fork.

**Does it work on Windows?**
Hook scripts use bash and `jq`, which are available in WSL and Git Bash. The `/claude-init` skill works anywhere Claude Code runs.

**What's the 300-line CLAUDE.md limit about?**
Community testing shows Claude starts ignoring rules unpredictably when CLAUDE.md exceeds ~300 lines. claude-init distributes detailed conventions into path-scoped rules (which only load when relevant files are touched) to keep CLAUDE.md concise.

**How do I update?**
Run `/claude-init update` inside any Claude Code session. This fetches the latest release tag and checks it out. The symlink means updates take effect immediately — no reinstall needed.

**Can I install somewhere other than ~/.claude-init?**
Yes. Clone wherever you want. The symlink points to wherever you cloned it.

---

## Keeping Projects Updated

claude-init uses **semver tags** (e.g., `v1.0.0`, `v1.2.0`) for version identity and a **two-tier update detection** system.

### Update detection

**Tier 1 — Local check (every session, no network):**
Compares the project's stamped version against the locally installed version. Catches "tool was already updated but project hasn't re-run `/claude-init`":
```
claude-init updated to v1.2.0 (project configured with v1.0.0). Run /claude-init to upgrade this project.
```

**Tier 2 — Remote check (once per day, network):**
Queries the remote repository for the latest tag. If a newer version exists:
```
claude-init v1.2.0 available (you have v1.0.0). Run: /claude-init update
```

The remote check is throttled to once per day (epoch-day model). Skipped automatically in CI environments (`CI=true`) or when opted out (`CLAUDE_INIT_NO_UPDATE_CHECK=1`).

### Self-update

Run `/claude-init update` inside any Claude Code session to update to the latest release. This:
1. Fetches the latest tags from the remote
2. Checks out the newest semver tag
3. Reports what changed (e.g., `Updated claude-init: v1.0.0 -> v1.2.0`)
4. Prompts to re-run `/claude-init` to apply updates to the current project

### Smart upgrade

Running `/claude-init` on an already-configured project enters Audit Mode, which:
- Shows what version the project was configured with
- Lists new capabilities available since the last run
- Scans for gaps and offers to fill them
- Never overwrites existing config — only adds what's missing

### Version file

Each configured project gets `.claude/.claude-init-version` tracking the tool version (semver tag) and which capabilities were generated. This file is machine-specific and should be in `.gitignore`.

### Opt-out

Set `CLAUDE_INIT_NO_UPDATE_CHECK=1` to disable all update checks. Checks are also skipped when `CI=true`.

---

## Contributing

### Adding a New Stack

1. Create hook templates in `skills/claude-init/templates/hooks/[language]/`
2. Create rule templates in `skills/claude-init/templates/rules/[language]/`
3. Create a settings template in `skills/claude-init/templates/settings/[framework].json`
4. Create a CLAUDE.md template in `skills/claude-init/templates/claude-md/[framework].md`
5. Create agent templates in `skills/claude-init/templates/agents/` (security-reviewer and test-generator variants for the language)
6. Add detection logic to `skills/claude-init/SKILL.md` (Phase 2B detection tables)
7. Add template mapping to Phase 3 template selection table
8. Submit a PR

### Self-Configuration

This repo uses its own `.claude/` configuration — hooks, rules, and agents are set up for developing claude-init itself. See `.claude/rules/template-conventions.md` and `.claude/rules/contributing.md` for detailed conventions.

### Reporting Issues

- Open an issue at [github.com/iteks/claude-init/issues](https://github.com/iteks/claude-init/issues)
- Include your stack (language, framework, versions)
- Include the output of `/claude-init` if applicable

---

## License

[MIT](LICENSE) — Use it, fork it, customize it, share it.
