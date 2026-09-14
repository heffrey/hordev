#!/usr/bin/env bash
# skills/improving-hordev/validate-run-log.sh against real and fixture logs.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

V="$REPO/skills/improving-hordev/validate-run-log.sh"
F="$REPO/tests/fixtures/run-logs"

out=$(bash "$V" "$REPO/.hordev/run-log.md"); status=$?
assert_status "the bootstrap log passes" "$status" 0
assert_contains "and all nine entries are counted" "$out" "ok, 9 entries"

out=$(bash "$V" "$F/product-run.md"); status=$?
assert_status "the product-run fixture passes" "$status" 0

out=$(bash "$V" "$F/prose-run.md"); status=$?
assert_status "a prose log fails" "$status" 1
assert_contains "a heading in the preamble is flagged" "$out" "prose-run.md:3: heading in the preamble"
assert_contains "a prose section after a separator is flagged" "$out" "prose-run.md:11: text outside an entry"
assert_contains "a reflection table is flagged" "$out" "prose-run.md:17: text outside an entry"
count=$(printf '%s\n' "$out" | grep -c 'text outside an entry')
assert_status "one problem per prose section, not per line" "$count" 2
assert_not_contains "the one well-formed entry is not flagged" "$out" "prose-run.md:23"

T=$(scratch)
check() {  # check <name> <log body> <expected substring>
  printf '# log\n\n---\n\n%s' "$2" > "$T/$1.md"
  local o
  o=$(bash "$V" "$T/$1.md"); local s=$?
  assert_status "$1: exits 1" "$s" 1
  assert_contains "$1: says why" "$o" "$3"
}

check missing-class 'EVENT: x
SKILL: horde-qa
COST: one-off
RULE:
---
' "expected CLASS, found RULE"

check unknown-class 'EVENT: x
SKILL: horde-qa
COST: one-off
CLASS: vibes
RULE:
---
' "CLASS vibes is not in the vocabulary"

check bad-cost 'EVENT: x
SKILL: horde-qa
COST: systemic
CLASS: other
RULE:
---
' "COST must be one-off or systemic (N times)"

check wrapped-skill 'EVENT: x
SKILL: horde-qa and
also dispatching-hordes
COST: one-off
CLASS: other
RULE:
---
' "SKILL does not wrap"

check truncated 'EVENT: x
SKILL: horde-qa
---
' "entry stops before COST"

check blank-inside 'EVENT: x

SKILL: horde-qa
COST: one-off
CLASS: other
RULE:
---
' "blank line inside an entry"

check two-in-one 'EVENT: x
SKILL: horde-qa
COST: one-off
CLASS: other
RULE:
EVENT: y
---
' "extra EVENT after RULE"

printf 'EVENT: wraps\nacross lines\nSKILL: horde-qa\nCOST: systemic (2 times)\nCLASS: agent-git\nRULE: also\nwraps\n---\n' > "$T/wraps.md"
out=$(bash "$V" "$T/wraps.md"); status=$?
assert_status "EVENT and RULE may wrap" "$status" 0

out=$(bash "$V" 2>&1); status=$?
assert_status "no arguments is a usage error" "$status" 2

rm -rf "$T"
finish
