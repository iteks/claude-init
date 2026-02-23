---
paths:
  - "**"
---

# File Safety

- Never delete files or directories without confirming with the user first
- Never overwrite uncommitted changes without warning
- Protect dotfiles (`.env`, `.gitignore`, `.editorconfig`, config files) — read before modifying
- When encountering unfamiliar files or directories, investigate before removing
- Prefer editing existing files over creating new ones to avoid file bloat
- Never modify lock files (`package-lock.json`, `composer.lock`, `poetry.lock`) directly — use the package manager
