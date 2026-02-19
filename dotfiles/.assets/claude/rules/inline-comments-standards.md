---
name: inline-comments-standards
description: How to write inline comments
---
## How to write inline comments

**Always** follow these standards for writing inline comments within the codebase to enhance understanding and avoid clutter.

1. Use comments sparingly, and when you do write comments, make them meaningful.
2. Don't comment on obvious things. Excessive or unclear comments can clutter the codebase and become outdated.
3. Only use comments to convey the "why" behind specific actions or to explain unusual behavior and potential pitfalls.
4. In python use `#` for single-line comments and `"""` for multi-line comments.
5. Never change or remove 'noqa' or 'type: ignore' comments unless the user explicitly asks you to do so or they are incorrect.
6. Never describe the code in a comment. Assume the person reading the code knows how to read the code better than you do.

### Examples of good inline comment usage:

These comments are good because they explain WHY certain steps are made

```python
# Process items in reverse to ensure the most recent data is prioritized over older data to match user expectations
for items in reversed(items):
    item.price = 20 # Set the price to 20 to match the competitor's pricing strategy
```

This comment is good because it clarifies complex logic

```python
# This loop uses the Fisher-Yates algorithm to shuffle the array

for i in range(len(arr) - 1, 0, -1):
    j = random.randint(0, i)
    arr[i], arr[j] = arr[j], arr[i]

# We use a weighted dictionary search to find out where i is in
# the array.  We extrapolate position based on the largest num
# in the array and the array size and then do binary search to
# get the exact number.

if i & (i-1) == 0:  # True if i is 0 or a power of 2.
```
