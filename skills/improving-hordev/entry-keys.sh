#!/usr/bin/env bash
# Prints one line per run-log entry: its CLASS, a tab, and its EVENT text with
# continuation lines joined and whitespace collapsed.
#
#   entry-keys.sh <run-log.md> [more logs...]
#
# The EVENT text is an entry's identity. A log copied into another worktree,
# rewritten by a checkout, or back-filled with CLASS keeps it, so reflect.sh
# does not take the copy for a new run and tally-classes.sh does not count one
# failure once per copy. Both read entries through this script so they cannot
# disagree about what an entry is. CLASS is empty for an entry that has none.
#
# Depends on bash and POSIX tools only.
set -uo pipefail

[ $# -gt 0 ] || { echo "usage: entry-keys.sh <run-log.md> [...]" >&2; exit 2; }

for log in "$@"; do
  [ -r "$log" ] || continue
  awk '
    function flush() {
      if (ev != "") {
        gsub(/[[:space:]]+/, " ", ev); sub(/^ /, "", ev); sub(/ $/, "", ev)
        if (ev != "") print cls "\t" ev
      }
      ev = ""; cls = ""; inev = 0
    }
    /^EVENT:/ { flush(); ev = substr($0, 7); inev = 1; next }
    /^---[[:space:]]*$/ { flush(); next }
    /^CLASS:/ { cls = substr($0, 7); gsub(/^[[:space:]]+|[[:space:]]+$/, "", cls); inev = 0; next }
    /^(SKILL|COST|RULE):/ { inev = 0; next }
    /^[[:space:]]*$/ { inev = 0; next }
    inev { ev = ev " " $0 }
    END { flush() }
  ' "$log"
done
exit 0
