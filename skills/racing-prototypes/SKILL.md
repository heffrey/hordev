---
name: racing-prototypes
description: Use when two or more approaches are plausible and argument cannot decide between them
---

# Racing Prototypes

## When to Race

Racing costs N×tokens to build N candidates. It earns that cost only when the approaches differ on something that cannot be settled by reading specs or code.

**Race when:** The approaches differ in a way argument alone won't settle — different architectures, different tech stacks, different scaling assumptions, or when users themselves do not know what experience they want.

**Do NOT race when:** One approach is clearly correct (wrong: "REST vs GraphQL, let's build both"). Differences are cosmetic (wrong: "dark theme vs light theme default"). Approaches only differ in details a single prototype would reveal (wrong: "button sizes, let's build two").

**Decision test:** If you can write down why the approaches matter differently and the answer depends on seeing them built and tested, race. If you can decide by editing the spec, commit to one.

## Choosing Candidates

Two to four candidates, no more. They must differ on the ONE axis in question; everything else stays the same.

**Good axis:** UI paradigm (modal vs inline vs sidebar). Persistence strategy (SQL vs document-store vs in-memory). Execution model (synchronous vs async). API shape (RPC vs REST-like vs event-based).

**Bad axis:** "Implementation language" (wrong — confuses stack with design). "Performance vs correctness" (wrong — both are required, not a choice). "Fast and loose vs robust" (wrong — prototype-first already handles this).

Set candidates side-by-side in writing before the race starts: what does each do differently, and what stays the same?

## Fair-Race Rules

- **Spec:** Every candidate gets the same feature spec. Use `rapid-spec` first; do not re-spec per candidate.
- **Acceptance tests:** Same test suite. Write them once, run all candidates against them.
- **Budget:** Same token count per candidate. Set it beforehand. If one reaches its limit first, it does not get more.
- **Thinness:** Every candidate follows `prototype-first` — no over-engineering, no premature abstractions. A race where one candidate optimized for scale while the others stayed thin teaches nothing.
- **Timeline:** Candidates run in parallel. Do not start the second after seeing the first.

## Isolation

Each candidate needs its own worktree. Use the `isolating-horde-workspaces` conventions — do not share checkouts or run code that might affect siblings.

Dispatch candidates as parallel agents with identical prompts that name only their candidate identity and the shared spec path.

## Judging

**Before racing:** Write down the criteria. Criteria must be observable from running the code, not from reading it. "Clean code" does not qualify. "Handles 10k events/sec" does; "smaller test suite" does not; "test suite runs in <2s" does.

| Criterion | Passes | Fails | How to measure |
|-----------|--------|-------|-----------------|
| Accepts spec | Yes/No | — | Do all tests pass? |
| No crashes | Yes/No | — | Run the acceptance test suite |
| (Custom criterion) | Threshold | — | (Observable outcome) |

**Judge on behavior, not code.** Run the candidates. Look at test results, timing, error handling. Do not judge on code style, test organization, or how "clean" the implementation looks.

**Ties:** If two candidates pass all criteria equally, pick the simpler one. "Simpler" means fewer dependencies, fewer moving parts, fewer files. If still tied, flip a coin; both work.

**All fail:** The spec was wrong or underspecified. Go back to `rapid-spec` before re-racing.

## Killing Losers

Delete the losing candidates' worktrees entirely. Do not cherry-pick pieces from multiple candidates into a hybrid. That produces something none of the candidates was and makes the race meaningless.

Record the winner and the decision in `.hordev/assumptions.md` (use `assumption-ledger` format). The entry should be: candidate ID, which axes differentiated them, which criteria favored the winner, and why it matters to the system. This is a decision the user never got asked about; assume-tracking makes it visible.

Example assumption entry:
```
ID: choose-ui-paradigm-sep-2026
Decided: modal-ui beat inline-ui on acceptability tests
Rationale: modals allow complex multi-step workflows; inline UX 
  hit token limit before passing acceptance tests
Rejected: inline-ui (failed tests), sidebar (untested)
Blast radius: UI architecture now locked; changing would need 
  refactor of state management
```

## Reporting

Show the user:
1. **What was raced:** The candidates and the axis they differed on.
2. **Criteria:** The pass/fail rules you defined.
3. **Results:** Test outcomes for each candidate. Include evidence: test runs, timing, error logs.
4. **Winner and why:** Which candidate won, on what evidence, and what decision this makes for the system going forward.
5. **Assumption logged:** Point to the entry in `.hordev/assumptions.md`.

## Red Flags

| Flag | What it means | What to do |
|------|---------------|-----------|
| Racing to avoid deciding | The axes are not real; you just wanted someone else to pick | Commit to one; use `rapid-spec` to settle the question |
| Cosmetic variants | Candidates only differ in UI polish, naming, or code style | Merge them; do not race |
| Favorite gets extra help | One candidate got more tokens, a head-start, or looser spec interpretation | Restart with fair rules or commit |
| Judging on aesthetics | Picking based on "this code is cleaner" or "I like this design better" | Re-judge on the criteria you wrote down. If criteria don't exist, the race was not fair |
| All succeed equally | Every candidate passed every test with no differentiation | The axes were not real. Commit to whichever is simplest or pick one. |
