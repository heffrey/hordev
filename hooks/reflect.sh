#!/usr/bin/env bash
# Self-improvement trigger.
#
# hordev is supposed to get better at its own job, and reflection that depends
# on an agent remembering to reflect does not happen. So the harness asks.
#
# Fires when the main agent finishes responding. Two things matter here and an
# earlier version got both wrong:
#
#   1. Stop does not honor hookSpecificOutput.additionalContext -- that is the
#      SessionStart/UserPromptSubmit mechanism. On Stop, stdout at exit 0 goes
#      to the debug log and nowhere else. The documented way to hand the model
#      more work is {"decision":"block","reason":"..."}.
#   2. Blocking on Stop can loop. The harness sets stop_hook_active when it is
#      already continuing from a Stop hook; bail out then, or the session never
#      ends.
#
# Deliberately depends on nothing but bash.
set -uo pipefail

input=$(cat 2>/dev/null || true)

# Already continuing from a previous Stop hook. Do not block again.
case "$input" in
  *'"stop_hook_active":true'* | *'"stop_hook_active": true'*) exit 0 ;;
esac

PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
LEDGER="$PROJECT/.hordev/run-log.md"
STAMP="$PROJECT/.hordev/.reflected"

[ -r "$LEDGER" ] || exit 0

# Speak only when the run log grew since the last reflection, so a session that
# ends twenty times does not get asked twenty times.
if [ -e "$STAMP" ] && [ ! "$LEDGER" -nt "$STAMP" ]; then
  exit 0
fi
touch "$STAMP" 2>/dev/null || true

printf '{"decision":"block","reason":"hordev: .hordev/run-log.md grew since the last reflection. Invoke the improving-hordev skill and decide whether anything in this run should change a skill. Amend on a repeated failure, not a one-off. If nothing clears that bar, say so in one line and stop."}\n'
