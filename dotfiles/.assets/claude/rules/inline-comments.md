---
name: inline-comments-standards
description: When and how to write inline code comments in any language
---

## How to write inline comments

- Only comment to explain _why_, not _what_ - assume the reader knows the language.
- A comment that captures intent, a gotcha, a trade-off, a workaround, or the name of
  a non-obvious algorithm ("Fisher-Yates shuffle"), something the code cannot say for
  itself, earns its place.
- Explaining _why_ is not enough on its own: if the reason is already obvious from the codebase
  or general knowledge, don't include it
- Comments should be short and to the point tighten to the shortest phrasing that still carries
  the reason
- Never change or remove `noqa` or `type: ignore` comments unless the user explicitly
  asks you to do so or they are incorrect
- Comments are forever, written for a reader years from now who knows nothing
  about the change's history. That reader never saw the conversation that produced the page,
  and never saw the change that motivated it. That reader is the only one who matters, because
  every other reader is temporary.Never reference the incident, bug, outage, conversation, or
  review that motivated the code ("seen when X took down Y", "fixes the issue where...", "previously
  this was..."). State the present-tense invariant, risk, or trade-off instead; the history belongs
  in the commit message.
- This gate fails when the moment of writing leaks into the text. Documentation
  records the behavior that holds now. It is not a record of a change, and it is not
  a report to whoever asked for it.
- The test: if a comment only makes sense to someone who watched the change
  happen, it's commit-message material, not a comment.
- Keep inline comments to a minimum. Just because we can explain "why" we are doing something,
  doesn't mean we should. If it's self-evident, don't comment. If it doesn't add meaningful
  value to a future reader, don't comment.

### Examples of good inline comment usage

Explain WHY certain steps are made:

```python
# Process items in reverse to ensure the most recent data is prioritized over older data to match user expectations
for items in reversed(items):
    item.price = 20  # Set the price to 20 to match the competitor's pricing strategy
```

Name non-obvious algorithms and clarify tricky expressions:

```python
# This loop uses the Fisher-Yates algorithm to shuffle the array
for i in range(len(arr) - 1, 0, -1):
    j = random.randint(0, i)
    arr[i], arr[j] = arr[j], arr[i]

if i & (i - 1) == 0:  # True if i is 0 or a power of 2
```

Avoid referencing specific incidents or historical context

```python
# Bad:  restart in place (seen when an OOM-killed backup took the service down)
# Good: restart in place so a crashed sidecar can't fail the whole alloc
```
