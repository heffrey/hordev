#!/usr/bin/env bash
# hooks/reflect.sh against fixture projects.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

HOOK="${HOOK:-$REPO/hooks/reflect.sh}"
OLD=202001010000   # a timestamp every freshly written file is newer than

run_hook() {  # run_hook <project-dir> [stdin]
  printf '%s' "${2:-{\}}" | CLAUDE_PROJECT_DIR="$1" bash "$HOOK"
}

entry() {
  printf 'EVENT: fixture event\nSKILL: horde-qa\nCOST: one-off\nCLASS: other\nRULE:\n---\n'
}

# A run isolated in a worktree: no .hordev in the main checkout at all.
P=$(scratch)
mkdir -p "$P/.claude/worktrees/run-a/.hordev"
entry > "$P/.claude/worktrees/run-a/.hordev/run-log.md"

out=$(run_hook "$P")
assert_contains "worktree run log triggers reflection" "$out" '"decision":"block"'
assert_contains "reason names the worktree log" "$out" '.claude/worktrees/run-a/.hordev/run-log.md'
assert_json "payload is valid JSON" "$out"
[ -e "$P/.claude/worktrees/run-a/.hordev/.reflected" ] \
  && pass "stamp written beside the worktree log" \
  || fail "stamp written beside the worktree log"
[ ! -e "$P/.hordev/.reflected" ] \
  && pass "no stamp invented in the main checkout" \
  || fail "no stamp invented in the main checkout"

out=$(run_hook "$P")
assert_empty "unchanged log stays silent on the next Stop" "$out"

# The log grows again.
touch -t "$OLD" "$P/.claude/worktrees/run-a/.hordev/.reflected"
out=$(run_hook "$P" '{"session_id":"x","stop_hook_active":true}')
assert_empty "stop_hook_active:true stays silent" "$out"
out=$(run_hook "$P" '{"stop_hook_active": true}')
assert_empty "stop_hook_active: true (spaced) stays silent" "$out"
out=$(run_hook "$P")
assert_contains "grown log triggers again once the loop guard is clear" "$out" '"decision":"block"'

# Two worktrees: one already reflected, one grown. Stamps are per log.
mkdir -p "$P/.claude/worktrees/run-b/.hordev"
entry > "$P/.claude/worktrees/run-b/.hordev/run-log.md"
out=$(run_hook "$P")
assert_contains "second worktree's log triggers" "$out" 'run-b/.hordev/run-log.md'
assert_not_contains "reflected worktree is not re-announced" "$out" 'run-a/'

# Main checkout and a worktree both grown: both named.
Q=$(scratch)
mkdir -p "$Q/.hordev" "$Q/.claude/worktrees/w/.hordev"
entry > "$Q/.hordev/run-log.md"
entry > "$Q/.claude/worktrees/w/.hordev/run-log.md"
out=$(run_hook "$Q")
assert_contains "main checkout log named" "$out" '(.hordev/run-log.md'
assert_contains "worktree log named alongside it" "$out" '.claude/worktrees/w/.hordev/run-log.md'

# Session isolated in a worktree reports the worktree as its project.
R=$(scratch)
mkdir -p "$R/.claude/worktrees/iso/.hordev" "$R/.claude/worktrees/other/.hordev"
entry > "$R/.claude/worktrees/other/.hordev/run-log.md"
out=$(run_hook "$R/.claude/worktrees/iso")
assert_contains "project dir inside a worktree still scans the whole project" "$out" 'worktrees/other/'

# Nothing to reflect on.
E=$(scratch)
out=$(run_hook "$E"); status=$?
assert_empty "project with no run log stays silent" "$out"
assert_status "and exits 0" "$status" 0

rm -rf "$P" "$Q" "$R" "$E"
finish
