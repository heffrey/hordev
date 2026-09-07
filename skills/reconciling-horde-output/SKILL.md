---
name: reconciling-horde-output
description: Use when horde agents have returned and their files have not yet been built or tested together - the first pass that makes parallel output compile, agree at the seams, and match the TDD's names
---

# Reconciling Horde Output

Many cheap agents wrote code in parallel without seeing each other's work.
You are integrating that work into a working codebase. You are not styling it
or perfecting it — you are making it cohere around the TDD's contract.

## Failure modes and detection

Parallel authorship fails in predictable ways. Detect them in order of cost
(cheapest first) and impact (most work invalidated first).

| Failure | Detection | Impact |
|---------|-----------|--------|
| **Build breaks** | Compile or lint error, import path wrong, syntax | Blocks everything |
| **Tests fail** | TDD not satisfied, contract violated | Blocks integration |
| **Stub work** | Agent left comments, empty functions, `raise NotImplementedError` | Logic gap, needs redone |
| **Duplicated helpers** | Two agents independently wrote `retry_with_backoff`, both now in tree | Confusing, bloat |
| **Divergent seams** | Agent A expects `error: Exception`, Agent B raises `CustomError` | Silent failures at boundaries |
| **Naming drift** | Agent wrote `parse_config()`, TDD expects `parse_configuration()` | Tests fail, needs renaming |
| **Swallowed errors** | `except Exception: pass`, missing validation | Worse than failure — silent bugs |

## Reconciliation order

Work through these steps for each agent's output. Stop if the order invalidates
the rest (e.g., if build fails, fix and retest before moving on).

1. **Build and run tests** — Does it compile? Do the tests pass? If no to either,
   run only that agent's tests in isolation. If their specific tests pass, the
   break is at a seam — note it.

2. **Check seams first** — Inspect the interfaces between agents' files before
   reading bodies. Look for:
   - Function signatures: do they match what the neighbor agent expects?
   - Error types: does both sides agree on exception names?
   - Data structures: does the shape of returned objects match?
   - File paths, imports, module names: are they the agreed-upon names?

3. **Detect stubs** — Search for `NotImplementedError`, `pass`, `TODO`,
   `# stub`, ellipsis (`...`), and empty function bodies. Any indicate an
   agent did not finish.

4. **Find duplicates** — Look for helpers that appear in multiple files with
   similar logic but different names or signatures (e.g., two retry loops,
   two config parsers). Agents never see each other's files, so anything
   similar in two of them was written independently — there is no copy-paste
   to rule out.

5. **Validate naming against TDD** — Run `grep` for test expectations. If
   a test expects `process_data()` but the implementation has `handle_data()`,
   that's a mismatch to fix.

## Fix or re-dispatch: decision rule

| Situation | Action |
|-----------|--------|
| Small, local bug (off-by-one, typo, wrong import) | Fix in place |
| One seam misaligned, both agents' code is good otherwise | Fix the interface agreement locally |
| Agent stubbed an entire module or key function | Re-dispatch to that agent for that function |
| Duplicated helper, small and obvious | Pick one, delete the other, verify imports |
| Style/naming inconsistency only | Fix in place — do not re-dispatch for lint |
| Logic error that spans an agent's work and breaks TDD | Re-dispatch that agent on the specific failed test |

## The seam-first principle

Integration bugs live at boundaries. Before reading any function body,
walk the interfaces:

1. List every file-to-file dependency (imports, function calls, data passed).
2. For each edge, verify both sides agree:
   - Function name and parameter types
   - Return type and shape
   - Error cases and exception names
   - Cardinality: does one agent call the other once or in a loop?

Only after seams are solid, read implementations to catch logic bugs.

## Style and voice

**Do not silently rewrite an agent's work into your own style.** You will
lose the speed advantage of parallelism if you re-author code that merely
looks ugly. Reconcile toward the TDD's contract only:

- Naming must match test expectations.
- Error handling must match what other agents catch.
- Return types and shapes must match the interface agreement.
- Logic must satisfy the test cases.

If an agent wrote readable, working code in a different style, leave it.
Style consistency is a post-integration task, not a reconciliation task.

## Deciding what is systemic

If an agent consistently misunderstood the seam interface or the TDD scope,
feed the details to `improving-hordev` so the next horde learns from it.
Examples:

- Three agents independently ignored error handling because the TDD didn't
  specify it clearly.
- Two agents misunderstood the same config file format because the TDD was
  ambiguous.
- An agent assumed a global constant existed when they should have passed it
  as a parameter.

One-off mistakes (typo, wrong import, off-by-one) are not systemic.

## What comes next

When reconciliation is complete:

- The code builds and tests pass locally.
- Seams are aligned.
- No stubs remain.
- Naming matches the TDD.

**Do not deploy.** Hand off to `horde-qa`, which runs a fuller test suite,
acceptance criteria, and performance checks that reconciliation does not cover.

## Log what went wrong

Append a 4-field entry to `.hordev/run-log.md` (format in `improving-hordev`)
for every seam collision, duplicated helper, and silently stubbed task you find.
Mark `COST: systemic` when the same class appeared in an earlier run — that is
what clears the amendment bar.

## Battle cry

"Work complete!" — when the tree is coherent and the seams hold. Not before,
and not instead of checking.

Once, at that moment — not every message, and never two messages running. Full
rules in `using-hordev` § Voice: conversational output only, never in artifacts,
never on bad news.
