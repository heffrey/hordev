#!/usr/bin/env bash
# Self-improvement trigger.
#
# hordev is supposed to get better at its own job, and reflection that depends
# on an agent remembering to reflect does not happen. So the harness asks.
#
# Fires when the main agent finishes responding. Three things matter here and
# earlier versions got all of them wrong:
#
#   1. Stop does not honor hookSpecificOutput.additionalContext -- that is the
#      SessionStart/UserPromptSubmit mechanism. On Stop, stdout at exit 0 goes
#      to the debug log and nowhere else. The documented way to hand the model
#      more work is {"decision":"block","reason":"..."}.
#   2. Blocking on Stop can loop. The harness sets stop_hook_active when it is
#      already continuing from a Stop hook; bail out then, or the session never
#      ends.
#   3. isolating-horde-workspaces puts every run in .claude/worktrees/<name>/,
#      so the run log is almost never in the main checkout. A hook that looks
#      only at <project>/.hordev/ is silent on exactly the runs it exists for.
#      Look in both, and stamp each log beside itself so one worktree's
#      reflection does not suppress another's.
#
# Deliberately depends on nothing but bash.
set -uo pipefail

input=$(cat 2>/dev/null || true)

# Already continuing from a previous Stop hook. Do not block again.
case "$input" in
  *'"stop_hook_active":true'* | *'"stop_hook_active": true'*) exit 0 ;;
esac

PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
# A session isolated in a worktree may report the worktree as its project.
# Reflection covers the whole project either way.
ROOT="${PROJECT%%/.claude/worktrees/*}"

json_escape() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\t'/\\t}
  s=${s//$'\r'/\\r}
  s=${s//$'\n'/\\n}
  printf '%s' "$s"
}

# Every run log this hook sees goes into a user-level index, so Reflect can count
# a failure class across projects instead of within one log. Best effort: a
# read-only home costs the cross-run view, never the session.
INDEX_DIR="${HORDEV_HOME:-${HOME:+$HOME/.claude/hordev}}"
register() {
  [ -n "$INDEX_DIR" ] || return 0
  mkdir -p "$INDEX_DIR" 2>/dev/null || return 0
  grep -qxF "$1" "$INDEX_DIR/runs.md" 2>/dev/null ||
    printf '%s\n' "$1" >> "$INDEX_DIR/runs.md" 2>/dev/null || true
}

grown=""
for log in "$ROOT/.hordev/run-log.md" "$ROOT"/.claude/worktrees/*/.hordev/run-log.md; do
  # An unmatched glob stays literal and fails this test.
  [ -r "$log" ] || continue
  register "$log"

  # Speak only when this log grew since its last reflection, so a session that
  # ends twenty times does not get asked twenty times.
  stamp="$(dirname "$log")/.reflected"
  if [ -e "$stamp" ] && [ ! "$log" -nt "$stamp" ]; then
    continue
  fi
  touch "$stamp" 2>/dev/null || true

  grown="${grown:+$grown, }${log#"$ROOT"/}"
done

[ -n "$grown" ] || exit 0

# The procedure is owned by using-hordev's Reflect stage. This text quotes it
# word for word, and tests/reflect-hook.test.sh fails if the two drift.
reason="hordev: run log grew since the last reflection ($grown). If a run is still in progress, finish it first. Then run the Reflect stage from using-hordev: Dispatch one sonnet agent with the improving-hordev skill text and the run log paths. It writes .hordev/proposed-amendments.md beside the run log and edits no skill; you apply or decline what it proposes."

printf '{"decision":"block","reason":"%s"}\n' "$(json_escape "$reason")"
