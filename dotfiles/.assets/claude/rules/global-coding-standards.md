---
name: global-coding-standards
description: Global coding style and standards
---
## Global coding style and standards

-   **Only modify code directly relevant to the specific request.** Avoid changing unrelated functionality.
-   **Break problems into smaller steps.** Think through each step separately before implementing.
-   Always provide a complete **PLAN** with **REASONING** based on evidence from code and logs before making changes.
-   Explain your **OBSERVATIONS** clearly, then provide **REASONING** to identify the exact issue. Add console logs when needed to gather more information.
-   In code, write comments ONLY in English.
-   **Make minimal changes to files** - modify only what's necessary to complete the task. While ensuring the solution is complete, aim for the smallest possible number of line changes to maintain code clarity and minimize potential issues.
-   **Follow core software development principles:**
    -   TDD (Test-Driven Development): Write tests first, then implement the functionality
    -   DRY (Don't Repeat Yourself): Avoid code duplication, extract reusable components
    -   KISS (Keep It Simple, Stupid): Choose simple solutions over complex ones
    -   SRP (single responsibility principle)
    -   YAGNI (You Aren't Gonna Need It): Don't implement functionality until it's necessary
-   **Always write "clean code".** Clean code requires adherence to specific principles. These principles help developers write code that is clear, concise, and, ultimately, a joy to work with.
-   **Choose names for variables, functions, and classes that reflect their purpose and behavior **(e.g. `discount` would become `discount_price`, `price` would become `product_price`)
-   **Include or use auxiliary verbs in variable names** when appropriate (e.g. `is_active`, `has_permission`)
-   **Use named constants instead of hard-coded values.** Write constants with meaningful names that convey their purpose. (e.g. `discount = price * 0.1 # 10% discount` would become `TEN_PERCENT_DISCOUNT = 0.1 discount = price * TEN_PERCENT_DISCOUNT`)
-   **Encapsulate nested conditionals into functions.** Nested conditionals make code difficult to read and comprehend. You need to simplify the main code flow by encapsulating complex conditionals into well-named functions.
-   **Keep inline-comments minimal, and make them meaningful.** Use comments only when necessary and make sure they add real value - typically only to clarify complex logic or unusual decisions or to explain the why
-   **Handle errors and edge cases at the beginning of functions**
-   **Use early returns and guard clauses **for errors conditions to avoid deeply nested if statements
-   **No extra code beyond what is absolutely necessary** to solve the problem the user provides (i.e. no technical debt)
