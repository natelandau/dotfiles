---
name: git-commit-message-rules
description: Git commit message rules
---
## Git commit message rules

- Always use angular style conventional commits style. No Exceptions!
- The first line of the commit should never be more than 50 characters
- Each commit message consists of a header, and a body. The header has a special format that includes a type, a scope and a subject: `(<scope>): <subject>`
- The types must be one of the following. No exceptions:
    - build: Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)
    - ci: Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs)
    - docs: Documentation only changes
    - feat: A new feature
    - fix: A bug fix
    - perf: A code change that improves performance
    - refactor: A code change that neither fixes a bug nor adds a feature
    - style: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
    - test: Adding missing tests or correcting existing tests
- The scope should be the name of the package, feature, codebase, or area that is effected
- The subject contains a succinct description of the change:
    - use the imperative, present tense: "change" not "changed" nor "changes" in the subject
    - don't capitalize the first letter of the subject
    - no dot (.) at the end of the subject
- In the body, just as in the summary, use the imperative, present tense: "fix" not "fixed" nor "fixes".
- The body will explain the motivation for the change in the commit message body. This commit message should explain WHY you are making the change. You can include a comparison of the previous behavior with the new behavior in order to illustrate the impact of the change.

### Commit Message Examples

- feat: add email notifications on new direct messages
- feat(shopping cart): add the amazing button
- feat(search): add global search to navbar
- feat!: remove ticket list endpoint
- fix(api): fix wrong calculation of request body checksum
- perf: decrease memory footprint by using HyperLogLog
- build: update dependencies
- refactor: implement fibonacci number calculation as recursion
- style: remove empty line
- docs(readme): update installation instructions
- docs: clarify the service limitation in providers.md guide
- fix(utils): ensure logging handles exceptions from `FastAPI`
