#!/usr/bin/env bash
# Self-improvement trigger.
#
# hordev is supposed to get better at its own job, and reflection that depends
# on an agent remembering to reflect does not happen. So the harness asks.
#
# Fires when the main agent finishes responding. Deliberately cheap and quiet:
# it speaks only when the run actually recorded horde work, and it never blocks
# or fails a session. If there is nothing to learn, it says nothing.
set -uo pipefail

PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
LEDGER="$PROJECT/.hordev/run-log.md"
STAMP="$PROJECT/.hordev/.reflected"

[ -r "$LEDGER" ] || exit 0

# Nudge only when the run log grew since the last reflection, so a session that
# ends in ten turns does not get asked ten times.
if [ -e "$STAMP" ] && [ ! "$LEDGER" -nt "$STAMP" ]; then
  exit 0
fi
touch "$STAMP" 2>/dev/null || true

python3 -c '
import json

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "Stop",
        "additionalContext": (
            "hordev: this run appended to .hordev/run-log.md since the last "
            "reflection. Invoke the improving-hordev skill and decide whether "
            "anything here should change a skill. Amend on a repeated failure, "
            "not a one-off."
        ),
    }
}))
'
