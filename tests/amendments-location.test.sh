#!/usr/bin/env bash
# Standing rule: proposed amendments live at the user level (~/.claude/hordev/proposed-amendments.md),
# never in a project's .hordev/. hordev is amended from its clone, so a proposal left in a
# project is one nobody applies. This fails if any skill, hook or script points back at a project.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

# Every mention of the file, with the user-level forms removed; whatever is left is project-level.
stray=$(grep -rn 'proposed-amendments' "$REPO/skills" "$REPO/hooks" "$REPO/scripts" 2>/dev/null \
  | sed -e 's#~/\.claude/hordev/proposed-amendments##g' -e 's#\$HOME/\.claude/hordev/proposed-amendments##g' \
  | grep '\.hordev/proposed-amendments' \
  | sed "s#^$REPO/##")
assert_empty "no skill, hook or script puts proposals in a project" "$stray"

skill=$(tr '\n' ' ' < "$REPO/skills/improving-hordev/SKILL.md" | tr -s ' ')
assert_contains "improving-hordev names the user-level file" "$skill" '~/.claude/hordev/proposed-amendments.md'
assert_contains "improving-hordev states the standing rule" "$skill" 'Proposals live at the user level, never in a project.'

stage=$(tr '\n' ' ' < "$REPO/skills/using-hordev/SKILL.md" | tr -s ' ')
assert_contains "using-hordev's Reflect stage writes the user-level file" "$stage" '~/.claude/hordev/proposed-amendments.md'

finish
