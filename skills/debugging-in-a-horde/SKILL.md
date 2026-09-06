---
name: debugging-in-a-horde
description: Use when a bug appears in code written by parallel agents who never saw each other's work
---

# Debugging in a Horde

## Core Principle

**Root cause, not symptom. In horde output, 70% of bugs live at seams
between agents' files.** Read the error. Form one hypothesis. Test one
variable. Never guess.

## Why Horde Bugs Are Different

Multiple agents write concurrently. Each makes assumptions about interfaces,
contracts, and data shapes. When assumptions drift—Agent A expects
`items: array` but Agent B returns `items: object`—bugs surface at the
boundary, not inside either file.

**Seam bugs outnumber logic bugs 7:1 in parallel-authored code.**

## Triage Order: Fast Elimination

Before running tests, ask this sequence. It cuts wasted debugging time.

1. **Is it a skipped task?**
   - Check `.hordev/tasks.md`: did an agent mark this done when it wasn't?
   - Search the owning agent's file: does the code for this feature exist?
   - **If skipped:** dispatch the agent to do the work (don't fix).

2. **Is it a test that never asserted?**
   - Read the test completely. Does it actually verify the behavior?
   - Run test with verbose output. What did it check vs. what broke?
   - **If fake test:** fix test first, watch it fail real behavior, then fix
     behavior.

3. **Is it a seam mismatch?**
   - Find the file boundary where data enters/exits (JSON parse, function
     call, API response, file write).
   - Do both sides agree on the shape? Type, null-handling, key names?
   - Check assumption ledger: did agents assume differently here?
   - **If seam:** fix the contract (canonical interface), then update
     whoever got it wrong.

4. **Is it a logic bug inside one file?**
   - Reach this only after eliminating 1–3 above.
   - Reproduce reliably. Read the error stack completely. Form hypothesis
     about what line fails and why.
   - Change one thing. Verify.

## Check Assumptions Early

Before deep tracing, open `.hordev/assumptions.md`. A bug that looks like
bad code is often a falsified assumption:

- Agent A assumed "user IDs are strings"; Agent B generated numbers.
- Agent A assumed "config file exists"; Agent B never wrote it.
- Agent A built for Node 18; Agent B used Node 20 syntax.

**If assumptions differ, escalate to `rapid-spec`**—the decomposition was
incomplete. Don't patch it; fix the spec and re-dispatch.

## Parallelism Rules for Debugging

**DO NOT fan out a horde to test candidate fixes.** That is guessing at
scale. Hypothesis testing is sequential—one variable at a time.

**Parallelism IS good for:**
- Independently reproducing the bug (one agent per environment/data set).
- Gathering evidence from several suspect files (read call sites, trace
  data flow in parallel, report findings to one agent).
- Bisecting disjoint areas (if you suspect module A or module B broke,
  inspect both concurrently, report which one failed).

**Then:** one agent investigates the culprit sequentially.

## When to Fix In Place vs. Re-Dispatch

**Fix in place if:**
- Bug is inside one agent's file boundary.
- Root cause is clear (seam contract mismatch, logic error).
- Fix is small (< 10 lines).
- You understand the owning agent's original task fully.

**Re-dispatch the owning agent if:**
- The fix requires re-thinking the agent's design.
- Multiple pieces of the agent's output need rework.
- Assumption was falsified (agent didn't know the real requirement).
- You're unsure whether this is in scope for the original task.

Send the agent a message naming the file, the bug, root cause, and what to
fix. Include a test case that now fails. Let them fix it in context; they
understand their own reasoning better than you do after the fact.

## The Systematic Process

### Phase 1: Reproduce and Understand

1. **Read the error completely.** Stack trace, line numbers, actual vs.
   expected.
2. **Reproduce consistently.** Can you trigger it? Every time? With what
   data?
3. **Identify the seam.** Where does data cross a file/agent boundary?
   Suspect that first.
4. **Gather evidence:** Add logging at both sides of the seam. Run once.
   What data enters, what exits? Do they match the contract?

### Phase 2: Triage and Hypothesis

1. Run the elimination sequence above (skipped task → fake test → seam →
   logic).
2. Form one hypothesis: "Agent A returns `{id: "123"}` but Agent B expects
   `{id: 123}`."
3. State it clearly. Write it down.

### Phase 3: Test Minimally

1. Make the smallest change to test your hypothesis.
2. One variable at a time.
3. Does it work? Proceed to Phase 4. Didn't work? Form new hypothesis.

### Phase 4: Fix or Re-Dispatch

1. Decide: fix in place or re-dispatch (see rules above).
2. If fixing: create a failing test first, implement the fix, verify tests
   pass.
3. If re-dispatching: message the agent with file, bug, root cause, and
   test case.

## Red Flags — Stop and Re-Investigate

- "I'll just try changing X": You haven't formed a hypothesis.
- "Multiple changes at once": Can't isolate what worked.
- "This test passes but I think it's wrong": Read the test. It might be
  fake.
- "Probably a seam issue": Check assumption ledger. It might be a falsified
  spec.
- "One more fix" (after 2+ failures): Question the original task
  decomposition. Escalate to `improving-hordev`.

## Feeding Back to Improving-hordev

If the same seam bug recurs across runs (e.g., "JSON keys drift between
agents" or "agents miss each other's timestamps"), **don't just patch it**.
The bug is in the task decomposition, not the code.

Message `improving-hordev` with:
- What bug recurred (the pattern).
- Which seams keep breaking (file boundary, interface, data shape).
- What assumption or spec detail was missing.

Let the improvement agent tighten the skill that decomposed the work.
Recurring seams = broken decomposition.
