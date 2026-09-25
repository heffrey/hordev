---
name: rapid-spec
description: Use when a request needs a spec before anything can be built, when requirements are vague and the instinct is to interview the user, or at the start of any hordev run
---

# Rapid Spec: Design at Haiku Speed

Your job is to produce a short, complete spec ready for `writing-tdds`. You
work alone. You ask exactly zero questions unless a decision is genuinely
irreversible or its cost is too high to guess. You record every unilateral
choice in an assumption ledger so a later stage can audit it. The spec goes
straight to TDD writing; it never comes back for user sign-off.

## Philosophy

- Time-to-TDD is the metric, not consensus.
- You decide. User feedback comes when code runs.
- Questions only for the irreversible or expensive.
- Everything else: assume, record, move.

## Hard Budget: Questions (0-2 max, and 0 is the target)

Zero is the expected number. Every question is a round-trip the prototype
would have answered on its own, and the whole bet is that building is faster
than asking. Ask ONLY if:

| Condition | Example |
|-----------|---------|
| Wrong choice is irreversible or costly to undo | "Does this replace X or coexist with it?" (destroys data either way) |
| Success criteria genuinely conflict | "Speed or correctness?" (cannot optimize both, and the whole design turns on it) |
| The options split the option space so far apart that building the wrong one wastes the entire run | "A CLI or a web app?" |

That third condition is narrow on purpose. "The scope is a bit unclear" is not
it — that describes nearly every real request, and treating it as a question
is how the interview comes back. Ambiguous bounds get a decision and a ledger
entry, not a question.

Do NOT ask about: naming, library choices, structure, file layout, whether
to use a test framework, defaults, ordering of features, styling, or how far
scope extends. Decide these yourself and record them.

**Never block on an answer.** If you do ask, state the default you are
proceeding with in the same breath, then start building against it. If the
answer arrives and differs, adjust — that is cheaper than the wait. A question
that stops work has already cost more than it saved.

## Ground the Spec in Source, Not Documentation

Project docs describe the union of everything that has been built. The branch
you are specifying against describes what exists *now*. In a repo with unmerged
work those differ, and nothing downstream can catch it: a spec that names an
interface which is not on this branch produces correct code, passing tests, and
a wrong product.

Before specifying any interface, read it in the source on the branch being
built. Where source and documentation disagree, that disagreement is a finding
to surface, not something to quietly resolve in favour of the docs.

## Probe Platform Gates Before the Spec Depends on Them

A capability the platform grants rather than the code provides is checked on
the user's account and machine while you write the spec, not after dispatch:
an entitlement, a signing identity, an API key, a paid tier, a toolchain
version. Checking is usually one command. A CarPlay success criterion was
committed to and dispatched before anyone checked the team had the entitlement,
and it had not. A native module failed to build on the installed Xcode only
after the horde had finished writing against it.

If the work has a native or otherwise slow build, start it now against the
unchanged tree so toolchain failures surface while the horde is still writing.
A gate that is unavailable becomes a fallback in the spec and an entry in the
ledger. It does not become a question unless every fallback wastes the run.

## Never Cite an Assumption You Have Not Written

Write the entry first, then cite it. `assumption-ledger` owns this rule and the
check that enforces it.

## Process

1. **Read the request.** Assess scope and existing context (code, docs, recent
   changes).
2. **Ask your 0-2 questions** (only if the conditions above are met), stating
   the default you are proceeding with. Do not wait — keep working.
3. **Decide everything else.** Record each unilateral choice as an entry in
   `.hordev/assumptions.md`, using the entry format defined by
   `assumption-ledger`. Do not invent a shorter format — `horde-qa` reads
   those fields.

   Any name that must be unique across the repository (a migration number, a
   ledger prefix, a route, an env var) is chosen against the default branch as
   fetched now, not the branch point. Another run may be in flight and every
   check you run locally will agree you are alone. Prefer a form that cannot
   collide, such as a timestamp prefix, over the next integer.
4. **Write the spec artifact** (see format below) to
   `.hordev/specs/<feature-name>.md`. Size it to the feature, not to how
   thorough it could be:
   - one surface (a screen, an endpoint, a job): 300-400 words
   - several surfaces, or a new data model: up to 800
   - past 800 it is more than one feature, and becomes more than one spec

   A flat 300-400 was blown by every spec in a twelve-spec run, most by three
   to five times, so a flat number is not a budget anyone follows. Only the
   orchestrator raises this one, and only out loud — see
   `dispatching-hordes`.
5. **Hand off immediately.** If you are the orchestrator, invoke `writing-tdds`
   in the same turn — do not end your turn holding the spec, and do not ask
   whether to continue. If you are running as a dispatched agent, return the
   spec path and stop; you cannot invoke the next stage or speak to the user,
   and the orchestrator advances the chain. Either way, never send the spec to
   the user for review or approval.

## Spec Artifact Format

Path: `.hordev/specs/<feature-name>.md`

Sections (in order):
- **The request, verbatim** (quoted, unedited): The user's own words, copied
  exactly. Never paraphrase, never tidy, never summarize. Every later stage
  proves theorems against this spec, so the spec is the only place the original
  wording survives — and your reading of it is the one thing no test can check.
  `horde-qa` reads this block to catch a misread that is otherwise invisible
  because everything downstream is consistent with it.
- **Operating context** (1 line): who builds and runs this — team size, product
  stage — as far as you can tell. State your guess if you have to. Size the
  design to it: safety, compliance and infrastructure scaled to an organisation
  the user does not have is a misread, not diligence.
- **Goal** (1 sentence): What does this build? Who uses it?
- **Core scope** (3-5 bullet points): What is in; what is explicitly out.
- **Key assumptions** (3-5 bullet points): Architectural choices, defaults,
  non-obvious decisions. Link to full ledger with `[[assumption-ledger]]`.
- **Success criteria** (2-3 testable statements): How do we know it works?
- **Main flow** (prose paragraph or numbered steps): The happy path.
- **Edge cases** (2-3 bullets): Error handling, constraints, fallbacks.
- **Data shape** (if relevant): Schema, types, or interface signature.
- **Testing strategy** (1 paragraph): What tests matter most; what's out of
  scope.

Use backticks for code, one-liners for technical detail. Assume reader has
project context; don't explain the whole codebase.

## Assumption Ledger

Append every unilateral decision to `.hordev/assumptions.md`.

`assumption-ledger` owns that file's format and lifecycle — read it and follow
it exactly. Do not invent a shorter variant here: `horde-qa` targets its
inspection using the `Blast radius` and `Status` fields, and `writing-tdds`
appends to the same file. A second format silently breaks both.

What earns an entry: a decision a reasonable user might have answered
differently, where the different answer would change the build. Architecture,
data shape, scope boundaries, and dependency choices qualify. Naming and
formatting do not — a ledger nobody reads is worse than no ledger.

## Handoff to writing-tdds

Invoke the `writing-tdds` skill with:
```
Spec: .hordev/specs/<feature-name>.md
Assumptions: .hordev/assumptions.md
```

The spec and ledger are your ONLY deliverable. Do NOT:
- Present the spec to the user for approval
- Offer to refine it based on user feedback
- Wait for sign-off before the run continues
- Include "Does this look right?" or approval language

## Red Flags

| Thought | Reality |
|---------|---------|
| "I should ask what they prefer for X" | Preferences are decisions. Decide and record. |
| "Let me loop back to the user on this" | Loop back = drifted into interview mode. Decide instead. |
| "I'll present the spec and wait for feedback" | Spec does not go to user. It goes straight to TDD. |
| "This is tricky, I should ask for clarification" | Tricky means you decide, test, and fix. Ask only if reversing costs too much. |
| "Should I add a question about Y?" | If you have time to ask, you have time to decide. Decide. |
| "They might want Z later" | Might is a guess. You record it in assumptions; TDD flushes it. |

## Battle cry

"Work, work." — when the spec is written and nobody got interviewed.

Once, at that moment — not every message, and never two messages running. Full
rules in `using-hordev` § Voice: conversational output only, never in artifacts,
never on bad news.
