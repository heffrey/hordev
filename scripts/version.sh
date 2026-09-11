#!/usr/bin/env bash
# The version string lives in four files and has to agree across all of them.
#
# It drifted twice -- 0.4.0 and 0.5.0 were bumped in plugin.json alone, so
# marketplace.json went on advertising 0.3.0 and every install stayed two
# versions behind. The bump is easy to get wrong because three of the four
# files are prose and only one of them is the one that actually ships.
#
# Usage:
#   scripts/version.sh              check that all four agree (exit 1 if not)
#   scripts/version.sh 0.6.0        set all four to 0.6.0
#
# Every edit is verified to have matched exactly once. A pattern that stops
# matching -- because someone reworded the prose around it -- is a hard error,
# not a silent skip: an edit that no-ops while looking applied is the failure
# this script exists to prevent.
#
# Deliberately depends on nothing but bash, grep and sed.
set -euo pipefail

cd "$(dirname "$0")/.."

# file:pattern -- one per place the version is written. The pattern must match
# exactly one line, and the version must be the first \d+\.\d+\.\d+ on it, since
# that is the occurrence the bump rewrites.
SITES=(
  '.claude-plugin/plugin.json:^  "version": "[0-9]+\.[0-9]+\.[0-9]+",$'
  '.claude-plugin/marketplace.json:^      "version": "[0-9]+\.[0-9]+\.[0-9]+",$'
  'CLAUDE.md:^Version [0-9]+\.[0-9]+\.[0-9]+\. The plugin manifest'
  'README.md:^Early\. Version [0-9]+\.[0-9]+\.[0-9]+\.$'
)

fail() { printf 'version.sh: %s\n' "$1" >&2; exit 1; }

# Echoes the version found at a site. Fails unless the pattern matched once.
read_site() {
  local file="${1%%:*}" pat="${1#*:}" hits
  [ -r "$file" ] || fail "$file: not readable"
  hits=$(grep -Ec "$pat" "$file" || true)
  [ "$hits" = 1 ] || fail "$file: pattern matched $hits times, expected 1.
  Pattern: $pat
  The file was probably reworded. Fix the pattern in scripts/version.sh --
  do not delete the site, or the next bump silently skips this file."
  grep -E "$pat" "$file" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1
}

if [ $# -eq 0 ]; then
  # Check mode.
  declare -a seen=()
  for site in "${SITES[@]}"; do
    v=$(read_site "$site")
    seen+=("$v")
    printf '%-34s %s\n' "${site%%:*}" "$v"
  done
  for v in "${seen[@]}"; do
    [ "$v" = "${seen[0]}" ] || fail "versions disagree. Run: scripts/version.sh <version>"
  done
  printf 'all agree at %s\n' "${seen[0]}"
  exit 0
fi

# Bump mode.
new="$1"
[ $# -eq 1 ] || fail "takes one version, got $#"
printf '%s' "$new" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' \
  || fail "'$new' is not a semver x.y.z"

for site in "${SITES[@]}"; do
  file="${site%%:*}" pat="${site#*:}"
  old=$(read_site "$site")
  if [ "$old" = "$new" ]; then
    printf '%-34s %s (unchanged)\n' "$file" "$new"
    continue
  fi
  # Rewrite only the matching line, and only the version within it.
  sed -i.bak -E "/$pat/s/[0-9]+\.[0-9]+\.[0-9]+/$new/" "$file"
  rm -f "$file.bak"
  got=$(read_site "$site")
  [ "$got" = "$new" ] || fail "$file: wrote $new but read back $got"
  printf '%-34s %s -> %s\n' "$file" "$old" "$new"
done

printf '\nNow: git commit -m "Release %s" && git tag -a v%s\n' "$new" "$new"
