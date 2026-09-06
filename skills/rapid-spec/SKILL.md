---
name: rapid-spec
description: Use when turning a request into a spec before implementation. Replaces superpowers' brainstorming with speed-first design that minimizes user questions, decides unilaterally, and records assumptions.
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

## Hard Budget: Questions (0-2 max)

Ask ONLY if:

| Condition | Example |
|-----------|---------|
| Decision is irreversible or costly to undo | "Does this replace X or coexist with it?" (architectural fork) |
| Success criteria conflict | "Does this prioritize speed or correctness?" (can't optimize both) |
| Scope is genuinely ambiguous from the request | "Should this handle Y or stop at X?" (bounds aren't clear) |

Do NOT ask about: naming, library choices, structure, file layout, whether
to use a test framework, defaults, ordering of features, or styling. Decide
these yourself and record them.

## Process

1. **Read the request.** Assess scope and existing context (code, docs, recent
   changes).
2. **Ask your 0-2 questions** (only if conditions above are met). Wait for
   answers.
3. **Decide everything else.** For each unilateral choice, write one line in
   the assumption ledger: `- [category] decision: reasoning.`
4. **Write the spec artifact** (see format below) to the file path you
   determine. It is short enough for one pass (~300-400 words total).
5. **Hand off.** Invoke `writing-tdds` with the spec path. Do NOT send the
   spec to the user for review or approval.

## Spec Artifact Format

Path: `.claude/specs/[YYYYMMDD]-[slug].md`

Sections (in order):
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

Write one file: `.claude/assumptions/[spec-slug]-assumptions.md`

Format:
```
# Assumptions for [Spec Slug]

[Brief statement of the request, to orient later readers]

## Decisions Made Unilaterally

- [category] **decision**: reasoning. (link to spec section if relevant)
- [category] **decision**: reasoning.
```

Categories: architecture, naming, scope, ui/ux, performance, testing,
libraries, defaults, ordering.

Example:
```
- naming **API route is /api/posts/batch**: singular "post" for single
  resource, plural "posts" for bulk; POST method. (See spec: Main flow)
- scope **Pagination starts at v2**: v1 assumes small dataset; added to
  assumptions for future. (See spec: Core scope)
- libraries **Use node:crypto, not tweetnacl**: stdlib is faster, audited
  by Node team, no extra deps. (See spec: Data shape)
```

## Handoff to writing-tdds

Invoke the `writing-tdds` skill with:
```
Spec: /path/to/spec.md
Assumptions: /path/to/assumptions.md
```

The spec and ledger are your ONLY deliverable. Do NOT:
- Present the spec to the user for approval
- Offer to refine it based on user feedback
- Wait for sign-off before invoking writing-tdds
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
