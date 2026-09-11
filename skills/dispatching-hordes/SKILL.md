---
name: dispatching-hordes
description: Use when a decomposed task list with file ownership is ready and agents need launching, or when a dispatched agent times out, returns a plan instead of code, fails its tests, or reports BLOCKED
---

# Dispatching Hordes

**The core principle:** Launch all independent agents in ONE message with multiple tool calls. Sequential dispatch is the failure mode.

Hordes use cheap, fast agents (haiku) working in parallel. Each agent owns one task: write this code, pass these tests, deliver this report. No agent sees the conversation. You construct exactly what each needs and let them run.

## When to Use

- Multiple independent implementation tasks from a decomposed plan
- You have a spec; agents write code, not plans
- Speed matters more than review-gate lateness
- Agents run 5+ minutes in parallel; sequential dispatch wastes wall-clock

Do NOT use hordes when tasks are tightly coupled or agents need live back-and-forth.

## The Prompt Contract

An agent cannot ask you anything, cannot see the conversation, and will do
exactly what the prompt supports — including things it supports by accident.
Every item below is load-bearing.

1. **The task.** One sentence. What does this agent own?
2. **Input.** Exactly which files exist, and what earlier agents produced that
   this one consumes.
3. **Output.** Which files it creates or modifies. Name them exactly. This is
   its write surface and nothing else is.
4. **What passing looks like.** Paste real test names, expected values, edge
   cases. Never "make the tests pass".
5. **The verification command, verbatim, with raw output required.** See below —
   this is the item most often left implicit and it is the one that fails
   silently.
6. **Acceptance.** Hard stops. "Deliver X, or report BLOCKED."
7. **Style bar.** Match the surrounding code: indentation, naming, comment
   density.
8. **Write, do not plan.** "Implement the code directly. Do not write a plan."
9. **Worktree path.** From `isolating-horde-workspaces`. Without it the agent
   edits the user's checkout.
10. **Open assumptions.** The IDs and `Decided` lines from
    `.hordev/assumptions.md` bearing on this component. An agent that does not
    know what was assumed will contradict it. Only cite IDs that exist.
11. **Prohibitions, stated twice** — once where they belong and once in the
    closing lines. See below.

### 5, expanded: name the command, demand the output

State the exact command and require the agent to paste what it printed.

An agent left to choose its own verification will choose one that works for it.
One reported "21/21 passing" under `npx tsx --test`; the suite had never
executed under the project's `node --test`, because the two resolve imports
differently. The claim was true and worthless, and typecheck and build were
green the whole time.

"Verify it works" is not a contract. `npm run lint && node --test src/x.test.ts`
is. The same goes for build and typecheck. Requiring raw output matters as much
as naming the command: a summary is the agent's reading of the result, and the
reading is the part that goes wrong.

`horde-qa` then re-runs *that* command, not whichever one came back in the
report.

### 11, expanded: prohibitions bracket the prompt

An agent that starts acting before it finishes reading will break a rule it has
not reached yet. One told plainly not to run git ran `git rm` and `git commit`,
found the instruction afterwards, and had to unwind its own commit.

Put every prohibition in the closing lines as well as wherever it naturally
belongs. It costs three lines and it survives an agent that reads in order.

**Skeleton prompt:**

```
TASK: Implement Widget.authorize() to approve pending transactions over $100.

INPUT:
- src/widget.ts (exists; Widget class, empty authorize() stub)
- test/widget.test.ts (exists; tests commented out, awaiting your implementation)
- src/transaction.ts (from an earlier agent; Transaction, .isOver(n), .approve())

OUTPUT — your entire write surface:
- src/widget.ts
- test/widget.test.ts
Touch nothing else.

WHAT PASSING LOOKS LIKE:
1. "approves transactions over $100" — approve() called on each amount > 100
2. "skips transactions under $100" — approve() not called on smaller ones
3. "handles empty transaction list" — no error on an empty list
4. "returns count of approved" — returns the number approved

VERIFY WITH EXACTLY THIS, AND PASTE THE RAW OUTPUT:
    npx tsc --noEmit -p tsconfig.json && node --test test/widget.test.ts
Do not substitute another runner. If it does not pass, say so and say why —
do not weaken a test to make it green.

ACCEPTANCE:
- All 4 tests pass under the command above
- No TypeScript errors
- authorize() does not modify the Transaction class

STYLE: existing naming (camelCase, no prefixes), JSDoc on public methods,
match the indentation of the Widget class.

WORKTREE: .claude/worktrees/horde-1730000000
Work only inside this directory.

OPEN ASSUMPTIONS (do not contradict):
- A-002: Transaction amounts are integer cents, never floats.
- A-007: No auth on internal endpoints for the prototype.

Implement directly. Do not write a plan. Write the code.

DO NOT: run any git command. Commit. Touch files outside OUTPUT above.
Substitute your own verification command.
```

## Say Who Commits

**Agents write files. The orchestrator commits.** State this in every prompt.

An agent left to its own judgment will often commit its work. When a dozen of
them do that at once they are racing on one git index and one lockfile, and the
history comes back interleaved and half-attributed. Nothing about file
ownership protects the index — it is shared state that file-level disjointness
does not cover.

The orchestrator commits once, after `reconciling-horde-output`, when the tree
is coherent. If an agent genuinely needs its own history, it needs its own
worktree — see `isolating-horde-workspaces`.

## Always Set Model Explicitly

```typescript
Agent({
  model: "haiku",  // Always set; never inherit session default
  prompt: "..."
})
```

- **Haiku:** Implementation tasks (write code, pass tests). Mechanical work with clear specs
- **Opus:** Orchestration, reconciliation, decomposition (NOT dispatched; you do it)

Never omit `model`. Inheriting your session default defeats cost and speed.

## Horde Sizing and Waves

**Wave 1:** Launch all tasks with no dependencies in parallel — 5-20 agents at once is normal.

**Wave 2+:** After Wave 1 completes, launch tasks that consume Wave 1 output. Waves ensure dependency ordering without losing parallelism.

**Deciding batch size:**
- 5-10 agents: small features, quick dispatch → launch all at once
- 10-20 agents: moderate decomposition → launch all at once
- 20+ agents: large hordes → consider 2-3 waves if memory/token limits become real

A single wave of 50 independent agents is fine. Sequential dispatch of 5 agents (one per response) is wasteful.

## Failure Handling

**Agent returns nothing / times out:** Re-dispatch with same prompt to a fresh agent. If it happens twice, something is wrong with the prompt (missing context, unclear task). Fix the prompt and re-dispatch.

**Agent returns a plan instead of code:** It misread "write code, not a plan." Re-dispatch with this addition: "You are writing the code directly, not describing what to do. Paste the complete implementation."

**Agent returns code but tests fail:** Two routes:
  1. **Output incomplete:** Agent stopped mid-task. Re-dispatch to a fresh agent, marking URGENT
  2. **Logic bug:** Agent's code has a real defect. Cheaper to re-dispatch to fresh agent than loop — each agent gets one shot

**Agent reports BLOCKED:** Assess the blocker. Is it missing context, or is the task mis-specified? Provide context or amend the prompt, then re-dispatch.

**Agent reports uncertainty:** Re-dispatch with more concrete examples or constraints. "I'm not sure which approach" means your spec is ambiguous, not that the agent is uncertain.

## What You Do While the Horde Runs

Do NOT idle-poll. Use dispatch time to:

1. **Prepare reconciliation:** Sketch what success looks like. Are there files that must be merged? Interfaces that must align? Globals that agents might conflict over?
2. **Stage Wave 2:** While Wave 1 runs, write Wave 2 prompts and stage their dependencies
3. **Read agent feedback logs:** Some agents report concerns or warnings; collect them
4. **Prepare QA script:** What's the one test that verifies the whole feature? Write it now (don't run it yet)

When agents finish, you're ready to reconcile immediately instead of re-deriving context.

## Re-dispatch Rules

**Re-dispatch only once per agent** in the normal case. If an agent fails, one retry to a fresh agent usually finds the real issue (unclear prompt, missing context, timing bug). Two failures on the same task → the task itself is malformed. Stop, inspect the spec, fix it, and re-dispatch to a single agent with the amended prompt.

**Batch re-dispatches:** If 3 agents fail on the same kind of error, fix the prompt once and re-dispatch all 3 at once to fresh agents (not sequential retries).

## Handoff to Reconciliation

When all agents report completion (or failures you've ruled as non-blocking), move to `reconciling-horde-output`. Pass:

- List of agents and the files each one wrote
- Reconciliation checklist you prepared (file merges, interface validation)
- Any concerns agents flagged
- Wave success rate (e.g., "23/25 agents completed; 2 re-dispatched")

Do not attempt to merge or test here. Reconciliation handles conflict detection and full-suite verification.

## Metrics

- **Time to code:** Count wall-clock from dispatch to all agents complete
- **Cost:** Haiku × agent-count × 1-2 turns per agent
- **Re-dispatch rate:** Target <10% (failures indicate spec or decomposition issues, not agent capability)
- **Convergence:** All agents done within 2-3 minutes; outliers block downstream waves

## Example: Decomposed Feature (3 Waves)

**Wave 1 (5 agents, parallel):**
- Agent A: Implement data model (types, validation)
- Agent B: Write database layer (CRUD)
- Agent C: Build API endpoint (route, auth, parsing)
- Agent D: Add error handling middleware
- Agent E: Write integration tests

**Wave 2 (3 agents, after Wave 1 complete):**
- Agent F: Connect API to DB layer (consumes B, C output)
- Agent G: Add caching layer (consumes B output)
- Agent H: Write CLI tool (consumes A output)

**There is no Wave 3.** Reconciliation and QA are not dispatched. When
Wave 2 returns you run `reconciling-horde-output`, then `horde-qa`,
yourself on `opus`. Dispatching either to a cheap agent means nothing is
checking the design — see `using-hordev`.

Dispatch Wave 1 now. Stage Wave 2 prompts while Wave 1 runs.

## Log what went wrong

Append a 4-field entry to `.hordev/run-log.md` (format in `improving-hordev`)
whenever an agent returns nothing, returns a plan instead of code, reports
BLOCKED, or has to be re-dispatched. Note the re-dispatch rate for the run.

Nothing else writes this. If you skip it, `improving-hordev` has nothing to
learn from and the library stops improving.

## Battle cry

"For the Horde!" — when the wave goes out. "Lok'tar ogar!" and "Blood and
thunder!" serve the same moment.

Once, at that moment — not every message, and never two messages running. Full
rules in `using-hordev` § Voice: conversational output only, never in artifacts,
never on bad news.
