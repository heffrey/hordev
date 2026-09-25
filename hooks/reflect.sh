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
# Deliberately depends on nothing but bash and the POSIX tools every system has
# (grep, sed, awk, sort). Never python, node, or jq: an earlier hook shelled out
# to python3 and failed on every session where it was missing.
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

logs=""
for log in "$ROOT/.hordev/run-log.md" "$ROOT"/.claude/worktrees/*/.hordev/run-log.md; do
  # An unmatched glob stays literal and fails this test.
  [ -r "$log" ] || continue
  register "$log"
  logs="$logs$log"$'\n'
done

# Self-improvement is meant to stop once hordev is good enough. improving-hordev
# defines "good enough" (When reflection goes dormant); this implements it.
#
#   HORDEV_REFLECT=auto   default: dormant once converged, awake on a recurrence
#   HORDEV_REFLECT=on     always reflect when a log grows
#   HORDEV_REFLECT=off    never block; logs are still indexed
MODE="${HORDEV_REFLECT:-auto}"
RUNS="${HORDEV_CONVERGE_RUNS:-10}"
PROJECTS="${HORDEV_CONVERGE_PROJECTS:-3}"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TALLY="$PLUGIN_ROOT/skills/improving-hordev/tally-classes.sh"
VALIDATE="$PLUGIN_ROOT/skills/improving-hordev/validate-run-log.sh"
KEYS="$PLUGIN_ROOT/skills/improving-hordev/entry-keys.sh"
MARKER="${INDEX_DIR:+$INDEX_DIR/dormant}"
# Every entry reflection has already been asked about, one key per line, across
# all projects. See log_keys.
SEEN="${INDEX_DIR:+$INDEX_DIR/reflected}"

[ "$MODE" = off ] && exit 0

# One key per entry in a log: its EVENT text, from entry-keys.sh. A log with no
# parseable entry gets one key for its whole content, so a malformed log is still
# noticed when it changes.
#
# Entries, not file times, decide whether a log grew. A modification time moves
# when git checks the file out, when a worktree is created from a branch that
# carries it, and when a merge rewrites it, and each of those asked for
# reflection on entries already reflected on.
log_keys() {
  local k=""
  [ -r "$KEYS" ] && k=$(bash "$KEYS" "$1" 2>/dev/null | cut -f2)
  if [ -n "$k" ]; then printf '%s\n' "$k"; else printf 'FILE %s\n' "$(cksum < "$1")"; fi
}

# Reads log paths, prints those that add at least one entry no earlier path had.
# Worktrees carry copies of the same log; a copy is not another run.
distinct_runs() {
  local p keys new seen=""
  while IFS= read -r p; do
    keys=$(log_keys "$p")
    new=$(printf '%s\n' "$keys" | grep -vxF -f <(printf '%s\n' "$seen"))
    [ -n "$new" ] || continue
    seen="$seen${seen:+$'\n'}$new"
    printf '%s\n' "$p"
  done
}

# Tally the most recent $RUNS distinct indexed logs that still exist. Prints the
# tally, or nothing if there is no index or no tally script to run.
recent_tally() {
  [ -n "$INDEX_DIR" ] && [ -r "$INDEX_DIR/runs.md" ] && [ -r "$TALLY" ] || return 0
  local window
  window=$(grep -vE '^[[:space:]]*(#|$)' "$INDEX_DIR/runs.md" |
    while IFS= read -r p; do [ -r "$p" ] && printf '%s\n' "$p"; done |
    distinct_runs | tail -n "$RUNS")
  [ -n "$window" ] || return 0
  set --
  while IFS= read -r p; do set -- "$@" "$p"; done <<< "$window"
  printf 'LOGS %s\n' "$#"
  printf 'PROJECTS %s\n' "$(printf '%s\n' "$window" |
    sed -e 's#/\.claude/worktrees/.*##' -e 's#/\.hordev/run-log\.md$##' | sort -u | grep -c .)"
  bash "$TALLY" "$@" 2>/dev/null
}

state="awake"
if [ "$MODE" = auto ]; then
  tally=$(recent_tally)
  recurring=$(printf '%s\n' "$tally" | grep 'recurring:' | awk '{ print $1 }' | tr '\n' ' ')
  recurring=${recurring% }
  if [ -n "$MARKER" ] && [ -e "$MARKER" ]; then
    # Dormant stays dormant until a class recurs. Worktrees removed from under
    # the window are not a reason to wake.
    [ -z "$recurring" ] && state="dormant" || state="woke"
  else
    nlogs=$(printf '%s\n' "$tally" | awk '$1 == "LOGS" { print $2 }')
    nprojects=$(printf '%s\n' "$tally" | awk '$1 == "PROJECTS" { print $2 }')
    if [ "${nlogs:-0}" -ge "$RUNS" ] && [ "${nprojects:-0}" -ge "$PROJECTS" ] &&
       [ -z "$recurring" ] &&
       ! printf '%s\n' "$tally" | grep -qE '^(unclassified|unparseable) '; then
      state="converging"
    fi
  fi
fi

case "$state" in
  dormant) exit 0 ;;
  converging)
    touch "$MARKER" 2>/dev/null || exit 0
    msg="hordev: self-improvement has converged. The last $RUNS run logs, across $nprojects projects, have no failure class at the recurring bar, so reflection is now dormant and this hook stays quiet. It wakes by itself if a class recurs. HORDEV_REFLECT=on forces reflection; =off silences it for good."
    printf '{"systemMessage":"%s"}\n' "$(json_escape "$msg")"
    exit 0
    ;;
  woke)
    rm -f "$MARKER" 2>/dev/null || true
    ;;
esac

# The seen list is new in 0.8.1. On first use, seed it from logs whose old
# .reflected stamp says they were already reflected, so upgrading does not ask
# about every entry ever written.
by_entry=""
if [ -n "$SEEN" ]; then
  if [ ! -e "$SEEN" ] && : >> "$SEEN" 2>/dev/null; then
    while IFS= read -r log; do
      [ -n "$log" ] || continue
      stamp="$(dirname "$log")/.reflected"
      if [ -e "$stamp" ] && [ ! "$log" -nt "$stamp" ]; then
        log_keys "$log" >> "$SEEN"
      fi
    done <<< "$logs"
  fi
  [ -w "$SEEN" ] && by_entry=1
fi

grown=""
malformed=""
while IFS= read -r log; do
  [ -n "$log" ] || continue
  # Speak only when this log holds an entry not yet asked about, so a session
  # that ends twenty times is not asked twenty times, and a copy of a log is not
  # asked about at all. Without a writable seen list, fall back to the log's
  # modification time against a stamp beside it.
  stamp="$(dirname "$log")/.reflected"
  if [ -n "$by_entry" ]; then
    new=$(log_keys "$log" | grep -vxF -f "$SEEN")
    [ -n "$new" ] || continue
    printf '%s\n' "$new" >> "$SEEN"
  elif [ -e "$stamp" ] && [ ! "$log" -nt "$stamp" ]; then
    continue
  fi
  touch "$stamp" 2>/dev/null || true
  grown="${grown:+$grown, }${log#"$ROOT"/}"
  # Skills that write the log point at improving-hordev for its format, and the
  # agents writing it rarely load that skill. Logs written from memory came back
  # without CLASS, without separators, or as prose, and a log tally-classes.sh
  # cannot parse is invisible to cross-run counting. Catch it while the session
  # that wrote the entries still has the context to rewrite them.
  if [ -r "$VALIDATE" ] && ! bash "$VALIDATE" "$log" >/dev/null 2>&1; then
    malformed="${malformed:+$malformed, }${log#"$ROOT"/}"
  fi
done <<< "$logs"

if [ "$state" = woke ]; then
  lead="hordev: reflection is awake again: $recurring reached the recurring bar in the last $RUNS runs${grown:+ ($grown grew)}."
elif [ -n "$grown" ]; then
  lead="hordev: run log grew since the last reflection ($grown)."
else
  exit 0
fi

# The procedure is owned by using-hordev's Reflect stage. This text quotes it
# word for word, and tests/reflect-hook.test.sh fails if the two drift.
reason="$lead If a run is still in progress, finish it first. Then run the Reflect stage from using-hordev: Dispatch one sonnet agent with the improving-hordev skill text and the run log paths. It appends to ~/.claude/hordev/proposed-amendments.md under a heading naming the project, and edits no skill; you apply or decline what it proposes."
if [ -n "$malformed" ]; then
  reason="$reason Malformed run log ($malformed): run skills/improving-hordev/validate-run-log.sh on it and rewrite the entries it names in the format improving-hordev defines, keeping what they say, before Reflect reads it. A class Reflect cannot parse is never counted."
fi

printf '{"decision":"block","reason":"%s"}\n' "$(json_escape "$reason")"
