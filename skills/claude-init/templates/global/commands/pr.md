---
description: Create a pull request with auto-generated title and body
disable-model-invocation: true
---

Create a pull request for the current branch.

1. Run `git log --oneline main..HEAD` (or the appropriate base branch) to see all commits
2. Run `git diff main...HEAD --stat` to see the scope of changes
3. Analyze all commits and changed files to generate:
   - **Title**: Short, descriptive (under 70 characters)
   - **Summary**: 1-3 bullet points covering the key changes
   - **Test plan**: Checklist of testing steps
4. If $ARGUMENTS is provided, use it as additional context for the PR description
5. Show the drafted PR and ask for confirmation
6. Create the PR using `gh pr create`

If the branch has no remote tracking, push it first with `git push -u origin HEAD`.

If `gh` is not available, output the PR title and body so the user can create it manually.
