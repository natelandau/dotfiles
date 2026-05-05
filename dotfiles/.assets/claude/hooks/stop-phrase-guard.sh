#!/bin/bash
# Stop hook: catches ownership-dodging and session-quitting phrases that
# violate CLAUDE.md golden rules. When triggered, blocks the assistant from
# stopping and forces it to go back and do the work properly.
#
# The assistant's message has already been shown to the user by the time this
# runs, but the assistant is forced to continue — so the correction appears
# immediately after the violation, which is visible and self-documenting.

set -euo pipefail

INPUT=$(cat)

# Prevent infinite loops: if the hook already fired once this turn, let
# the assistant stop. The correction message from the first firing is
# enough — we don't want to trap the assistant in an endless cycle.
HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [[ "$HOOK_ACTIVE" == "true" ]]; then
  exit 0
fi

MESSAGE=$(echo "$INPUT" | jq -r '.last_assistant_message // empty')
if [[ -z "$MESSAGE" ]]; then
  exit 0
fi

# Each violation: "grep_pattern|correction_rule"
# Patterns are checked case-insensitively against the full assistant message.
# Ordered by severity — first match wins.
VIOLATIONS=(
  # Ownership dodging (the #1 problem: dismissing failures as not-my-fault)
  "pre-existing|NOTHING IS PRE-EXISTING (CLAUDE.md golden rule). All builds and tests are green upstream. If something fails, YOUR work caused it. Investigate and fix it. Never dismiss a failure as pre-existing."
  "not from my changes|NOTHING IS PRE-EXISTING. You own every change. Investigate the failure."
  "not my change|NOTHING IS PRE-EXISTING. You own every change. Investigate the failure."
  "not caused by my|NOTHING IS PRE-EXISTING. You own every change. Investigate the failure."
  "not introduced by my|NOTHING IS PRE-EXISTING. You own every change. Investigate the failure."
  "already existed before|NOTHING IS PRE-EXISTING. If you found it broken, fix it or explain exactly what is wrong and what the fix requires."
  "before my changes|NOTHING IS PRE-EXISTING. There is no 'before your changes' — you own the codebase as it is now."
  "prior to my changes|NOTHING IS PRE-EXISTING. There is no 'prior to your changes.'"
  "unrelated to my changes|NOTHING IS PRE-EXISTING. If it is broken, fix it. If you broke it, fix it. Nothing is unrelated."
  "an existing issue|NOTHING IS PRE-EXISTING. Investigate and fix, or explain exactly what is wrong."
  "existing bug|NOTHING IS PRE-EXISTING. Investigate and fix."

  # Known limitation dodging
  "known limitation|NO KNOWN LIMITATIONS (CLAUDE.md golden rule). Investigate whether it is fixable. Either fix it or explain the specific technical reason it cannot be fixed right now."
  "known issue|NO KNOWN LIMITATIONS. Explain the specific technical reason or fix it."
  "future work|NO KNOWN LIMITATIONS. Fix it now or describe exactly what the fix requires — not as a TODO, as a technical explanation."
  "left as an exercise|NO KNOWN LIMITATIONS. Do the work."

  # Session-length quitting
  "session length|Sessions are unlimited (CLAUDE.md rule). If work remains, do the work. Continue."
  "session depth|Sessions are unlimited. Continue working."
  "given the length of this|Sessions are unlimited. Continue working."
  "continue in a new session|Sessions are unlimited. There is no reason to defer to a new session. Continue."
  "good place to stop|Is the task done? If not, continue working. Sessions are unlimited."
  "good stopping point|Is the task done? If not, continue working. Sessions are unlimited."
  "good checkpoint given|Is the task done? If not, continue working."
  "natural stopping|Is the task done? If not, continue working."
  "logical stopping|Is the task done? If not, continue working."
  "this session has gotten long|Sessions are unlimited. You are a machine. Continue working."
  "session has been long|Sessions are unlimited. Continue working."
  "getting long|Sessions are unlimited. Continue working."
  "lengthy session|Sessions are unlimited. Continue working."

  # Permission-seeking mid-task (the answer is always "yes, continue")
  # These fire when Claude stops to ask whether it should keep working on
  # something it was already asked to do. If the only possible answer from the
  # user is "yes, obviously, you haven't finished yet" — don't ask.
  "want to continue.*or |Do not ask. The task is not done. Continue working."
  "or save it for|Do not ask. The task is not done. Continue working."
  "should I continue|Do not ask. If the task is not done, continue. The user will interrupt if they want you to stop."
  "shall I continue|Do not ask. Continue working until the task is complete."
  "shall I proceed|Do not ask. Proceed."
  "would you like me to continue|Do not ask. Continue."
  "would you like to continue|Do not ask. Continue."
  "want me to keep going|Do not ask. Keep going."
  "want me to continue|Do not ask. Continue."
  "should I keep going|Do not ask. Keep going."
  "save it for next time|There is no 'next time.' Sessions are unlimited. Continue working."
  "in the next session|There is no 'next session.' This session is unlimited. Continue working."
  "next session|There is no 'next session.' This session is unlimited. Continue working."
  "next conversation|There is no 'next conversation.' Continue working."
  "pick this up later|There is no 'later.' Continue working now."
  "come back to this|There is no 'coming back.' Continue working now."
  "continue in a follow-up|There is no 'follow-up.' Continue now."
  "pause here|Do not pause. The task is not done. Continue."
  "stop here for now|Do not stop. The task is not done. Continue."
  "wrap up for now|Do not wrap up. The task is not done. Continue."
  "call it here|Do not stop. Continue working."
)

for entry in "${VIOLATIONS[@]}"; do
  pattern="${entry%%|*}"
  correction="${entry#*|}"
  if echo "$MESSAGE" | grep -iq "$pattern"; then
    # Output JSON decision to stdout — Claude Code reads this and forces
    # the assistant to continue with the reason as its next instruction.
    jq -n --arg reason "STOP HOOK VIOLATION: $correction" '{
      decision: "block",
      reason: $reason
    }'
    exit 0
  fi
done

# No violations found — allow the assistant to stop normally.
exit 0
