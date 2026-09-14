#!/usr/bin/env bash
# Fails when a hordev artifact cites an assumption ID the ledger does not define.
#
#   check-ids.sh [hordev-dir]        default: .hordev
#
# Defined: every "## <ID>: <title>" heading in <hordev-dir>/assumptions.md.
# Cited:   every ID-shaped token (PK-001, A-018) in any other .md under
#          <hordev-dir> -- specs, TDDs, the build plan, and the saved dispatch
#          prompts in dispatch/. The prompts matter most: they are where cited-
#          but-unwritten IDs were actually found, and no spec file mentioned them.
#
# Any cited ID that is not defined fails, including one whose prefix the ledger
# has never seen, since a run's first phantom has exactly that shape. Tokens
# that look like IDs but are not (SHA-256, ISO-8601) are ignored by prefix;
# extend the list with HORDEV_ID_IGNORE="ABC XYZ".
#
# Exit 0 clean, 1 on any phantom, 2 on bad usage. Bash and POSIX tools only.
set -uo pipefail

DIR="${1:-.hordev}"
LEDGER="$DIR/assumptions.md"
IGNORE=" SHA AES RSA ISO RFC CVE UTF TLS SSL HTTP ECMA ES X ${HORDEV_ID_IGNORE:-} "

[ -d "$DIR" ] || { echo "check-ids.sh: no directory $DIR" >&2; exit 2; }

defined=""
[ -r "$LEDGER" ] && defined=$(grep -oE '^## [A-Z][A-Z0-9]*-[0-9]{3,}:' "$LEDGER" | sed -E 's/^## //; s/:$//')

files=$(find "$DIR" -type f -name '*.md' \
  ! -path "$LEDGER" ! -name run-log.md ! -name proposed-amendments.md | sort)

[ -n "$files" ] || { echo "check-ids.sh: no artifacts under $DIR cite anything"; exit 0; }

# A function rather than inline in $(...): bash 3.2 misparses a case pattern's
# closing parenthesis inside command substitution.
find_phantoms() {
  printf '%s\n' "$files" | while IFS= read -r f; do
    awk -v file="$f" '
      {
        line = $0
        while (match(line, /[A-Z][A-Z0-9]*-[0-9][0-9][0-9]+/)) {
          before = (RSTART > 1) ? substr(line, RSTART - 1, 1) : ""
          after = substr(line, RSTART + RLENGTH, 1)
          tok = substr(line, RSTART, RLENGTH)
          if (before !~ /[A-Za-z0-9-]/ && after !~ /[A-Za-z0-9-]/) print file ":" NR ": " tok
          line = substr(line, RSTART + RLENGTH)
        }
      }' "$f"
  done | while IFS= read -r hit; do
    id=${hit##*: }
    prefix=${id%%-*}
    case "$IGNORE" in *" $prefix "*) continue ;; esac
    printf '%s\n' "$defined" | grep -qxF "$id" && continue
    printf '%s\n' "$hit"
  done
}
phantoms=$(find_phantoms)

if [ -n "$phantoms" ]; then
  printf '%s\n' "$phantoms" | sed 's/$/ is cited but has no entry in the ledger/'
  n=$(printf '%s\n' "$phantoms" | sed 's/.*: //' | sort -u | grep -c .)
  printf '\n%d assumption ID(s) cited and never written. Write each entry in %s, then re-run.\n' "$n" "$LEDGER"
  exit 1
fi

printf 'ok: every cited assumption ID is in %s\n' "$LEDGER"
exit 0
