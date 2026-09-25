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

Each entry is five fields, in this order. EVENT and RULE may wrap onto
continuation lines; nothing else goes in an entry.

```
EVENT: <what happened; specific, 1-2 sentences>
SKILL: <skill in play: rapid-spec, decomposing-for-hordes, dispatching-hordes, reconciling-horde-output, horde-qa, debugging-in-a-horde, etc>
COST: <one-off | systemic (N times)>
CLASS: <one class from the vocabulary below>
RULE: <rule that would prevent it, or blank if none yet identified>
```

Followed by `---` separator. Prose, headings, and tables are not entries: a log
written that way cannot be tallied without re-reading every paragraph by hand,
which is the cost the format exists to remove.

### CLASS vocabulary

SKILL says where a failure surfaced; CLASS says what kind of failure it was.
The same class shows up under different skills and in different projects, and
counting by class is how a repeat becomes visible across runs.

| Class | Use when |
|---|---|
| `agent-git` | An agent ran git, or who commits was left unstated. |
| `format-drift` | An artifact broke the format its owner skill defines, or cited something never written. |
| `budget-overrun` | An artifact came back past its length or scope budget. |
| `green-but-broken` | Every check passed and the real path did not work. |
| `write-collision` | Two writers touched one write surface. |
| `dispatch-gap` | Planned work was never dispatched, or went out missing what it needed. |
| `spec-misread` | The spec aimed at the wrong target, and everything downstream agreed with it. |
| `duplicate-rule` | Two skills state one rule, and the copies drift. |
| `resource` | Memory, ports, disk, or another machine limit broke the run. |
| `other` | None fits. Say why in EVENT. Three alike earn a new class here. |

Pick one. An entry that fits two is usually two entries.

### Example entries

```
EVENT: Dispatched agent returned pseudo-code instead of implementation.
SKILL: dispatching-hordes
COST: one-off
CLASS: dispatch-gap
RULE:
---

EVENT: Two agents wrote to same file without coordination; reconciliation 2h.
SKILL: decomposing-for-hordes
COST: systemic (3 times)
CLASS: write-collision
RULE: Assign file ownership explicitly in task context.
---

EVENT: Null-pointer error path never exercised until merge; CI gap exposed.
SKILL: horde-qa
COST: one-off
CLASS: green-but-broken
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

**Count by CLASS, across every run you can see.** A failure that happens once in
each of two projects is a repeat, and a per-log count never shows it. The `Stop`
hook appends every run log it finds to a user-level index,
`~/.claude/hordev/runs.md`, one path per line. Read those logs as well as the
ones you were handed.

**Validate before you tally.** Run `validate-run-log.sh` from this skill's
directory on every log first. A malformed entry is not counted; it is reported
at the top of your proposal with the problems the validator printed, then
classified by reading so it still reaches the tally. A log that needed that has
itself earned a `format-drift` entry.

Then run `tally-classes.sh` over the lot:

```bash
tally-classes.sh                 # every log in the index
tally-classes.sh a.md b.md       # just these
```

It prints each class with its entry count, how many distinct logs it appears
in, and the bar it clears. A path in the index that no longer exists (a removed
worktree) is reported, not silently skipped. An entry is identified by its
EVENT text and counted once, in the first log that has it: worktrees carry
copies of the same log, and a copy is not a repeat. Two real failures therefore
need two EVENTs worded differently, which they always are.

- **One-off**: Log it. Move on. Capture the cost, but do not amend.
- **Systemic** (seen 2 times): Amend the skill. Add one rule.
- **Recurring** (3+ times OR > 4h cumulative cost): Schedule a full skill rewrite.

This keeps hordev from over-fitting to bad luck while ensuring honest failures change
the library.

## When reflection goes dormant

Self-improvement is a cost paid on the user's time, and it is meant to stop once
hordev is good enough. The measure is amendment yield going to zero: real runs
no longer repeat failures.

**Converged** means all of these, over the 10 most recent run logs in the index
that still exist and each add an entry no earlier one has (a copy is not a run):

- they come from at least 3 projects, so one easy codebase cannot declare victory
- every entry is well formed and classified, so absence of a repeat is real
- no class reaches the recurring bar (3 or more entries) in `tally-classes.sh`

When that holds, the `Stop` hook tells the user once that reflection is dormant
and stops blocking. It keeps indexing logs. It wakes by itself the moment any
class reaches the recurring bar again in the window, because what breaks a
converged library is usually new: a model or harness change, not an old lesson
forgotten. Teardown shrinking the window does not wake it.

`HORDEV_REFLECT=on` forces reflection regardless; `HORDEV_REFLECT=off` silences
the hook entirely. `HORDEV_CONVERGE_RUNS` and `HORDEV_CONVERGE_PROJECTS` change
the window. The hook implements this section; change the definition here first.

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

## Two jobs, two owners

This skill does two separable things, and only one of them is dangerous.

**Analyse and propose** — read `.hordev/run-log.md`, count occurrences per
skill, apply the amendment bar, and draft the exact text to insert and where.
Bounded, mechanical, and touches no skill file. This is the **Reflect** stage;
`using-hordev` owns when it runs, on which model, and what it writes. This skill
owns only the analysis rules below.

**Amend and commit** — edit a `SKILL.md` and put it in version control.
Orchestrator only, always. A library that edits itself through an agent nobody
reviewed is not self-improving, it is drifting.

A Reflect agent that returns "nothing repeated; no amendment earned" has done
its job. Repetition is the bar, and most runs will not clear it.

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
reviewable in git history. Two things catch people here:

- **A release goes through `scripts/version.sh <x.y.z>`**, then a
  `Release x.y.z` commit and an annotated tag. Never bump a version string by
  hand: it lives in four files, and the pre-commit hook rejects a commit where
  they disagree.
- **A committed amendment does not reach the session that made it.** Sessions
  load skills from the plugin cache, which refreshes when the plugin updates
  from the marketplace, not when the clone changes. Reloading skills reports
  no changes until then. Say so when you report the amendment, rather than
  letting the user assume the running session already follows it.

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
- **No subagent edits.** Only the orchestrator edits skills; a Reflect agent
  proposes (see Two jobs, two owners). This is the boundary that keeps hordev
  from rewriting itself while nobody is reading.
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

## Battle cry

"Strength and honor." — when an amendment lands and the library is stronger than
it was. A logged failure with no amendment yet is not that moment.

Once, at that moment — not every message, and never two messages running. Full
rules in `using-hordev` § Voice: conversational output only, never in artifacts,
never on bad news.
