---
description: Review uncommitted changes for bugs, logic errors, and quality issues
disable-model-invocation: true
---

Review all uncommitted changes in this repository for potential issues.

1. Run `git diff` to see unstaged changes and `git diff --staged` to see staged changes
2. For each modified file, read the full file to understand context around the changes
3. Review the changes for:
   - Logic errors or bugs introduced by the changes
   - Missing error handling for new code paths
   - Inconsistencies with existing patterns in the codebase
   - Security concerns (especially in input handling, auth, or data access)
   - Missing test coverage for new functionality

4. Report findings using the format:
   ### [P0|P1|P2] — Brief title
   **File**: `path/to/file:LINE`
   Description and suggested fix.

5. End with a summary: files reviewed, finding counts, and overall verdict (APPROVE / REQUEST CHANGES / APPROVE WITH COMMENTS).

If $ARGUMENTS is provided, focus the review on files matching that pattern.
