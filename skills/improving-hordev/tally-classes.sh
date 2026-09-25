#!/usr/bin/env bash
# Counts run-log entries by CLASS across run logs, so a failure that happens once
# in each of two projects shows up as the repeat it is.
#
#   tally-classes.sh               every log listed in the user-level index
#   tally-classes.sh a.md b.md     just these logs
#
# The index is ${HORDEV_HOME:-~/.claude/hordev}/runs.md, one path per line,
# appended to by hooks/reflect.sh. The vocabulary is read from the table in this
# skill's SKILL.md, so there is one list and it cannot drift from this script.
#
# Depends on bash and POSIX tools only.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
INDEX="${HORDEV_HOME:-${HOME:-}/.claude/hordev}/runs.md"

vocabulary=$(sed -n '/^### CLASS vocabulary/,/^### Example/p' "$HERE/SKILL.md" \
  | grep -oE '^\| `[a-z-]+` \|' | tr -d '|` ')
[ -n "$vocabulary" ] || { echo "tally-classes.sh: no CLASS vocabulary found in $HERE/SKILL.md" >&2; exit 2; }

logs=""
if [ $# -gt 0 ]; then
  for a in "$@"; do logs="$logs$a"$'\n'; done
else
  [ -r "$INDEX" ] || { echo "tally-classes.sh: no logs given and no index at $INDEX" >&2; exit 2; }
  logs=$(grep -vE '^[[:space:]]*(#|$)' "$INDEX")$'\n'
fi

pairs=""      # "<class>\t<log number>\t<event>" per classed entry
notes=""
n=0
while IFS= read -r log; do
  [ -n "$log" ] || continue
  if [ ! -r "$log" ]; then
    notes="${notes}missing        $log"$'\n'
    continue
  fi
  n=$((n + 1))
  events=$(grep -cE '^EVENT:' "$log")
  classes=$(grep -E '^CLASS:' "$log" | sed -E 's/^CLASS:[[:space:]]*//; s/[[:space:]]+$//')
  classed=0
  [ -n "$classes" ] && classed=$(printf '%s\n' "$classes" | grep -c .)
  if [ "$events" -gt "$classed" ]; then
    notes="${notes}unclassified   $log ($((events - classed)) of $events entries have no CLASS)"$'\n'
  fi
  if [ "$events" -eq 0 ]; then
    notes="${notes}unparseable    $log (no EVENT: lines; run validate-run-log.sh)"$'\n'
  fi
  pairs="$pairs$(bash "$HERE/entry-keys.sh" "$log" |
    awk -F'\t' -v n="$n" '$1 != "" { print $1 "\t" n "\t" $2 }')"$'\n'
done <<< "$logs"

# An entry is counted once, in the first log that has it. Worktrees carry
# copies of the same log, and counting each copy turned one failure into a
# recurrence.
printf '%-18s %7s %5s  %s\n' CLASS ENTRIES LOGS BAR
printf '%s' "$pairs" | grep . | awk -F'\t' '
  seen_event[$3]++ { next }
  { e[$1]++; if (!seen[$1 FS $2]++) l[$1]++ }
  END { for (c in e) printf "%s\t%d\t%d\n", c, e[c], l[c] }' \
  | sort -t "$(printf '\t')" -k2,2nr -k1,1 \
  | while IFS="$(printf '\t')" read -r class entries nlogs; do
      if [ "$class" = other ]; then
        bar="not a class; three alike earn one"
      elif ! printf '%s\n' "$vocabulary" | grep -qxF "$class"; then
        bar="unknown class, not in the vocabulary"
      elif [ "$entries" -ge 3 ]; then
        bar="recurring: rewrite"
      elif [ "$entries" -eq 2 ]; then
        bar="systemic: add a rule"
      else
        bar="one-off"
      fi
      [ "$nlogs" -ge 2 ] && bar="$bar (across $nlogs runs)"
      printf '%-18s %7s %5s  %s\n' "$class" "$entries" "$nlogs" "$bar"
    done

[ -n "$notes" ] && printf '\n%s' "$notes"
exit 0
