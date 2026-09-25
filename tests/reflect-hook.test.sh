#!/usr/bin/env bash
# hooks/reflect.sh against fixture projects.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

HOOK="${HOOK:-$REPO/hooks/reflect.sh}"
OLD=202001010000   # a timestamp every freshly written file is newer than

INDEX_HOME=$(scratch)   # never touch the real ~/.claude/hordev from a test

run_hook() {  # run_hook <project-dir> [stdin]
  printf '%s' "${2:-{\}}" | CLAUDE_PROJECT_DIR="$1" HORDEV_HOME="$INDEX_HOME" bash "$HOOK"
}

N=0
entry() {  # every call writes a distinct entry; EVENT text is an entry's identity
  N=$((N + 1))
  printf 'EVENT: fixture event %s\nSKILL: horde-qa\nCOST: one-off\nCLASS: other\nRULE:\n---\n' "$N"
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
entry >> "$P/.claude/worktrees/run-a/.hordev/run-log.md"
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

# One owner for reflection: the hook quotes using-hordev's Reflect stage word
# for word. If either side is edited alone, this fails.
SENTENCE='Dispatch one sonnet agent with the improving-hordev skill text and the run log paths. It appends to ~/.claude/hordev/proposed-amendments.md under a heading naming the project, and edits no skill; you apply or decline what it proposes.'
stage=$(tr '\n' ' ' < "$REPO/skills/using-hordev/SKILL.md" | tr -s ' ')
assert_contains "using-hordev states the Reflect procedure" "$stage" "$SENTENCE"
entry >> "$Q/.hordev/run-log.md"   # $Q was reflected above; grow it again
out=$(run_hook "$Q")
assert_contains "hook reason quotes that procedure exactly" "$out" "$SENTENCE"
count=$(grep -rlF 'Dispatch one sonnet agent with the improving-hordev skill text' "$REPO/skills" | wc -l | tr -d ' ')
assert_status "procedure appears in exactly one skill" "$count" 1

# A grown log that fails the validator is named for rewriting; a clean one is not.
M=$(scratch)
mkdir -p "$M/.hordev" "$M/.claude/worktrees/ok/.hordev"
printf '# Run log\n\n- WHAT: prose, not an entry\n' > "$M/.hordev/run-log.md"
entry > "$M/.claude/worktrees/ok/.hordev/run-log.md"
out=$(run_hook "$M")
assert_contains "malformed log is flagged for rewriting" "$out" 'Malformed run log (.hordev/run-log.md)'
assert_not_contains "well-formed log is not flagged" "$out" 'Malformed run log (.claude/worktrees/ok'
assert_contains "procedure is still quoted alongside the flag" "$out" "$SENTENCE"
assert_json "flagged payload is valid JSON" "$out"
entry >> "$Q/.hordev/run-log.md"
out=$(run_hook "$Q")
assert_not_contains "well-formed logs get no rewrite request" "$out" 'Malformed'

# Growth is new entries, not a newer file. Each of these once asked for
# reflection on entries already reflected on.
C=$(scratch)
mkdir -p "$C/.hordev"
entry > "$C/.hordev/run-log.md"
out=$(run_hook "$C")
assert_contains "a new log is asked about" "$out" '"decision":"block"'
touch -t "$OLD" "$C/.hordev/.reflected"; touch "$C/.hordev/run-log.md"
out=$(run_hook "$C")
assert_empty "a rewritten file with the same entries stays silent (checkout, merge)" "$out"
mkdir -p "$C/.claude/worktrees/copy/.hordev"
cp "$C/.hordev/run-log.md" "$C/.claude/worktrees/copy/.hordev/run-log.md"
out=$(run_hook "$C")
assert_empty "a worktree's copy of a reflected log stays silent" "$out"
sed 's/^CLASS: other$/CLASS: resource/' "$C/.hordev/run-log.md" > "$C/tmp" && mv "$C/tmp" "$C/.hordev/run-log.md"
out=$(run_hook "$C")
assert_empty "back-filling CLASS on a known entry stays silent" "$out"
entry >> "$C/.claude/worktrees/copy/.hordev/run-log.md"
out=$(run_hook "$C")
assert_contains "a new entry in the copy is asked about" "$out" 'worktrees/copy/.hordev/run-log.md'
assert_not_contains "and the unchanged original is not" "$out" '(.hordev/run-log.md'

# A log with no parseable entry is keyed on its whole content: noticed when it
# changes, silent when it does not.
printf '# Run log\n\n- WHAT: prose\n' > "$C/.hordev/run-log.md"
out=$(run_hook "$C")
assert_contains "an unparseable log that changed is asked about" "$out" 'Malformed run log (.hordev/run-log.md)'
touch -t "$OLD" "$C/.hordev/.reflected"; touch "$C/.hordev/run-log.md"
out=$(run_hook "$C")
assert_empty "and an unchanged one is not" "$out"

# Upgrading from 0.8.0: the seen list does not exist yet. Logs whose old stamp
# says they were reflected are seeded silently; a log newer than its stamp is not.
U=$(scratch); UH=$(scratch)
mkdir -p "$U/.hordev" "$U/.claude/worktrees/new/.hordev"
entry > "$U/.hordev/run-log.md"
touch -t 201901010000 "$U/.hordev/run-log.md"
touch -t "$OLD" "$U/.hordev/.reflected"
entry > "$U/.claude/worktrees/new/.hordev/run-log.md"
touch -t "$OLD" "$U/.claude/worktrees/new/.hordev/.reflected"
out=$(printf '{}' | CLAUDE_PROJECT_DIR="$U" HORDEV_HOME="$UH" bash "$HOOK")
assert_not_contains "upgrade: a log reflected under 0.8.0 is not re-asked" "$out" '(.hordev/run-log.md'
assert_contains "upgrade: a log grown since its stamp is asked about" "$out" 'worktrees/new/.hordev/run-log.md'

# No writable seen list: the modification-time stamps still work.
F=$(scratch)
mkdir -p "$F/.hordev"
entry > "$F/.hordev/run-log.md"
out=$(printf '{}' | CLAUDE_PROJECT_DIR="$F" HORDEV_HOME="/dev/null/nope" bash "$HOOK")
assert_contains "fallback: a new log is asked about" "$out" '"decision":"block"'
out=$(printf '{}' | CLAUDE_PROJECT_DIR="$F" HORDEV_HOME="/dev/null/nope" bash "$HOOK")
assert_empty "fallback: an unchanged log stays silent" "$out"

# Nothing to reflect on.
E=$(scratch)
out=$(run_hook "$E"); status=$?
assert_empty "project with no run log stays silent" "$out"
assert_status "and exits 0" "$status" 0

# Cross-run index: every log the hook has seen, once each, even when silent.
index=$(cat "$INDEX_HOME/runs.md" 2>/dev/null)
assert_contains "index lists a worktree log" "$index" "$P/.claude/worktrees/run-a/.hordev/run-log.md"
assert_contains "index lists a main-checkout log" "$index" "$Q/.hordev/run-log.md"
dupes=$(printf '%s\n' "$index" | sort | uniq -d)
assert_empty "index has no duplicate paths after repeated Stops" "$dupes"

# An unwritable index home costs the index, never the session.
out=$(printf '{}' | CLAUDE_PROJECT_DIR="$Q" HORDEV_HOME="/dev/null/nope" bash "$HOOK"); status=$?
assert_status "unwritable index home still exits 0" "$status" 0

rm -rf "$P" "$Q" "$R" "$E" "$M" "$C" "$U" "$UH" "$F" "$INDEX_HOME"
finish
