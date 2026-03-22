# Transfer Context

Prepare context for a new chat session when this one is degraded or hitting limits.

## Output Format

```
## Context Transfer

### Summary
[What was accomplished in this session]

### Key Decisions
- [Decision 1 and why]
- [Decision 2 and why]

### Important Context
- [Gotchas discovered]
- [Patterns to follow]
- [Things that didn't work]

### Relevant Files
- path/to/file.ts - [what it does, why it matters]
- path/to/other.ts - [description]

### Current State
[What's working, what's broken, what's next]

### Prompt for New Chat
[Ready-to-paste prompt with all necessary context to continue]
```

## Instructions

1. **Save to memory first** — Before generating the transfer, save any non-obvious learnings (user preferences, gotchas, project context) to auto-memory so the new session benefits from persistent memory too
2. Summarize what we accomplished (not just what we tried)
3. List decisions made and their reasoning
4. Note gotchas, failed approaches, important discoveries
5. List files touched with brief descriptions
6. Describe current state clearly
7. Create a complete prompt I can paste into a fresh chat

The prompt should give the new session everything it needs to continue without re-explaining.
