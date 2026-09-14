#!/usr/bin/env bash
# Runs every tests/*.test.sh and exits nonzero if any fails.
#
#   tests/run.sh              all tests
#   tests/run.sh reflect      only files whose name contains "reflect"
set -uo pipefail

cd "$(dirname "$0")"

status=0
for t in *.test.sh; do
  case "$t" in *"${1:-}"*) ;; *) continue ;; esac
  printf '%s\n' "$t"
  bash "$t" || status=1
done

if [ "$status" -eq 0 ]; then printf 'all tests passed\n'; else printf 'tests failed\n'; fi
exit "$status"
