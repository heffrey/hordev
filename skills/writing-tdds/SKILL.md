---
name: writing-tdds
description: Use when a spec exists in .hordev/specs/ and no TDD exists for it yet, or when horde-qa sends a TDD back for a missed requirement or a weak test
---

# Writing TDDs (Test-Driven Designs)

## Overview

A TDD (Test-Driven Design) is a specification written as concrete test
cases. It bridges from `rapid-spec` to work a horde can execute in
parallel. Tests come first because with no approval gate between design
and build, the tests ARE the specification — they're the only thing that
can falsify the design.

**Do not ask for user approval of the TDD. Nothing in hordev is approved
before build — the spec was not either. Write, decide locally when
underdetermined, log assumptions, move forward.**

## TDD Artifact

Save to: `.hordev/tdds/<feature-name>.md`

```markdown
# Feature Name — TDD

**Spec:** `.hordev/specs/<feature-name>.md` (link to the
rapid-spec this designs)

## Scope & Constraints

[2-3 sentences on what this TDD covers and what it explicitly does NOT.
Mention platform, language, dependency constraints. Any global test
setup or tear-down that applies to all tests.]

## Tests

### Unit 1: [Behavior Name]

Given [initial state/inputs]
When [action taken]
Then [observable result]

[Test code as language-specific runnable test]

```python
def test_[behavior]():
    # setup
    given = ...
    # act
    result = function(given)
    # assert
    assert result == expected
```

[Repeat 3-8 tests per TDD depending on scope]

### Unit N: [Behavior Name]

[Same structure]

## Implementation Notes

[If spec was underdetermined on a decision point, log it here:
"Decided X because Y. See assumption-ledger entry <TAG>-001."]

[Any shared setup, fixtures, or test utilities needed across units.]
```

## Tests Define Behavior

Each test is a contract for implementation. A horde agent receives
the spec and this TDD — write tests to make behavior unambiguous.
Good test names are specific (test_retry_stops_after_3_attempts, not
test_retry_works). Concrete inputs, no mocks. One behavior per test.

**Include an input that separates the plausible wrong behavior from the
right one.** If every candidate implementation passes your examples, the suite
defines nothing. A classifier tested only on inputs where the naive rule and the
correct rule agree will lock in the naive rule.

**Cross every boundary in one test.** When a value crosses a serialization,
encoding, or protocol boundary, name at least one test that carries it across
the whole boundary in one pass: produced the way the real client produces it,
consumed by the real handler. Unit tests on each side do not count. A double
decode on one side and an encoded-form comparison on the other both pass their
own unit tests.

**Shape inputs like the real source.** For stateful or time-based behavior,
state the input model in one paragraph before the first unit: what a sample,
span or window means, and what it looks like when nothing happens. Then build
inputs the way the real source produces them. Stay detection passed on
synthetic 60-second samples and could never fire on a device, because
location updates filtered by distance send nothing while the user stands
still. A "does not change X" unit puts its input through the path that is
supposed to filter it; two units have inserted the very thing they then
asserted was absent.

**A failure is not an empty result.** Every unit that calls something external
has a test where the call fails, and the failure is observable as a failure:
an error, a status, a retry. A TDD that allows `[]` for both a failed lookup and
an empty one lets the implementation store a timeout as "nothing here".

**Calendar days are local.** Date logic uses one local-date helper named in the
TDD, never `new Date("YYYY-MM-DD")` or `toISOString().slice(0, 10)`, which are
UTC. Tests that depend on the day pin the clock and the time zone. An evening
run in US Central has flipped a hard-coded date test.

## Contracts Do Not Wait for the TDD

Only units whose behavior is genuinely ambiguous need a TDD. Units that need
only signatures, props, keys and file ownership go out on a contracts file the
orchestrator writes itself in minutes, and dispatch immediately. A stream once
sat behind a single TDD agent for 35 minutes while seven of its units needed
nothing but signatures. The TDD never gates a unit it does not test.

## Parallel-Safe Tests

Each test must run independently in any order. No mutable shared state,
no test interdependencies. If shared setup is needed beyond constants,
move it into each test's Given block.

## Right-Sizing

A TDD is done when a `haiku` agent can implement each test unit
independently without rereading the spec. Each unit should fit in
50-100 lines of code. Names and types must be exact. Edge cases must
be explicit in tests, not in implementation notes. If setup needs
a paragraph, the behavior is too coarse — split it.

## Handoff to Decomposing

After writing the TDD:

1. If you are the orchestrator, invoke `decomposing-for-hordes` in the same
   turn. Do not end your turn holding the TDD, and do not ask whether to
   proceed to decomposition — "say the word and I'll dispatch" is an approval
   gate hordev does not have. If you are a dispatched agent, return the TDD
   path and stop; you cannot advance the chain and the orchestrator does that.
2. The orchestrator runs `decomposing-for-hordes` to slice the TDD into
   independent tasks with one owner each, sets up isolation per
   `isolating-horde-workspaces`, then dispatches.
3. Agents write files only. The orchestrator commits after
   `reconciling-horde-output`, and `horde-qa` verifies.

Do not pause for approval or ask the user to review before dispatch.

## Underdetermined Spec

If the spec is ambiguous, decide locally and log the assumption:

1. Append an entry to `.hordev/assumptions.md` with fields:
   **ID, Decided, Rationale, Rejected, Blast radius, Falsified by,
   Status** (see `assumption-ledger` skill for format)

2. Reference it in "Implementation Notes": "Decided X because Y.
   See assumption-ledger entry <TAG>-NNN."

3. Write the test reflecting your decision.

Log assumptions when the decision surprises implementers or commits
to a closed path. Skip "I chose Python" — log design choices like
"in-memory cache vs Redis for lightweight prototype."

## Example: Pagination TDD

```markdown
# Pagination — TDD

**Spec:** `.hordev/specs/pagination.md`

Covers HTTP list endpoints with pagination (`limit` and `offset`
params). Does NOT cover sorting or filtering.

### Unit 1: Default Behavior

Given: 100 items
When: GET /items (no params)
Then: returns 10 items (default limit), starting at 0

```python
def test_default_page():
    items = [Item(i) for i in range(100)]
    result = list_items(items)
    assert len(result) == 10 and result[0].id == 0
```

### Unit 2: Boundary Condition

Given: 100 items, offset=95, limit=10
When: GET /items?offset=95&limit=10
Then: returns 5 items (95-99)

```python
def test_past_end():
    items = [Item(i) for i in range(100)]
    result = list_items(items, offset=95, limit=10)
    assert len(result) == 5 and result[0].id == 95
```

## Implementation Notes

Decided: default limit=10, offset=0. Standard REST convention.
```

## Battle cry

"Dabu." — *I obey*. The TDD goes to the horde without a sign-off; that is the
whole point of the stage.

Once, at that moment — not every message, and never two messages running. Full
rules in `using-hordev` § Voice: conversational output only, never in artifacts,
never on bad news.
