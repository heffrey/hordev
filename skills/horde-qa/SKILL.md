---
name: horde-qa
description: Use when reviewing work from multiple horde agents before claiming completion - QA is the only gate standing between wrong design and wrong prototype
---

# Horde QA

**Core principle:** Evidence before assertions, at horde scale. hordev removed
user approval gates on specs and TDDs, so QA alone stands between wrong design
and wrong prototype.

## The Iron Law for Horde Work

```
NO COMPLETION CLAIMS WITHOUT:
(1) Fresh test runs confirming code matches TDD
(2) Evidence the TDD was actually correct
```

Cheap agents will cut corners. Your job catches them before they compound.

## Two Distinct Questions

**Question 1: Does the code do what the TDD says?**
- Run the tests. Read the output. Count failures.
- Has test assertions, not stubs.
- Passes all cases the TDD required.

**Question 2: Was the TDD itself right?**
- Nobody approved it. Verify against the spec.
- Exercise the actual user-facing path (don't just read code).
- Check if the TDD silently dropped any requirements.
- Look for assumptions the spec didn't make.

Both must pass. Q1 failure means agent didn't finish. Q2 failure means design
was wrong all along.

## Verifying at Horde Scale

Cheap-invalidating-first: run tests first, then target inspection.

**Run tests immediately.** 0 pass = agent didn't write runnable code. Stop.

**Inspect fast.** Don't re-read all implementation. Target:
- Files where agent returned suspiciously terse or fast responses
- Seams between modules (agent may have stubbed integration)
- Code marked "TODO" or "FIXME"
- Anything the TDD called an assumption

**Exercise the actual path.** Don't trust README examples. Start the app, click
the button, enter real data. Run the tool end-to-end the way users will.

**Check TDD assumptions against spec.** Open both files. For each assumption
the TDD listed, verify the spec actually makes that assumption. If the spec
doesn't mention it, check it against the prototype.

## Checklist (in order)

1. **Tests exist and run:** `npm test` or equivalent. Exit code 0? Count pass/fail.
   - STOP if exit code nonzero. Escalate: agent didn't finish.

2. **Tests assert, don't stub:** Read test output and code. Are assertions
   meaningful or do they just check `x !== null`?
   - STOP if most tests are no-op stubs. Re-dispatch with `writing-tdds`.

3. **User path works:** Actual application start, real interaction.
   - STOP if core path breaks. Fix and verify.

4. **TDD matches spec:** Line-by-line. For each requirement in spec, TDD tests
   it or explicitly assumes it won't be tested.
   - If silent gap: check prototype handles it. If not, escalate to `rapid-spec`.

5. **Assumptions hold:** For each assumption in TDD, verify spec makes it or
   prototype handles it safely.
   - If assumption was wrong, escalate to `rapid-spec`.

6. **No stubs left:** Grep for TODO, FIXME, stub, skip, xtest, xit. Escalate
   any agent claimed as finished.

## Specific Lies Cheap Agents Tell

| Lie | Tell | How to Catch |
|-----|------|-------------|
| Tests pass | "All tests green" | Run tests yourself, read raw output |
| Code complete | "Implementation done" | Grep for TODO/FIXME, exercise path |
| Requirements met | "Task 3 done" | Line-by-line TDD vs spec |
| Assumption checked | "Per TDD" | Verify against spec, not TDD |
| Tests meaningful | "94% pass rate" | Read assertions, not count |
| Integration works | "Modules integrated" | Run real workflow, not unit tests |

## What to Do on Failure

**Tests fail (Q1):**
- Bug in code: Fix, re-run, re-verify. Then do Q2.
- Bug in test: Fix test, re-run. If test still fails, escalate to agent.
- Test too weak: Strengthen, re-run. If still passes, escalate to `writing-tdds`.

**TDD wrong (Q2):**
- TDD missed requirement: Escalate to `rapid-spec`. Do NOT let agent add tests
  post-hoc. Spec must be fixed, TDD rewritten.
- Assumption false: Escalate to `rapid-spec`.
- Prototype doesn't handle: Fix prototype, re-run tests.

**Systemic pattern (e.g., all agents stubbing):** Feed to `improving-hordev`
with specifics: which agents, which files, which pattern.

## Reporting

State what you ran. State what it said. State what passed and what didn't.

```
✅ Tests pass: 34/34 (exit 0)
✅ User path: Start app, click [Search], enter "test", results load
❌ TDD assumed no auth required; spec requires API key
   Escalated to rapid-spec

Result: PASS with caveat (spec revision needed before merge)
```

Never claim completion without listing what you verified and what you didn't.
If you skipped a step, say which and why (e.g., "No user-facing path in library
code, Q1 only").

## Feeding Systemic Issues

When you see a pattern (not one-off bug):
- All agents left TODOs
- All agents weakened tests until they passed
- All agents stubbed same integration point

Dispatch to `improving-hordev` with: what pattern, which agents, which files,
and the hypothesis about why it happened (spec unclear? TDD bad? agents
coordinating wrong?).

Do NOT leave systemic issues unreported. They will cascade to next horde run.
