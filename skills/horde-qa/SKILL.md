---
name: horde-qa
description: Use after reconciling-horde-output leaves a tree that builds and passes its tests, before telling the user anything is done, or whenever you are about to write "tests pass", "working", or "complete" about horde output
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

**Question 0, and you run it first: was the spec right?**

Q1 and Q2 are a closed loop. The TDD is checked against the spec, the code is
checked against the TDD — and if the spec misread what the user wanted, every
one of those checks passes and the prototype is confidently wrong. Nothing else
in the pipeline can catch this, because everything downstream is *consistent*
with the misread.

So start here, before running anything:

1. Read **The request, verbatim** at the top of `.hordev/specs/<feature-name>.md`.
   The user's own words, not your summary of them.
2. Read the spec's Goal and Core scope directly against it.
3. Ask: would the person who wrote that request recognize this as what they
   asked for? Is anything they said missing? Is anything here that they never
   asked for?

A mismatch is not a test failure and no amount of green suite hides it.
Escalate to `rapid-spec` with the specific words that were misread.

Do not skip this because the tests pass. Passing tests prove the code matches
the TDD; they say nothing about whether the TDD was aimed at the right target.

All three must pass. Q0 failure means the run was aimed wrong. Q1 failure means
an agent didn't finish. Q2 failure means the design was wrong all along.

**No TDD, because Design was skipped:** Q1 and Q2 collapse into one question —
does the code do what the spec says? Check it against the spec's success
criteria and edge cases directly, and skip checklist step 4. Say plainly in the
report that the code was verified against the spec alone. That is weaker: no
test was written from the spec before the code existed, so the suite tests what
the agents built, not what was asked for.

## Verifying at Horde Scale

Cheapest invalidation first: the suite (checklist 0-2), then the real path
(3), then the design (4-5). Zero passing tests means no runnable code; stop.

**Inspect fast.** Don't re-read all implementation. Target:
- Files where agent returned suspiciously terse or fast responses
- Seams between modules (agent may have stubbed integration)
- Code marked "TODO" or "FIXME"
- Anything the TDD called an assumption

## Checklist (in order)

0. **The suite actually executes, as the right user.** Before reading any
   result, confirm the suite ran at all and ran with the privileges of the thing
   it claims to test. A planned-35/ran-4 is not "mostly passing", it is a suite
   that aborted. Worse, a security suite executed as a superuser bypasses the
   very policies it asserts and can go fully green while testing nothing.
   - Compare planned assertions against executed assertions; a gap is a failure.
   - For any authorization or permission test, verify the role in effect.
   - STOP if the suite has never been executed. Untested test code is not
     evidence, and its bugs mask exactly the controls it was written to prove.

1. **Tests exist and run:** `npm test` or equivalent — **the project's own
   command, named in the dispatch prompt**, not one the agent chose. Exit code
   0? Count pass/fail. Run it yourself; an agent's report is a claim.
   - STOP if exit code nonzero. Escalate: agent didn't finish.

1b. **Content-heavy data has invariant tests, not just function tests.** A
   lexicon shipped with four duplicate object keys and a fully green suite,
   because the tests exercised the function that reads the data and never the
   data itself. For any task whose deliverable is largely a data structure,
   require an invariant test over the structure — uniqueness, no cross-entry
   contradictions, expected cardinality.

2. **Tests assert, don't stub:** Read test output and code. Are assertions
   meaningful or do they just check `x !== null`?
   - STOP if most tests are no-op stubs. Re-dispatch with `writing-tdds`.
   - Read every test whose comment explains why a surprising result is correct.
     That comment marks where the author noticed something odd and argued past
     it. Check the assertion against the spec, not the implementation. A green
     test can assert the bug, and then fixing the bug "breaks a test".
   - For a function that classifies external input, run it on the input as it
     actually occurs (stored rows, captured requests), not only on the TDD's
     examples.

3. **The real path, observed in the real runtime.** Required, never inferred
   from the steps above. Green-but-broken is the largest failure class in
   hordev's history. In one run, with typecheck, lint, tests and build green
   throughout: a second app shipped unstyled because its CSS pipeline never
   compiled; analytics went to a regional host that answers HTTP 200 and
   discards the event; session replay loaded despite autocapture being off;
   sign-in failed with a bare 500 from NULL columns in seed data; a magic link
   redirected to the wrong app; a no-JavaScript form posted urlencoded to a
   JSON-only parser. Each was visible within a minute of using the thing.
   - Run it where users run it: a browser with the network panel open, `curl`
     against the running server, a real sign-in. Put the observation in the
     report — the command and what it printed, the request and its status.
     "Works" with no observation is a claim.
   - **Name the negative control.** For each critical claim, write down the
     observation that would differ if the feature were broken, and check that
     one. "No errors" is never it: analytics that sends nothing has no errors.
     The control is the event arriving at the ingest host; a computed style on
     a real element; the request a privacy guarantee says must not appear. A
     suite whose result is the same whether the feature works or does nothing
     does not cover the feature — an analytics allowlist suite passed whether
     or not a single event was ever sent.
   - STOP if core path breaks. Fix and verify.
   - "There is no runnable path" is not an answer until you have priced a
     synthetic client (a scripted HTTP caller, a software authenticator, a fake
     webhook sender). If it costs under an hour, build it.
   - When a defect is found mid-run, grep for every other instance of the same
     class before fixing the one. The first fix makes the class look handled.

4. **TDD matches spec:** Line-by-line. For each requirement in spec, TDD tests
   it or explicitly assumes it won't be tested.
   - If silent gap: check prototype handles it. If not, escalate to `rapid-spec`.

5. **Assumptions hold:** Open the TDD and the spec together. For each
   assumption the TDD lists, verify the spec makes it or the prototype handles
   it safely.
   - If assumption was wrong, escalate to `rapid-spec`.
   - For every entry that names a risk and a mitigation, list each branch the
     mitigation can take, including the one where it fires on a legitimate
     user, and confirm each was executed. A mitigation verified only in the
     case it was designed for is unverified.
   - For any harness you built, write down which real user it cannot simulate,
     and cover that user.

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
| Verified | "21/21 passing" | Re-run with the project's command; a true claim under a runner the agent chose proves nothing |
| Exact count | "157 canonical entries" | Count it yourself; there were 156, and the agent had no way to notice |
| Build is clean | "Build succeeds" | Look at it running (step 3); a build passes with the styling pipeline inert |
| Found a problem | "Encoding issues" | Reproduce it before acting on it; a confident false alarm sends QA the wrong way |
| Obeyed prohibitions | "No git commands run" | Check `git reflog` and the index; an agent that ran git and unwound it can still say this |

## What to Do on Failure

**Tests fail (Q1):**
- Bug in code: Fix, re-run, re-verify. Then do Q2.
- Bug in test: Fix test, re-run. If test still fails, escalate to agent.
- Test too weak: Strengthen, re-run. If still passes, escalate to `writing-tdds`.

**TDD wrong (Q2):**
- Requirement is in the spec but the TDD dropped it: escalate to
  `writing-tdds`. The spec is fine; the design lost something. Do NOT let an
  agent add tests post-hoc.
- Requirement is missing from the spec too: escalate to `rapid-spec`. Spec
  fixed first, then TDD rewritten.
- Assumption falsified: escalate to `rapid-spec` if its blast radius is large
  enough to change the spec; otherwise mark it `falsified` in
  `.hordev/assumptions.md` and fix forward.
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

### This report ends the run

Nobody approved the spec or the TDD, so this is where the user finds out what
was decided for them. Your report is the run's final output and must carry
three things:

1. **Verification results** — what you ran, what it said, what you did not check.
2. **Open assumptions** from `.hordev/assumptions.md`, highest blast radius
   first, in the format `assumption-ledger` defines. Never omit these because
   the tests passed; a passing suite proves the code matches the TDD, not that
   the assumptions behind it were right.
3. **The branch** the work is on, so the user can review or discard it whole —
   one per repository when the run spans more than one (see
   `isolating-horde-workspaces`).

Do not merge, push, or delete the branch. Hand it over and let the user decide.

## Feeding Systemic Issues

When you see a pattern (not one-off bug):
- All agents left TODOs
- All agents weakened tests until they passed
- All agents stubbed same integration point

Log it to `.hordev/run-log.md` with `COST: systemic`: what pattern, which
agents, which files, and the hypothesis about why it happened (spec unclear?
TDD bad? agents coordinating wrong?). `improving-hordev` reads that log after
the run ends. Do not edit a skill mid-run, and do not amend one yourself.
Dispatching the **Reflect** stage after your report is now the orchestrator's
job (see `using-hordev`); what it returns is a proposal, not a change.

Do NOT leave systemic issues unreported. They will cascade to next horde run.

## Log what went wrong

Append an entry to `.hordev/run-log.md` (format in `improving-hordev`)
for every defect that escaped reconciliation, every assumption falsified here,
and every case where the TDD itself was wrong. These are the entries that
matter most: they are where hordev's speed bet lost, and they are exactly what
the library needs to learn from rather than quietly delete.

## Battle cry

"Lok'tar!" — **only when QA passes.** A failing report gets no flavor at all:
it is the one moment in the run where the user has to act on what you found.

Once, at that moment — not every message, and never two messages running. Full
rules in `using-hordev` § Voice: conversational output only, never in artifacts,
never on bad news.
