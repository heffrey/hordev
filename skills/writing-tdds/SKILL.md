---
name: writing-tdds
description: Use when you have a rapid-spec and need to hand off to the horde
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

Save to: `path/to/feature-name.tdd.md`

```markdown
# Feature Name — TDD

**Spec:** `path/to/spec.md` (link to the rapid-spec this designs)

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

Each test is a contract. A horde agent implementing this TDD receives:
- The spec (for context)
- This TDD (behavior definition)
- No further guidance

Write tests to make implementation unambiguous.

**Good test:**
```python
def test_retry_stops_after_max_attempts():
    attempts = []
    def failing_op():
        attempts.append(1)
        raise ValueError("fail")
    
    with raises(ValueError):
        retry(failing_op, max_attempts=3)
    
    assert len(attempts) == 3
```
Clear name, concrete inputs, one behavior.

**Bad test:**
```python
def test_retry_works():
    mock = MagicMock(side_effect=[Error(), Error(), "ok"])
    result = retry(mock)
    assert mock.call_count == 3
```
Name vague, tests mock not behavior, setup obscures intent.

## Parallel-Safe Tests

Each test unit must be independently runnable and must not share mutable
state with other tests. No fixtures two agents would both edit. No
database state one test depends on another writing. No test
interdependencies.

**Write each test assuming it runs in isolation, in any order.**

If you find yourself needing shared setup beyond read-only constants,
refactor: extract what each test actually needs, put it in the test's
own Given block.

## Right-Sizing

A TDD is done when a `haiku` agent can take any single test unit and
implement it without rereading the spec or asking for clarification.

- Each unit should fit in 50-100 lines of implementation code
- Names and types must be exact (copy-paste safe for function names)
- Input/output types must be unambiguous
- Edge cases (empty input, null, boundaries) must be explicit in tests
- "Handle errors" is not a test; "raises ValueError on negative input"
  is

If a test needs a paragraph of Given setup, the behavior is too coarse
— split it.

## Handoff to Decomposing

After the TDD is complete:

1. Move to `decomposing-for-hordes`: it slices the TDD into
   independent tasks, assigns one task per agent, and dispatches.
2. Each task gets one or more test units to implement.
3. Each agent pushes their implementation to a branch.
4. Reconciliation collects implementations and verifies all tests pass.

**Do not pause here for approval. Do not ask the user to review the TDD
before dispatch.**

## Underdetermined Spec

If the spec is ambiguous on a design point:

1. **Decide locally.** Don't halt. What would a pragmatic implementation
   do?
2. **Document it.** Add a line to "Implementation Notes" with your
   decision and rationale (one sentence).
3. **Log the assumption.** Use `assumption-ledger`: create an entry with
   the decision, why you picked it, where it matters, who should know.
   Get its ID.
4. **Reference it.** Link the ID in Implementation Notes.
5. **Continue.** Write the test reflecting your decision.

Example:
```markdown
## Implementation Notes

[Spec silent on retry delay. Decided: no delay, fail fast. This assumes
caller handles backoff. See assumption-ledger entry AL-042.]

[Setup: all tests use in-memory data; no DB fixtures.]
```

Use `assumption-ledger` when the decision will surprise implementers
or commits to a path the spec could have closed. Don't log "I chose
Python" — log "I used in-memory cache instead of Redis because spec
said lightweight prototype."

## Example: Pagination TDD

```markdown
# Pagination — TDD

**Spec:** `features/pagination-api.md`

## Scope & Constraints

Covers HTTP list endpoints returning paginated results. Tests assume
JSON responses. Does NOT cover sorting, filtering, or cursor types —
those are separate features. Endpoint must support `limit` and `offset`
query params.

## Tests

### Unit 1: First Page Without Params

Given: 100 items in store, endpoint `/items`
When: GET /items (no params)
Then: returns first 10 items, status 200

```python
def test_first_page_default():
    store = Store(items=[Item(i) for i in range(100)])
    result = store.list()
    assert len(result) == 10
    assert result[0].id == 0
    assert result[9].id == 9
```

### Unit 2: Offset Advances Page

Given: 100 items, offset=20
When: GET /items?offset=20
Then: returns items 20-29

```python
def test_offset_skips_to_page():
    store = Store(items=[Item(i) for i in range(100)])
    result = store.list(offset=20)
    assert result[0].id == 20
    assert result[9].id == 29
```

### Unit 3: Limit Constrains Size

Given: 100 items, limit=5
When: GET /items?limit=5
Then: returns exactly 5 items

```python
def test_limit_caps_results():
    store = Store(items=[Item(i) for i in range(100)])
    result = store.list(limit=5)
    assert len(result) == 5
```

### Unit 4: Boundary — Past Last Item

Given: 100 items, offset=95
When: GET /items?offset=95&limit=10
Then: returns 5 items (95-99)

```python
def test_offset_past_end_returns_tail():
    store = Store(items=[Item(i) for i in range(100)])
    result = store.list(offset=95, limit=10)
    assert len(result) == 5
```

### Unit 5: Empty Request

Given: 100 items, limit=0
When: GET /items?limit=0
Then: returns empty list

```python
def test_limit_zero_returns_empty():
    store = Store(items=[Item(i) for i in range(100)])
    result = store.list(limit=0)
    assert len(result) == 0
```

## Implementation Notes

Spec says "sensible defaults." Decided: default limit=10, offset=0.
This is standard REST convention.

All tests use in-memory Store. Implement against interface, not DB.
```
