---
name: Bash style and standards
description: How to write Bash scripts
paths:
- '**/*.sh'
---
## Bash style and standards

-   **String Manipulation:** Use Bash's built-in string manipulation features (e.g., parameter expansion, substring extraction) instead of external commands like `sed` or `awk` when possible.
-   **File Handling:** Use Bash's built-in file handling commands (e.g., `read`, `write`, `mkdir`, `rm`) for basic operations. For more complex operations, consider `find` with `-exec` or `xargs`.
-   **Looping:** Use `for` loops for iterating over lists of items and `while` loops for conditional execution.
-   **Conditional Statements:** Use `if`, `elif`, and `else` statements for branching logic. Prefer `[[ ]]` over `[ ]` for string comparisons.
-   **Exit Early:** Use `return` or `exit` to exit the script as soon as an error is detected.
-   Always quote variables to prevent word splitting and globbing issues.
-   Avoid using `eval` as it can introduce security vulnerabilities and make the code difficult to understand.
-   Use `$(command)` instead of backticks for command substitution.
-   Minimize the use of global variables to avoid naming conflicts and unexpected side effects. Use `local` within functions.
-   Always check the return values of commands to handle errors gracefully. Use `set -e` to exit on errors automatically.
-   Comments should explain _why_ the code is doing something, not _what_ the code is doing.
-   While powerful, long pipelines can become unreadable. Consider breaking down complex operations into smaller, more manageable steps with intermediate variables.
-   Use temporary files to store intermediate data during script execution. Use `mktemp` to create unique temporary file names and remove them when finished. They should be created under `/tmp` or another location if needed.
-   Use `printf` for formatted output instead of `echo`, as it is generally faster and more portable.
