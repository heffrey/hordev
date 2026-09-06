---
name: improving-hordev
description: Use when a run has ended badly or surprisingly, when the same failure has appeared more than once, when .hordev/run-log.md has grown since the last reflection, or when asked to make hordev itself better
---

# improving-hordev

hordev fails deliberately and visibly so it can fix itself. This skill reads the run log,
diagnoses which skill to amend, and makes the smallest edit to prevent repetition.

## The run log format

File: `.hordev/run-log.md` (append-only; maintained by running skills)

One entry per notable event: an agent failure, a seam collision, an escaped defect,
a missed assumption. Keep entries cheap to write — expensive logging does not happen.

Each entry is exactly 4 lines:

```
EVENT: <what happened; specific, 1-2 sentences>
SKILL: <skill in play: rapid-spec, decomposing-for-hordes, dispatching-hordes, reconciling-horde-output, horde-qa, debugging-in-a-horde, etc>
COST: <one-off | systemic; if systemic, count: (N times)>
RULE: <rule that would prevent it, or blank if none yet identified>
```

Followed by `---` separator.

### Example entries

```
EVENT: Dispatched agent returned pseudo-code instead of implementation.
SKILL: dispatching-hordes
COST: one-off
RULE:
---

EVENT: Two agents wrote to same file without coordination; reconciliation 2h.
SKILL: decomposing-for-hordes
COST: systemic (3 times)
RULE: Assign file ownership explicitly in task context.
---

EVENT: High-blast-radius assumption (schema choice) falsified in QA; 8h rework.
SKILL: rapid-spec
COST: systemic (2 times)
RULE: For each architectural decision, ask "could this break at scale?"
---

EVENT: Null-pointer error path never exercised until merge; CI gap exposed.
SKILL: horde-qa
COST: one-off
RULE:
---
```

## What to log, by whom

- **`dispatching-hordes`**: Agent returns wrong form (plan, pseudo-code, description
  instead of working code). Any re-dispatch counts.
- **`decomposing-for-hordes`**: Two tasks collide on the same file or resource.
  Reconciliation effort > 15 min. Task boundaries don't isolate.
- **`horde-qa`**: Escaped defect (bug in working prototype). Falsified assumption.
  Performance miss (spec said X, real is 10x slower).
- **`debugging-in-a-horde`**: Same bug class recurring across two different agents.
  Error surfaced only at merge, not in agent's own tests.

Do NOT log:
- Individual typos (fix in-place, move on).
- Failures predicted in the spec's risk section (by design).
- Recoveries that cost < 5 min (too cheap to change habits).

## Amendment bar: REPEAT, not once

**Critical rule: change a skill on REPEATED failure only.** One expensive day is
hordev's speed bet. Two identical failures is a signal hordev is missing a rule.

- **One-off**: Log it. Move on. Capture the cost, but do not amend.
- **Systemic** (seen 2 times): Amend the skill. Add one rule.
- **Recurring** (3+ times OR > 4h cumulative cost): Schedule a full skill rewrite.

This keeps hordev from over-fitting to bad luck while ensuring honest failures change
the library.

## Symptom-to-skill map

Failures surface far from their cause. Use this to diagnose which skill is actually
under-specified:

| Symptom | Likely Culprit | Root Cause |
|---------|----------------|-----------|
| Agents return plans/descriptions, not code | dispatching-hordes | Output form contract unclear in prompt |
| Tasks collide on same file | decomposing-for-hordes | Decomposition omits explicit ownership |
| Seam defects found at merge | decomposing-for-hordes + horde-qa | Task boundaries don't isolate; untested paths |
| Blown deadline / scope creep | rapid-spec | Spec cut a hard question to save time |
| Same off-by-one bug in 2 agents | horde-qa | Missing test category; error path untested |
| Defect escaped to integration test | horde-qa | QA checklist incomplete or not enforced |

## How to amend a skill

1. **Diagnosis first.** Read the COST field. If one-off, skip steps 2–5.
2. **Find the root rule.** What decision would have prevented this? Be specific.
3. **Smallest edit.** Add one decision rule to the skill, or clarify an existing one.
   Do NOT rewrite the skill wholesale. If the change is complex, move to step 5.
4. **Update the run log.** Fill the RULE field for this entry.
5. **Write the amendment where it will survive.** See below — this depends on
   how hordev was installed, and getting it wrong means the edit is silently
   discarded on the next plugin update.
6. **Complex changes only**: Hand off to `writing-hordev-skills` for prose or structure.

## Where the amendment goes

Check whether the skills you are about to edit live in a git repository the
user controls:

```bash
git -C "$(dirname "$SKILL_PATH")" rev-parse --show-toplevel 2>/dev/null
```

**Installed from a clone** (the path resolves, and it is the hordev checkout):
edit the skill directly and commit with
`improving-hordev: <skill> — add rule for <symptom>`. Keep amendments
reviewable in git history.

**Installed from the marketplace** (skills live under the plugin cache): do
NOT edit them. That directory is not version controlled and is overwritten on
the next plugin update, so the edit looks applied and then vanishes. Instead
append the proposed amendment to `.hordev/proposed-amendments.md` in the
project, in this form:

```
## <skill-name> — <symptom>

Observed: <what happened, and the run-log entries that show the repeat>
Rule to add: <the exact text to insert, and where>
```

Then tell the user the file exists and that applying it means running hordev
from a clone or opening a pull request upstream. Self-improvement that
silently no-ops is worse than none, because it teaches nobody while looking
like it worked.

Example amendment:

```
OLD (in decomposing-for-hordes):
  Decompose by task boundary, not by file.

NEW:
  Decompose by task boundary, not by file. Assign each file to one owner
  in the task context. Files with shared writes require reconciliation step.
```

## Guardrails against runaway self-modification

- **No mid-run edits.** Finish the current run. Log the failure. Amend next cycle.
- **No subagent edits.** Only the main agent edits skills. Subagents log; orchestrator amends.
- **Version control only.** All edits in git. No hidden tweaks.
- **Do not overfit.** Wait for repetition (2+ times) before amending.
- **Skill bloat detection.** If a skill grows > 20 rules, it is overfit. Rewrite instead.

## What never gets optimized away

hordev wins by speed, and sometimes that speed bet loses. When a run costs extra
because hordev was too aggressive (spec skipped a hard question, decomposition was
premature, QA coverage was thin), **record it honestly in the log**. Do not quietly
delete the entry.

These are the failures worth learning from. They live in version control. They earn
amendments that make hordev faster next time while keeping it safe.
