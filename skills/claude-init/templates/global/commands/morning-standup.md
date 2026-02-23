---
description: Summarize recent activity across git repositories for standup
disable-model-invocation: true
---

Generate a standup summary of recent work.

1. Run `git log --oneline --since="yesterday" --author="$(git config user.name)"` to find recent commits
2. Run `git diff --stat HEAD~5` to understand the scope of recent changes
3. Check for any uncommitted work: `git status --short`
4. Check for open PRs: `gh pr list --author=@me --state=open` (if `gh` is available)

Summarize in standup format:

```
## Standup — [date]

### Done
- [Completed items from recent commits]

### In Progress
- [Uncommitted changes or open PRs]

### Blockers
- [Any issues noted, or "None"]
```

If $ARGUMENTS contains a path, also check that directory's git log for additional repos.
