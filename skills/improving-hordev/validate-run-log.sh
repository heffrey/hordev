#!/usr/bin/env bash
# Reports run-log entries that break the format in this skill's SKILL.md.
#
#   validate-run-log.sh .hordev/run-log.md [more logs...]
#
# Exit 0 when every log is well formed, 1 when any entry is malformed, 2 on bad
# usage. Each problem prints as <file>:<line>: <what is wrong>.
#
# A log is an optional preamble (a # title and plain text), then entries
# separated by lines that are exactly ---. An entry is EVENT, SKILL, COST, CLASS,
# RULE in that order, once each. EVENT and RULE may wrap onto continuation lines.
# Headings, tables, and prose between entries are what a hand re-tally at
# reflection time is made of, so they fail.
#
# Depends on bash and POSIX tools only.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

[ $# -gt 0 ] || { echo "usage: validate-run-log.sh <run-log.md> [...]" >&2; exit 2; }

vocabulary=$(sed -n '/^### CLASS vocabulary/,/^### Example/p' "$HERE/SKILL.md" \
  | grep -oE '^\| `[a-z-]+` \|' | tr -d '|` ' | tr '\n' ' ')
[ -n "$vocabulary" ] || { echo "validate-run-log.sh: no CLASS vocabulary in $HERE/SKILL.md" >&2; exit 2; }

status=0
for log in "$@"; do
  if [ ! -r "$log" ]; then
    echo "$log: not readable"
    status=1
    continue
  fi
  awk -v file="$log" -v vocab=" $vocabulary " '
    function problem(line, msg) { printf "%s:%d: %s\n", file, line, msg; bad++ }

    function close_entry() {
      if (!open) return
      if (want <= 5) problem(start, "entry stops before " order[want] " (fields are EVENT, SKILL, COST, CLASS, RULE)")
      open = 0
      entries++
    }

    BEGIN {
      split("EVENT SKILL COST CLASS RULE", order, " ")
      seen_sep = 0; open = 0; bad = 0; entries = 0
    }

    /^---[[:space:]]*$/ { close_entry(); seen_sep = 1; blank_in_entry = 0; skipping = 0; next }

    # Preamble: a title and plain text before the first separator. A log may
    # also open straight into its first entry, since --- follows an entry.
    !seen_sep && /^EVENT:/ { seen_sep = 1 }
    !seen_sep {
      if ($0 ~ /^(SKILL|COST|CLASS|RULE):/) problem(NR, "field before the first EVENT")
      else if ($0 ~ /^##/) problem(NR, "heading in the preamble; entries are fields, not sections")
      else if ($0 ~ /^\|/) problem(NR, "table in the preamble; entries are fields, not tables")
      # Fields of an invented format (WHAT:, - CAUSE:) never reach a separator,
      # so without this a log written entirely from memory reads as 0 entries, ok.
      else if ($0 ~ /^[[:space:]]*([-*][[:space:]]+)?[A-Z][A-Z]+:/)
        problem(NR, "field outside the entry format; entries are EVENT, SKILL, COST, CLASS, RULE: " substr($0, 1, 60))
      next
    }

    /^[[:space:]]*$/ { if (open) blank_in_entry = NR; next }

    # Rest of a prose block already reported once.
    !open && skipping { next }

    {
      if (match($0, /^(EVENT|SKILL|COST|CLASS|RULE):/)) {
        key = substr($0, 1, RLENGTH - 1)
        val = substr($0, RLENGTH + 1); sub(/^[[:space:]]+/, "", val); sub(/[[:space:]]+$/, "", val)
      } else {
        key = ""
      }

      if (!open) {
        if (key != "EVENT") {
          problem(NR, (key == "" ? "text outside an entry (prose, heading, or table): " substr($0, 1, 60) : "entry starts with " key ", not EVENT"))
          # Swallow the rest of this block so one prose section is one problem.
          skipping = 1
          next
        }
        open = 1; want = 1; start = NR; last = ""; blank_in_entry = 0
      }

      if (blank_in_entry) { problem(blank_in_entry, "blank line inside an entry"); blank_in_entry = 0 }

      if (key == "") {
        if (last == "EVENT" || last == "RULE") next
        problem(NR, (last == "" ? "continuation line with no field" : last " does not wrap; only EVENT and RULE may"))
        next
      }

      if (want > 5) { problem(NR, "extra " key " after RULE; separate entries with ---"); next }
      if (key != order[want]) {
        problem(NR, "expected " order[want] ", found " key)
        # Resynchronise on the field we actually found, if it comes later.
        for (i = want; i <= 5; i++) if (order[i] == key) want = i
      }

      if (key == "EVENT" && val == "") problem(NR, "EVENT is empty")
      if (key == "SKILL" && val == "") problem(NR, "SKILL is empty")
      if (key == "COST" && val !~ /^(one-off|systemic \([0-9]+ times\))$/)
        problem(NR, "COST must be one-off or systemic (N times), got: " val)
      if (key == "CLASS" && index(vocab, " " val " ") == 0)
        problem(NR, "CLASS " (val == "" ? "is empty" : val " is not in the vocabulary"))

      last = key
      want++
    }

    END {
      close_entry()
      if (bad == 0) printf "%s: ok, %d entries\n", file, entries
      exit (bad > 0)
    }
  ' "$log" || status=1
done

exit "$status"
