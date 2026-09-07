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

Each agent gets a self-contained prompt with:

1. **The task:** One sentence. What does this agent own?
2. **Input files/dependencies:** Exactly which files exist; what earlier agents produced that this agent consumes
3. **Output files:** Which files does the agent create or modify? Name them exactly
4. **Test cases:** What must pass? Paste actual test expectations (test names, expected outputs, edge cases). No "make tests pass" — list what passing looks like
5. **Acceptance criteria:** Hard stops. "Deliver X, or report BLOCKED"
6. **Style bar:** Match the surrounding code (indent, naming, comment density)
7. **Explicit instruction to write, not plan:** "Implement the code directly. Do not write a plan. Write the code."
8. **Worktree path:** The horde's worktree from `isolating-horde-workspaces`. The agent works only there. Without it the agent edits the user's checkout.
9. **Open assumptions:** The IDs and `Decided` lines from `.hordev/assumptions.md` that bear on this component. An agent that does not know what was assumed will contradict it.

**Skeleton prompt:**

```
TASK: Implement Widget.authorize() to approve pending transactions over $100.

INPUT:
- src/widget.ts (exists; defines Widget class, has empty authorize() method stub)
- test/widget.test.ts (exists; tests are commented-out, await your implementation)
- Previous agent built src/transaction.ts (defines Transaction class, methods: .isOver(amount), .approve())

OUTPUT:
- src/widget.ts: Add authorize() implementation
- test/widget.test.ts: Uncomment and ensure all 4 tests pass

TEST CASES:
1. "approves transactions over $100" — calls approve() on each transaction with amount > 100
2. "skips transactions under $100" — does NOT call approve() on smaller transactions
3. "handles empty transaction list" — no error when no transactions exist
4. "returns count of approved" — returns number of approvals made

ACCEPTANCE:
- All 4 tests must pass
- No TypeScript errors
- authorize() must not modify Transaction class

STYLE:
- Use existing naming (camelCase, no prefixes)
- Add JSDoc for public methods
- Match indentation of Widget class

WORKTREE: .claude/worktrees/horde-1730000000
Work only inside this directory.

OPEN ASSUMPTIONS (do not contradict):
- A-002: Transaction amounts are integer cents, never floats.
- A-007: No auth on internal endpoints for the prototype.

Do not run git. Do not commit. Write the files and stop.

Implement directly. Do not write a plan. Write the code.
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
