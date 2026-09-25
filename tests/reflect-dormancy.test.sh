#!/usr/bin/env bash
# hooks/reflect.sh: reflection goes dormant once converged, and wakes on a recurrence.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

HOOK="${HOOK:-$REPO/hooks/reflect.sh}"
OLD=202001010000
OLDER=201901010000

N=0
entry() {  # entry <class>; every call writes a distinct entry
  N=$((N + 1))
  printf 'EVENT: fixture %s\nSKILL: horde-qa\nCOST: one-off\nCLASS: %s\nRULE:\n---\n' "$N" "$1"
}

# build <scratch> <n-projects> <n-logs> [unclassified]
# Writes n-logs run logs spread across n-projects, one entry each, cycling
# through nine classes so no class reaches three. Indexes every log.
build() {
  local s=$1 np=$2 nl=$3 i p log
  local classes=(agent-git format-drift budget-overrun green-but-broken write-collision dispatch-gap spec-misread duplicate-rule resource)
  mkdir -p "$s/home"
  : > "$s/home/runs.md"
  for ((i = 0; i < nl; i++)); do
    p=$((i % np))
    log="$s/proj$p/.claude/worktrees/run$i/.hordev/run-log.md"
    mkdir -p "$(dirname "$log")"
    entry "${classes[$((i % 9))]}" > "$log"
    # Already reflected: log older than its stamp, both in the past, so any
    # append made during the test is newer regardless of clock granularity.
    touch -t "$OLDER" "$log"
    touch -t "$OLD" "$(dirname "$log")/.reflected"
    printf '%s\n' "$log" >> "$s/home/runs.md"
  done
  if [ "${4:-}" = unclassified ]; then
    printf 'EVENT: legacy\nSKILL: horde-qa\nCOST: one-off\nRULE:\n---\n' > "$s/proj0/.claude/worktrees/run0/.hordev/run-log.md"
    touch -t "$OLDER" "$s/proj0/.claude/worktrees/run0/.hordev/run-log.md"
  fi
}

hook() {  # hook <scratch> [extra env assignments...]
  local s=$1; shift
  printf '{}' | env CLAUDE_PROJECT_DIR="$s/proj0" HORDEV_HOME="$s/home" "$@" bash "$HOOK"
}

# Ten logs, three projects, nothing recurring: converged.
S=$(scratch)
build "$S" 3 10
out=$(hook "$S")
assert_contains "converged: says so once, without blocking" "$out" '"systemMessage":"hordev: self-improvement has converged'
assert_not_contains "and does not block" "$out" '"decision"'
assert_json "message is valid JSON" "$out"
[ -e "$S/home/dormant" ] && pass "dormant marker written" || fail "dormant marker written"

out=$(hook "$S")
assert_empty "dormant: next Stop is silent" "$out"

# A log grows while dormant, with a class that does not recur.
entry other >> "$S/proj0/.claude/worktrees/run0/.hordev/run-log.md"
out=$(hook "$S")
assert_empty "dormant: a grown log with no recurrence stays silent" "$out"

out=$(hook "$S" HORDEV_REFLECT=on)
assert_contains "HORDEV_REFLECT=on reflects even while dormant" "$out" '"decision":"block"'
touch -t "$OLDER" "$S/proj0/.claude/worktrees/run0/.hordev/run-log.md"   # as if reflected
touch -t "$OLD" "$S/proj0/.claude/worktrees/run0/.hordev/.reflected"

# A worktree removed from under the window is not a reason to wake.
rm -rf "$S/proj2/.claude/worktrees/run8"
out=$(hook "$S")
assert_empty "dormant: fewer logs after a teardown does not wake it" "$out"

# Tripwire: agent-git (already twice in the window) happens a third time.
entry agent-git >> "$S/proj0/.claude/worktrees/run3/.hordev/run-log.md"
out=$(hook "$S")
assert_contains "a recurring class wakes reflection" "$out" '"decision":"block"'
assert_contains "and names the class" "$out" 'agent-git reached the recurring bar'
assert_contains "and the log that grew" "$out" 'run3/.hordev/run-log.md grew'
assert_contains "and still quotes the Reflect procedure" "$out" 'Dispatch one sonnet agent with the improving-hordev skill text'
[ ! -e "$S/home/dormant" ] && pass "dormant marker removed on waking" || fail "dormant marker removed on waking"

out=$(hook "$S")
assert_empty "awake with a recurrence but nothing newly grown: silent" "$out"
[ ! -e "$S/home/dormant" ] && pass "and it does not re-enter dormancy while the class recurs" \
  || fail "and it does not re-enter dormancy while the class recurs"

# Not converged: too few projects, too few logs, or a log that cannot be tallied.
for case in "2 10" "3 9" "3 10 unclassified"; do
  T=$(scratch)
  # shellcheck disable=SC2086
  build "$T" $case
  entry other >> "$T/proj0/.claude/worktrees/run0/.hordev/run-log.md"
  out=$(hook "$T")
  assert_contains "not converged ($case): a grown log still triggers reflection" "$out" '"decision":"block"'
  [ ! -e "$T/home/dormant" ] && pass "not converged ($case): no marker" || fail "not converged ($case): no marker"
  rm -rf "$T"
done

# Copies are not runs: nine distinct logs plus a worktree copy of one of them
# is nine runs, short of convergence.
T=$(scratch)
build "$T" 3 9
mkdir -p "$T/proj1/.claude/worktrees/copy/.hordev"
cp "$T/proj1/.claude/worktrees/run1/.hordev/run-log.md" "$T/proj1/.claude/worktrees/copy/.hordev/run-log.md"
printf '%s\n' "$T/proj1/.claude/worktrees/copy/.hordev/run-log.md" >> "$T/home/runs.md"
out=$(hook "$T")
assert_not_contains "a copy does not count toward convergence" "$out" 'converged'
[ ! -e "$T/home/dormant" ] && pass "and no dormant marker" || fail "and no dormant marker"
rm -rf "$T"

# HORDEV_REFLECT=off never blocks, and still indexes.
T=$(scratch)
build "$T" 1 2
entry other >> "$T/proj0/.claude/worktrees/run0/.hordev/run-log.md"
mkdir -p "$T/proj0/.hordev" && entry other > "$T/proj0/.hordev/run-log.md"
out=$(hook "$T" HORDEV_REFLECT=off)
assert_empty "HORDEV_REFLECT=off never blocks" "$out"
assert_contains "and the log is still indexed" "$(cat "$T/home/runs.md")" "$T/proj0/.hordev/run-log.md"
rm -rf "$T"

rm -rf "$S"
finish
