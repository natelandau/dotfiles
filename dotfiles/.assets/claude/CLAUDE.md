# General guidelines

- Default: do all work in a new git worktree, not by switching branches in the main checkout.
- When unfamiliar with a tool/platform, research docs before reasoning from general knowledge.
- Never clear a pytest, lint, or build cache as routine. Clear one only when a stale cache is the
  confirmed or strongly suspected cause of a wrong result: clear once, re-run, stop. Applies to
  dispatched subagents too.
- macOS: `sed` is GNU sed.
- To troubleshoot Cloudflare (Workers, Builds, KV, R2, DNS, zone settings), call the
  API at https://api.cloudflare.com/client/v4 with `$CF_AGENT_TROUBLESHOOTING_TOKEN`.
  It is read-only and covers every account and zone. Reference the variable; never
  print, echo, or paste its value, and never send it to any host other than
  api.cloudflare.com. Never set it as `CLOUDFLARE_API_TOKEN`, which wrangler would
  use. When a fix needs a write, describe the change and ask me for a short-lived token.

## Conventions and Best Practices

- A user-facing string that more than one file needs, tests included, is
  an exported constant beside the component that shows it. Every other
  file imports it, so a wording change is one edit.
- Name every identifier (function, variable, class, etc.) with the most precise name that still
  reads easily. No colloquialisms, coined terms, or terms a developer new to the project would
  not understand on sight.
- Pass structured data with a fixed shape that crosses function boundaries as a typed object.
  Leave free-form data and single-use values unwrapped.
- No catch-all types (`Any`, `any`, `interface{}`), except for truly dynamic keyword or option
  values, untyped data from external libraries, or a type that cannot be known statically.
- Never silently swallow errors. Catch specific error types. Put the failing value and the
  expected condition in every error message.
- After every file edit, run the project's linter and formatter on that file. Before every
  commit, run its linters, type checker, and full test suite (through its task runner if it has
  one) and fix every error.

## Finishing feature development

Before presenting finished feature work, run each once, in order. Skip for small changes and
changes only to docs or tooling.

1. /simplify
2. /code-review --fix
3. /security-review. If it recommends no changes, continue without waiting for the user.

Final recap: list the three skills and each one's result.

## Documentation

Vault: the private notes store managed by the `sessionmemory` CLI.

- Write and edit every doc a human reads, in the repository or the vault, with the
  `natelandau-toolkit:technical-writer` skill. If the skill and this file disagree, this file wins.
- Write and edit every text an agent reads (skills, subagents, slash commands,
  CLAUDE.md and rules files, prompts for subagents) with the
  `natelandau-toolkit:prompt-writer` skill instead of `technical-writer`.
- The vault is private and privileged. Never name it, `sessionmemory`, or a
  path inside it in anything committed or public: docs, code comments,
  commit messages, pull requests. Public text that needs to point at
  private material says only that it lives outside the repository.
- No em-dashes. Use a comma, period, or hyphen, or rewrite the sentence.
- Plans -> vault `plans/`; specs and design docs -> vault `specs/` (`sessionmemory new spec`),
  including ones a plugin such as superpowers generates. Never under `docs/`, which is reserved
  for public-facing documentation.
- Write every runbook (a step-by-step procedure to follow by hand) with `sessionmemory new runbook`,
  which puts it in the project's vault `runbooks/` folder. Never in `plans/`.
- Private documentation about a project (hosting and dashboard settings, where each credential
  lives, account details, anything that should not be public) lives in the project's vault
  `reference/` folder, never `docs/`. Create a reference doc with `sessionmemory new reference`,
  edit it in place afterward, and before working on hosting, deploys, or credentials, read whatever
  `reference/` holds.
- Use terms any developer knows. No colloquialisms, terms coined in a spec or session, or code
  names (module, function, internal concept), unless documenting that code.
- Docs describe current behavior for the user's task. No change history (the changelog covers it),
  edge-case lists, or algorithm internals.

## Code Reviews

- When reviewing code or running a code-review plugin, the diff is the seed of the search, not the
  scope of the remedy. We own all the code, so a real finding is in scope regardless of which commit
  introduced it. After verifying findings (drop the refuted ones), assign every surviving finding
  exactly one disposition. FIX is the default and needs no justification:
    - `FIX`: apply it now. Burden of proof is on not fixing.
    - `SKIP: false positive`: the finding is wrong; say why.
    - `SKIP: changes intended behavior`: the fix would undo a decision I approved or alter intended
      behavior; say what.
    - `SKIP: needs sign-off`: the fix is irreversible or breaks a public contract, so it needs my
      explicit go-ahead. Add these to the backlog.
- These are the only valid skips. "Pre-existing," "not introduced by this diff," "out of scope,"
  "spans other files," "to keep this change focused," and "worth a follow-up" are not valid skips.
  If your reason is one of those or a paraphrase, the disposition is FIX.
- Size is not scope. A large but correct fix gets done, in a separate commit if it would muddy the
  current one. Multiple commits are fine. Never substitute "noted for follow-up" for doing a fix
  you could do now, and never park a fixable item on the backlog to avoid the work.

## Testing Guidelines

A test earns its place when it catches a bug that no other test catches, at the cheapest
layer that can see that bug.

| The bug is in                                                       | Test it with                                     |
| ------------------------------------------------------------------- | ------------------------------------------------ |
| Logic: parsing, sorting, filtering, formatting, a rule over data    | A unit test of the function                      |
| Wiring: logic reaching a screen or route, real input, focus, layout | One integration, browser, or UI test per feature |
| A flow across the API boundary                                      | An end-to-end test                               |

- One rule, one test. Before adding a test, search for one of the same rule and add a case to it.
- Variants of one rule are one table: `it.each`, `@pytest.mark.parametrize`, `@Test(arguments:)`.
- Never a test of a UI or UX choice: a font, color, radius, size, weight, spacing, duration, class
  name, label, or where a haptic plays. The UI must change with no test failing. Screenshots and
  review check how things look.
- Never a test that restates code: a constant's value, a copy string, a call order that a
  mock records when the order is not the behavior, or what the type checker already rejects.
- A refactor that changes no behavior changes no test. A test that fails
  on a refactor checks the implementation: rewrite it against the public
  surface.
- A test asserts behavior and contracts:
    - What a person sees and can do.
    - What is stored or sent.
    - Accessibility: touch targets, focus, contrast, reduced motion, text
      size.
    - Design-token use and shared-component rules defined in the project.
- A change that removes a behavior removes its tests.
- A cleanup deletes a test only when another test checks the same rule, or when the test checks
  a design value. The evidence: mutation testing or per-test coverage.
- Never raise a timeout or add a retry to make a test pass.
- Every test must pass alone and in any order.
