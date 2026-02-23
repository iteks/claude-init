---
description: Generate a smart commit message from staged changes and commit
disable-model-invocation: true
---

Create a commit for the currently staged changes.

1. Run `git diff --staged` to see what's being committed
2. Run `git log --oneline -5` to match the project's commit message style
3. Analyze the changes and draft a concise commit message:
   - Summarize the "why" not the "what"
   - Use conventional commit format if the project follows it (check recent commits)
   - Keep the first line under 72 characters
4. If $ARGUMENTS is provided, use it as guidance for the commit message
5. Show the drafted message and ask for confirmation before committing
6. Create the commit

If nothing is staged, run `git status` and suggest what to stage.
