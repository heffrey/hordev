#!/usr/bin/env bash
# skills/improving-hordev/entry-keys.sh: one line per entry, CLASS then EVENT text.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

K="$REPO/skills/improving-hordev/entry-keys.sh"
T=$(scratch)

printf '# log\n\nEVENT: first line\n  wraps here\nSKILL: horde-qa\nCOST: one-off\nCLASS: resource\nRULE: a rule\n  that wraps\n---\nEVENT: no class\nSKILL: horde-qa\nCOST: one-off\nRULE:\n---\n' > "$T/log.md"
out=$(bash "$K" "$T/log.md")
assert_status "one line per entry" "$(printf '%s\n' "$out" | grep -c .)" 2
assert_contains "EVENT continuation lines are joined" "$out" "$(printf 'resource\tfirst line wraps here')"
assert_not_contains "RULE continuation lines are not part of the key" "$out" "that wraps"
assert_contains "an entry without CLASS has an empty class" "$out" "$(printf '\tno class')"

count=$(bash "$K" "$REPO/.hordev/run-log.md" | grep -c .)
events=$(grep -c '^EVENT:' "$REPO/.hordev/run-log.md")
assert_status "every entry in the bootstrap log is keyed" "$count" "$events"

printf '# Run log\n\n- WHAT: prose\n' > "$T/prose.md"
assert_empty "a log with no entries prints nothing" "$(bash "$K" "$T/prose.md")"

bash "$K" >/dev/null 2>&1; status=$?
assert_status "no arguments is a usage error" "$status" 2

rm -rf "$T"
finish
