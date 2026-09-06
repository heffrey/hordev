#!/usr/bin/env bash
# Inject the hordev entrypoint skill at session start.
#
# Without this, using-hordev is a file nobody reads and the session runs on
# whatever default posture the harness came with. The entrypoint is what makes
# the rest of the library reachable, so it loads unconditionally.
#
# Deliberately depends on nothing but bash. An earlier version shelled out to
# python3 to encode the JSON, which fails with exit 127 where python3 is absent
# and, worse, exit 1 behind macOS's Xcode stub — an error notice on every single
# session start.
set -uo pipefail

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SKILL="$ROOT/skills/using-hordev/SKILL.md"

# A missing entrypoint is not worth failing a session over.
[ -r "$SKILL" ] || exit 0

body=$(cat "$SKILL")

# Escape for a JSON string literal. Backslashes first, or the escapes we add
# below get escaped again.
body=${body//\\/\\\\}
body=${body//\"/\\\"}
body=${body//$'\r'/\\r}
body=${body//$'\t'/\\t}
body=${body//$'\n'/\\n}

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$body"
