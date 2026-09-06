---
name: writing-tdds
description: Use when a rapid-spec is complete and you need to
  convert it to test-driven behavior contracts for parallel
  implementation by multiple agents.
---

# Writing TDDs (Test-Driven Designs)

## Overview

A TDD (Test-Driven Design) is a specification written as concrete test
cases. It bridges from `rapid-spec` to work a horde can execute in
parallel. Tests come first because with no approval gate between design
and build, the tests ARE the specification — they're the only thing that
can falsify the design.

**Do not ask for user approval of the TDD. Specs get approved; designs
don't. Write, decide locally when underdetermined, log assumptions, move
forward.**

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
"Decided X because Y. See assumption-ledger entry ID-123."]

[Any shared setup, fixtures, or test utilities needed across units.]
```

## Tests Define Behavior

Each test is a contract for implementation. A horde agent receives
the spec and this TDD — write tests to make behavior unambiguous.
Good test names are specific (test_retry_stops_after_3_attempts, not
test_retry_works). Concrete inputs, no mocks. One behavior per test.

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

1. Move to `decomposing-for-hordes` — it slices the TDD into
   independent tasks, assigns one per agent, and dispatches.
2. Each agent implements their task units in parallel, pushes
   to a branch.
3. Reconciliation verifies all tests pass.

Do not pause for approval or ask the user to review before dispatch.

## Underdetermined Spec

If the spec is ambiguous, decide locally and log the assumption:

1. Append an entry to `.hordev/assumptions.md` with fields:
   **ID, Decided, Rationale, Rejected, Blast radius, Falsified by,
   Status** (see `assumption-ledger` skill for format)

2. Reference it in "Implementation Notes": "Decided X because Y.
   See assumption-ledger entry ID-NNN."

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
