# claude-init

**Stop configuring Claude Code manually. Start building.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Analyze any project and generate optimal Claude Code integration — hooks, rules, agents, settings, and CLAUDE.md — in one command.

---

## What It Does

- **Detects your stack** — language, framework, test runner, linter, formatter, package manager
- **Generates `.claude/` config** — format-on-save hooks, safety guards, path-scoped rules, security review agents
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

**To update:** `cd ~/.claude-init && git pull`
**To uninstall:** `bash ~/.claude-init/uninstall.sh`

---

## What Install Does

The `install.sh` script does two things:

**1. Installs the `/claude-init` skill globally**
- Symlinks `~/.claude/skills/claude-init` to the cloned repo
- Makes `/claude-init` available in every Claude Code session
- Updates automatically when you `git pull`

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
├── settings.json              # Hooks, permissions, settings
├── hooks/
│   ├── guard-git-push.sh      # Prompts before git push
│   ├── guard-env.sh           # Blocks .env edits (use .env.example)
│   └── format-php.sh          # Auto-formats PHP with Duster/Pint on every edit
├── rules/
│   ├── testing-pest.md        # Pest conventions scoped to tests/**
│   ├── migration-safety.md    # Migration safety scoped to database/migrations/**
│   └── api-conventions.md     # API conventions scoped to routes/api/**, Controllers/Api/**
└── agents/
    ├── code-reviewer.md       # Code quality review agent (all projects)
    ├── security-reviewer.md   # Security review agent for your stack
    ├── test-generator.md      # Test generation agent (when test framework detected)
    └── ...                    # Additional agents based on project signals:
        # migration-reviewer.md   — when migrations detected
        # api-reviewer.md         — when API routes detected
        # performance-reviewer.md — when ORM models with relationships detected
        # + dynamic agents (accessibility, CI, docs, dependencies)

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

## Supported Stacks

| Stack | Hooks | Rules | Agents | Suggested Agents | Settings | CLAUDE.md |
|---|---|---|---|---|---|---|
| PHP / Laravel | format-php, guard-env, guard-push, migration-guard | testing-pest, migration-safety, api-conventions | code-reviewer, security-reviewer-php, test-generator-pest | migration-reviewer, api-reviewer, performance-reviewer | laravel-boost, php-lsp, pest plugins | Full template |
| JS / Next.js | lint-changed, typecheck-changed, guard-config, guard-env, guard-push | testing-jest/vitest, component-conventions | code-reviewer, security-reviewer-js, test-generator-jest/vitest | api-reviewer, performance-reviewer | typescript-lsp plugins | Full template |
| JS / Expo | lint-changed, typecheck-changed, guard-config, guard-push | testing-jest, component-conventions | code-reviewer, security-reviewer-js, test-generator-jest | api-reviewer, performance-reviewer | typescript-lsp plugins | Full template |
| Python / Django | format-python, guard-env, guard-push | testing-pytest | code-reviewer, security-reviewer-python, test-generator-pytest | migration-reviewer, api-reviewer, performance-reviewer | python plugins | Full template |
| Python / FastAPI | format-python, guard-env, guard-push | testing-pytest | code-reviewer, security-reviewer-python, test-generator-pytest | api-reviewer, performance-reviewer | python plugins | Full template |
| Go | format-go, guard-env, guard-push | — | code-reviewer, security-reviewer-generic | performance-reviewer | — | Generic template |
| Rust | format-rust, guard-env, guard-push | — | code-reviewer, security-reviewer-generic | performance-reviewer | — | Generic template |
| Other | guard-env, guard-push | — | code-reviewer, security-reviewer-generic | (signal-based) | — | Generic template |

**Adding a new stack?** See [Contributing](#contributing).

---

## How It Works

```
/claude-init
      |
      v
+-- Detect State ----------------+
| Has .claude/?  Has source?     |
| -> New / Existing / Audit      |
+---------------+----------------+
                |
         +------+------+
         v             v
   +- Detect -+  +- Prompt -+
   | language  |  | type?    |
   | framework |  | frame?   |
   | test      |  | desc?    |
   | formatter |  | testing? |
   | pkg mgr   |  +----+-----+
   +-----+-----+       |
         +------+-------+
                v
       +- Generate ------------+
       | Read templates         |
       | Replace placeholders   |
       | Adjust paths           |
       | Write files            |
       +---------+--------------+
                 v
       +- Validate ------------+
       | chmod +x hooks         |
       | Valid JSON?            |
       | Rules match files?     |
       | CLAUDE.md < 300 ln     |
       +---------+--------------+
                 v
       +- Report --------------+
       | List created files     |
       | Suggest next steps     |
       +------------------------+
```

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
| Distribution | Git clone + global skill | Git clone | Git clone | pip install |

---

## Global Permission Details

The `install.sh` script merges these into `~/.claude/settings.json`:

**Auto-approved (read-only, zero side effects):**
- Git reads: `status`, `log`, `diff`, `branch`, `show`, `rev-parse`, `ls-files`, `remote`
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
`cd ~/.claude-init && git pull`. The symlink means updates take effect immediately — no reinstall needed.

**Can I install somewhere other than ~/.claude-init?**
Yes. Clone wherever you want. The symlink points to wherever you cloned it.

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

### Reporting Issues

- Open an issue at [github.com/iteks/claude-init/issues](https://github.com/iteks/claude-init/issues)
- Include your stack (language, framework, versions)
- Include the output of `/claude-init` if applicable

---

## License

[MIT](LICENSE) — Use it, fork it, customize it, share it.
