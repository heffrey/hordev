---
name: horde-status
description: Use when asked where a hordev run stands - "where are we", "what's the horde doing", "status", "what's left", "how's the run going", "what did you decide" - or before handing a run back to the user
---

# Horde Status

## Overview

A horde-status report is **a stage pipeline, a task table, a live agent roster, and the assumption ledger** — in that order. It answers four questions a generic status report cannot:

1. Which of the five stages is the run in?
2. Which agents are out right now, on what model, owning which files?
3. What was decided **without asking**, and is any of it falsified?
4. Has `horde-qa` run — because nothing is done before it has.

Written in the reply, not published as a page. Scannable, not narrative.

## Why hordev needs its own

`status-report` assumes work you did. A horde run is work **dispatched**, against **assumptions nobody approved**, behind a **QA gate that is the only correctness check in the system**. Three things follow that a generic report gets wrong:

- **No task exceeds 75% before `horde-qa` passes.** An agent reporting "tests pass" is a claim, not evidence. The horde's own word is the least reliable input in the run.
- **The ledger is not an appendix.** The user approved no spec and no TDD. The ledger is the only place they learn what was decided for them, so it is a section, ranked by blast radius.
- **A falsified assumption outranks everything.** One with large blast radius sends the run back to `rapid-spec`. That is not a row in a table; it goes at the top, in plain language, before anything else.

## The report IS, in this order

### 1. Run header

One block. Run name, branch, worktree path, and the stage.

```
Run      six-features
Branch   worktree-plan-six-features (pushed)
Worktree .claude/worktrees/plan-six-features
Stage    Swarm — wave 1 of 4
```

If the run is **not** isolated in a worktree, say so here and say it loudly. A horde writing to the user's checkout is the failure `isolating-horde-workspaces` exists to prevent, and it is worth interrupting the report to name.

### 2. Stage pipeline

The five stages, with the current one marked. One line.

```
Extract ✓ → Design ✓ → Cut ✓ → Swarm ◈ → Verify ○
```

`✓` complete, `◈` in progress, `○` not started, `✗` failed or sent back. A stage skipped deliberately is `–` with a reason on the next line. Never mark Verify `✓` on the horde's own say-so.

### 3. Task table

One row per deliverable, same bar as `status-report`: 20 blocks, `█` filled, `░` empty, one block per 5%.

| Task | Progress | Agent | State |
|---|---|---|---|
| Emotion lexicon + parser | `███████████████░░░░░` 75% | `build-lexicon` haiku | 41/41 tests pass, unverified |
| Supabase schema + RLS | `██████████░░░░░░░░░░` 50% | `build-supabase` haiku | migrations written, no live instance |
| Coach portal | `░░░░░░░░░░░░░░░░░░░░` 0% | — | blocked: no Supabase project |

The **Agent** column is what makes this a horde report. Name the agent and its model. A judgment task on `haiku` or a volume task on `opus` is a decomposition smell worth seeing at a glance — call it out below the table when you spot one.

Every dispatched task gets a row, including ones that returned nothing useful. An agent that timed out, returned a plan instead of code, or reported BLOCKED is a row at the percentage it actually reached, with the reason in State. Dropping it is how a horde report lies.

### The hordev percentage ladder

Take the highest rung whose evidence has actually happened:

| Evidence | % |
|---|---|
| Cut, not dispatched | 0 |
| Spec exists | 15 |
| TDD exists | 25 |
| Agent dispatched, still out | 40 |
| Code returned, not reconciled | 50 |
| Reconciled — the tree builds | 65 |
| Tests pass **and you ran them yourself** | 75 |
| `horde-qa` passed | 90 |
| Accepted by the user, in use | 100 |

**75 is the ceiling until QA.** An agent's report of green tests is 65 — you have code that builds and a claim about it. Run the tests yourself to reach 75. This is the single most important rule in the ladder, because a horde's most common failure is confidently reporting success.

Work whose only deliverable is an answer — a spec, a decomposition, a recommendation — has no QA gate, so it reaches 100 when delivered and the user can act.

### 4. Agents in flight

Only while any are out. Drop the section entirely when none are.

```
build-lexicon      haiku   ◈ running   src/lib/emotion-lexicon.ts
build-supabase     haiku   ◈ running   supabase/migrations/**
build-subscribe    haiku   ✓ returned  functions/.../{subscribe,confirm}/**
```

Include the **owned paths**, because file ownership is what makes the wave safe. If two running agents own the same path, that is a decomposition bug that is happening *right now* — say so above the table, not in it.

Never invent an agent's result. An agent still out is `running`, and its row says nothing about whether the work is good.

### 5. Assumption ledger

Read `.hordev/assumptions.md`. Report open entries **grouped by blast radius, largest first**, and every falsified entry regardless of size.

```
Falsified
  A-004  tier shown once, never a progress view    → superseded by A-015

Existential
  A-008  community is Reddit, not software we write        [open]

Large
  A-005  analytics is PostHog, no content ever             [open]
  A-003  tier changes Coach's register, not access         [open]
```

An **Existential** entry gets a sentence of plain English, not just its title — it is the one that invalidates the run if wrong.

If the ledger is empty in a run that made decisions, that is itself the finding: the run guessed without recording, and `rapid-spec` was not followed.

### 6. Closing section

Whichever apply, in this order:

- **Falsified with large blast radius** → say it first and say what it costs: which stage the run returns to, and what gets thrown away. Never bury this.
- **Blocked on you** → what needs the user's judgment, access, money, or an account only they can create. External service setup (a Supabase project, a Mailgun domain, a subreddit) is the commonest blocker in a hordev run and is never something the horde can clear. Separate a real decision from a mechanical errand.
- **Next wave** → what dispatches without being asked, and explicitly whether those agents can run **at once**. Parallelism is hordev's default; a sequential next step must name the data dependency or the shared file that forces it.
- **Every task at 90%+** → a **What's next** section. Same rule as `status-report`: let the work set the count, never pad.

## Corroborate against the tree, not the agents

The session supplies the tasks. The **working tree** supplies the truth about them.

An agent's report is a claim. Before writing a percentage above 65, check it yourself — run the test file, read the diff, confirm the file exists. `git status` and `git log` in the worktree corroborate; the agent's summary does not.

When an agent's claim and the tree disagree, report the tree and say the agent claimed otherwise. "Agent reported 9/9 passing; the test file does not exist" is the most useful line such a report can contain.

## Common mistakes

| Mistake | Fix |
|---|---|
| Scoring a task 90% on the agent's word | Unverified by you is 65; QA-passed is 90 |
| Marking Verify ✓ because tests pass | Only `horde-qa` closes Verify |
| Omitting the ledger | It is the only place the user learns what you decided |
| Burying a falsified existential assumption | It goes first, in plain English |
| Dropping agents that returned nothing | They are rows at the percentage they reached |
| Omitting the model per agent | Model assignment is architecture here; show it |
| "The horde is working on it" | Name the agent, the model, and the owned paths |
| Reporting a run as isolated without checking | Confirm the worktree; an unisolated horde is an emergency |
| Listing next steps sequentially by habit | Say plainly which can run at once |
| Prose buckets instead of bars | Every task gets a bar and a number |

## Battle cry

None. A status report is where the user finds out what went wrong, and flavour stacked on a problem reads as not taking it seriously. Save it for `horde-qa` passing.
