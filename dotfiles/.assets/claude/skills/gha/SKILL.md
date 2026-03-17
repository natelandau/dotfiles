---
name: gha
description: Analyze GitHub Actions failures and identify root causes. Use when asked to investigate a CI/CD GitHub Actions failure and recommend a fix.
argument-hint: <url>
---

Investigate this GitHub Actions URL: $ARGUMENTS

Use the gh CLI to analyze this workflow run. Your investigation should:

1. **Get basic info & identify actual failure**:
    - What workflow/job failed, when, and on which commit?
    - CRITICAL: Read the full logs carefully to find what SPECIFICALLY caused the exit code 1
    - Distinguish between warnings/non-fatal errors vs actual failures
    - Look for patterns like "failing:", "fatal:", or script logic that determines when to exit 1
    - If you see both "non-fatal" and "fatal" errors, focus on what actually caused the failure

2. **Check flakiness**: Check the past 10-20 runs of THE EXACT SAME failing job:
    - IMPORTANT: If a workflow has multiple jobs, you must check history for the SPECIFIC JOB that failed, not just the workflow
    - Use `gh run list --workflow=<workflow-name>` to get run IDs, then `gh run view <run-id> --json jobs` to check the specific job's status
    - Is this a one-time failure or recurring pattern for THIS SPECIFIC JOB?
    - What's the success rate for THIS JOB recently?
    - When did THIS JOB last pass?

3. **Identify breaking commit** (if there's a pattern of failures for the specific job):
    - Find the first run where THIS SPECIFIC JOB failed and the last run where it passed
    - Identify the commit that introduced the failure
    - Verify by checking: does THIS JOB fail in ALL runs after that commit? Does it pass in ALL runs before?
    - If verified, report the breaking commit with high confidence

4. **Root cause**: Based on logs, history, and any breaking commit, what's the likely cause?
    - Focus on what ACTUALLY caused the failure (not just any errors you see)
    - Verify your hypothesis against the logs and failure logic

5. **Check for existing fix PRs**: Search for open PRs that might already address this issue:
    - Use `gh pr list --state open --search "<keywords>"` with relevant error messages or file names
    - Check if any open PR modifies the failing file/workflow
    - If a fix PR exists, note it in your report and skip the recommendation section

Write a final report with:

- Summary of failure (what specifically triggered the exit code 1)
- Flakiness assessment (one-time vs recurring, success rate)
- Breaking commit (if identified and verified)
- Root cause analysis (based on the ACTUAL failure trigger)
- Existing fix PR (if found - include PR number and link)
- Recommendation (skip if fix PR already exists)
