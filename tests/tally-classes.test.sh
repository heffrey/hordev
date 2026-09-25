#!/usr/bin/env bash
# skills/improving-hordev/tally-classes.sh over two runs' logs.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

TALLY="$REPO/skills/improving-hordev/tally-classes.sh"
BOOT="$REPO/.hordev/run-log.md"
PRODUCT="$REPO/tests/fixtures/run-logs/product-run.md"

row() { printf '%s\n' "$1" | grep -E "^$2 "; }

out=$(bash "$TALLY" "$BOOT" "$PRODUCT"); status=$?
assert_status "tally exits 0" "$status" 0

# The three classes the two runs share. Each log alone sees them once or twice.
assert_contains "agent-git recurs across both runs" "$(row "$out" agent-git)" "(across 2 runs)"
assert_contains "format-drift recurs across both runs" "$(row "$out" format-drift)" "(across 2 runs)"
assert_contains "budget-overrun recurs across both runs" "$(row "$out" budget-overrun)" "(across 2 runs)"
assert_contains "budget-overrun clears the rule bar only once both runs count" "$(row "$out" budget-overrun)" "systemic: add a rule"

alone=$(bash "$TALLY" "$BOOT")
assert_contains "within the bootstrap log alone, agent-git is a one-off" "$(row "$alone" agent-git)" "one-off"
assert_not_contains "and is not reported across runs" "$(row "$alone" agent-git)" "across"

assert_contains "a class seen in one run only is not called cross-run" "$(row "$out" write-collision)" "recurring: rewrite"
assert_not_contains "write-collision stays within one run" "$(row "$out" write-collision)" "across"
assert_contains "other is not treated as a class" "$(row "$out" other)" "not a class"

# Driven by the user-level index, the way Reflect runs it.
H=$(scratch)
printf '# run logs\n%s\n%s\n%s\n' "$BOOT" "$PRODUCT" "$H/gone/.hordev/run-log.md" > "$H/runs.md"
out=$(HORDEV_HOME="$H" bash "$TALLY")
assert_contains "index-driven tally sees both runs" "$(row "$out" agent-git)" "(across 2 runs)"
assert_contains "a vanished log in the index is reported, not skipped" "$out" "missing        $H/gone/.hordev/run-log.md"

# Legacy and unknown entries are surfaced.
printf 'EVENT: old entry\nSKILL: horde-qa\nCOST: one-off\nRULE:\n---\nEVENT: new\nSKILL: horde-qa\nCOST: one-off\nCLASS: vibes\nRULE:\n---\n' > "$H/legacy.md"
out=$(bash "$TALLY" "$H/legacy.md")
assert_contains "entries without CLASS are counted as unclassified" "$out" "1 of 2 entries have no CLASS"
assert_contains "a class outside the vocabulary is flagged" "$(row "$out" vibes)" "unknown class"

# Worktree copies of one log are one run. Counting each copy once turned a
# single failure into a recurrence.
mkdir -p "$H/a" "$H/b"
printf 'EVENT: one failure\nSKILL: horde-qa\nCOST: one-off\nCLASS: resource\nRULE:\n---\n' > "$H/a/run-log.md"
cp "$H/a/run-log.md" "$H/b/run-log.md"
out=$(bash "$TALLY" "$H/a/run-log.md" "$H/b/run-log.md")
assert_contains "an entry in two copies counts once" "$(row "$out" resource)" "one-off"
assert_not_contains "and not across runs" "$(row "$out" resource)" "across"
printf 'EVENT: another failure\nSKILL: horde-qa\nCOST: one-off\nCLASS: resource\nRULE:\n---\n' >> "$H/b/run-log.md"
out=$(bash "$TALLY" "$H/a/run-log.md" "$H/b/run-log.md")
assert_contains "a new entry in a copy still counts" "$(row "$out" resource)" "systemic: add a rule"

out=$(HORDEV_HOME="$H/none" bash "$TALLY" 2>&1); status=$?
assert_status "no index and no arguments is an error" "$status" 2

rm -rf "$H"
finish
