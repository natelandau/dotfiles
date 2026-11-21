---
name: inline-comments-standards
description: When and how to write inline comments and doc comments in any language
---

## Doc comments

Applies to docstrings, JSDoc, Swift `///`, and equivalents.

- Imperative voice only. Never "This function ...".
- Explain why a developer would call it, not only what it does.
- Omit the returns section when nothing is returned.
- Document only errors the code raises or throws explicitly.

## How to write inline comments

- Comment only what the code cannot say for itself: intent, a gotcha, a trade-off, a workaround,
  or the name of a non-obvious algorithm. Never restate what the code does.
- Skip the comment when the reason is obvious from the code, the codebase, or general knowledge.
- Use the shortest phrasing that still carries the reason.
- Never change or remove `noqa` or `type: ignore` comments unless the user asks or they are
  incorrect.
- Write for a reader years from now who never saw the change or the conversation behind it. State
  the present-tense invariant, risk, or trade-off. Never reference the incident, bug, review,
  conversation, or earlier version that motivated the code. Test: if the comment only makes sense
  to someone who watched the change happen, it belongs in the commit message.

### Examples (illustrations, not templates)

```python
# Newest entries win on key collisions, matching what users see in the UI
for entry in reversed(entries):
    merged[entry.key] = entry

# Fisher-Yates shuffle
for i in range(len(arr) - 1, 0, -1):
    j = random.randint(0, i)
    arr[i], arr[j] = arr[j], arr[i]

if i & (i - 1) == 0:  # True if i is 0 or a power of 2
    ...

# Bad:  restart in place (seen when an OOM-killed backup took the service down)
# Good: restart in place so a crashed sidecar can't fail the whole alloc
```
