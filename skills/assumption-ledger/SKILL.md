---
name: assumption-ledger
description: Use when logging decisions hordev made without asking the user, or reviewing open assumptions for falsification
---

# Assumption Ledger

hordev refuses to interview the user. But refusing to ask is only defensible
if every unanswered question becomes a logged, falsifiable assumption. An
undocumented guess is a bug; a logged assumption is a design decision.

## The Trade

When `rapid-spec` picks a detail instead of asking, that decision goes to the
ledger with:
- What was decided and why
- What alternative was rejected
- The blast radius: what would have to change if wrong
- How it will be falsified (test, prototype behavior, or user reaction)
- Current status (open, confirmed, falsified)

The ledger is visible to the user. It is the ONLY way they learn what was
decided for them. `horde-qa` targets inspection at open high-blast-radius
entries. Falsified assumptions with large blast radii send you back to
`rapid-spec`, not to patch around them.

## Ledger Format

**File**: `.hordev/assumptions.md` in the project root.

**Structure**: One assumption per entry. Fields are:

| Field        | Required | Content |
|--------------|----------|---------|
| ID           | yes      | `A-001`, `A-002`, etc. Immutable; status changes do not reassign IDs. |
| Decided      | yes      | What was chosen (e.g., "SQLite for persistence"). Terse. |
| Rationale    | yes      | Why in one sentence. If you need two sentences, it's underspecified. |
| Rejected     | yes      | The alternative not chosen. If none existed, write "None"; that signals an innovation, not a dodge. |
| Blast radius | yes      | What changes if wrong. One sentence. "Tiny" for cosmetic; "Large" for architecture; "Existential" if it invalidates the core proposition. See below — Existential is the one value that changes what you do. |
| Falsified by | yes      | How you will know this is wrong. Cite a test name, a prototype behavior, a specific user reaction, or "UAT". |
| Status       | yes      | `open`, `confirmed`, or `falsified`. |

**Example**:

```markdown
## A-001: Text-first UI, no drag-and-drop

Decided: No drag-and-drop gestures; editing happens via a command palette and
inline text.

Rationale: Command-driven flows are faster to prototype and test than gesture
recognizers.

Rejected: Drag-and-drop UI familiar from spreadsheets.

Blast radius: Medium — if users hate text-first input, we rebuild the whole
editing surface.

Falsified by: UAT feedback or "users prefer to drag" in session replays.

Status: open

---

## A-002: Fetch data on demand, no caching layer

Decided: Every query hits the API; no local cache.

Rationale: Caching complicates state, and we need to prove the core flow
works first.

Rejected: Redis cache with TTL.

Blast radius: Small — cache is an optimization added later, not a redesign.

Falsified by: If load tests show API latency exceeds SLA without cache.

Status: open
```

## What Earns an Entry

**Test**: Would a reasonable user have answered this differently, and would
that change the build?

- **Yes → Entry**. Example: `A-001` above. Users might demand drag-and-drop;
  we decided against it. That's an assumption.
- **No → Skip**. Example: Naming a button "Save" instead of "Submit". No
  reasonable user cares; it's not a decision, it's noise.

**Rule of thumb**: If `rapid-spec` had to guess at product shape, data model,
UX pattern, or performance strategy, log it. If it was just picking a word or
a color, ship it.

## Existential Entries Get Announced, Not Asked

Every other blast radius is logged and read at the end of the run. An
`Existential` entry — one that invalidates the core proposition if wrong — is
the exception, because discovering it at the end means the whole run was
wasted.

It still does not earn a question. hordev does not stop to ask, and waiting for
an answer costs more than the rebuild would. Instead, **say it once, in one
line, before dispatching the horde, and keep going**:

```
Assuming A-003: this is a CLI, not a service. Building on that now.
```

Then build. If the user corrects it, you have lost minutes rather than a run.
If they say nothing, you were right or they did not care — both fine.

This is the whole discipline in miniature: surface the bet, do not wait on it.

## Status Lifecycle

**open**: The assumption is live. The ledger mentions it, the user sees it, and
`horde-qa` may target it.

**confirmed**: Testing (unit test, prototype, or UAT) proved the assumption
sound. Do not remove the entry; mark it confirmed so the user knows this was
questioned and held up.

**falsified**: Testing proved the assumption wrong. Do NOT patch around it. If
blast radius is large, return to `rapid-spec` and replan. If tiny, update the
ledger and continue.

## Who Writes and Reads

- **Write**: `rapid-spec` logs entries when it picks. `writing-tdds` refines
  them as tests clarify the surface. Horde agents inherit relevant open
  assumptions in their prompts (tagged by component or layer).
- **Read**: `horde-qa` targets inspection at open entries with medium or large
  blast radius. The final report to the user lists all open assumptions,
  highest blast radius first.

## Surfacing to the User

At the end of each run, surface the ledger plainly:

```
## Assumptions Made

The following decisions were made without user approval:

**Large blast radius:**
- A-001: Text-first UI, no drag-and-drop [open]
- A-005: SQLite backend, not PostgreSQL [open]

**Medium blast radius:**
- A-002: Fetch on demand, no caching [open]

**Tiny/cosmetic:**
- A-003: Button label "Save", not "Submit" [open]

Review `.hordev/assumptions.md` for full details. If any assumption conflicts
with your intentions, reply with the ID (e.g., "A-001 is wrong") and the
intended behavior.
```

## Quick Reference: When to Log

✓ Data model shape (e.g., relational vs. document vs. key-value)
✓ Editing paradigm (e.g., modal dialogs vs. inline vs. command palette)
✓ Performance trade-off (e.g., caching vs. on-demand)
✓ Persistence strategy (e.g., SQLite vs. PostgreSQL vs. in-memory)
✓ Error handling posture (e.g., fail-fast vs. retry-with-backoff)

✗ Color, icon, or button label
✗ Whitespace or typography
✗ Ordinary naming of functions, variables, or files
✗ Choice between two equivalent implementations (if the user wouldn't care)
