# Shared helpers for tests/*.test.sh. Sourced, not executed.
#
# Tests build fixture directories under a fresh temp dir and run the real
# scripts against them. Hooks and scripts depend on nothing but bash; tests may
# use jq to check JSON when it is installed, and say so when it is not.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILS=0

scratch() { mktemp -d "${TMPDIR:-/tmp}/hordev-test.XXXXXX"; }

pass() { printf '  ok    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; [ $# -gt 1 ] && printf '        %s\n' "$2"; FAILS=$((FAILS + 1)); }

assert_empty() {
  if [ -z "$2" ]; then pass "$1"; else fail "$1" "expected no output, got: $2"; fi
}

assert_contains() {
  case "$2" in
    *"$3"*) pass "$1" ;;
    *) fail "$1" "expected to contain: $3 | got: $2" ;;
  esac
}

assert_not_contains() {
  case "$2" in
    *"$3"*) fail "$1" "expected not to contain: $3 | got: $2" ;;
    *) pass "$1" ;;
  esac
}

assert_status() {
  if [ "$2" = "$3" ]; then pass "$1"; else fail "$1" "expected exit $3, got $2"; fi
}

assert_json() {
  if ! command -v jq >/dev/null 2>&1; then
    printf '  skip  %s (jq not installed)\n' "$1"
    return
  fi
  if printf '%s' "$2" | jq -e . >/dev/null 2>&1; then pass "$1"; else fail "$1" "not valid JSON: $2"; fi
}

finish() {
  if [ "$FAILS" -eq 0 ]; then exit 0; fi
  printf '  %d failure(s)\n' "$FAILS"
  exit 1
}
