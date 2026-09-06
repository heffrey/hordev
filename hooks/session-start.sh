#!/usr/bin/env bash
# Inject the hordev entrypoint skill at session start.
#
# Without this, using-hordev is a file nobody reads and the session runs on
# whatever default posture the harness came with. The entrypoint is what makes
# the rest of the library reachable, so it loads unconditionally.
set -uo pipefail

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SKILL="$ROOT/skills/using-hordev/SKILL.md"

# A missing entrypoint is not worth failing a session over.
[ -r "$SKILL" ] || exit 0

python3 -c '
import json, sys

with open(sys.argv[1], encoding="utf-8") as handle:
    body = handle.read()

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": body,
    }
}))
' "$SKILL"
