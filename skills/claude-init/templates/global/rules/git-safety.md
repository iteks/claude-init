---
paths:
  - "**"
---

# Git Safety

- Never commit `.env`, `.env.local`, credentials files, or files containing secrets
- Never force-push to `main` or `master` without explicit user confirmation
- Follow conventional commit format when the project's recent history uses it
- Always create new commits rather than amending unless the user explicitly requests `--amend`
- When a pre-commit hook fails, fix the issue and create a new commit — do not use `--no-verify`
- Before any `git reset --hard` or `git clean -f`, confirm with the user that no work will be lost
