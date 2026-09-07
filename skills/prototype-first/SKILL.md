---
name: prototype-first
description: Use when deciding what to build first, when about to add config, flags, an abstraction layer, error handling for undescribed cases, or tests beyond the TDD, or when deciding whether the prototype is done
---

# Prototype-First

A prototype is the thinnest end-to-end path a human can execute and judge.
The test: can the user run it, feed it real input, and see real behavior? If you
are describing what it would do instead of what it does, you are not yet a
prototype.

## Ordering: Build the Risky Slice First

Start with the load-bearing, uncertain, or architecturally risky piece. This is
what the prototype exists to falsify. Comfortable, well-understood work waits.

**Right order**: Does this language model API work as described? Build the API
call, test it on real input, prove the behavior. Then build UI around it.

**Wrong order**: Design a config system, build abstraction layers, then wire up
the model call on day three and discover the API does not work that way.

## What to Defer Explicitly

Record each deferral in `assumption-ledger`. Do not omit it silently.

- **Error handling beyond the happy path.** Handle the main success case.
  Graceful failures for edge cases come later.
- **Configurability and settings.** Hardcode values. Change them when the
  prototype proves what should vary.
- **Performance work.** Prototype for correctness. Optimize after you know it
  matters.
- **Abstraction layers for future cases.** Do not build for cases nobody has yet.
  Generalize when a second case arrives.
- **Input validation and sanitization.** Validate enough to avoid crashes in the
  happy path. Exhaustive validation is hardening work.
- **Logging, observability, telemetry.** Add these when you need them to debug
  or understand the prototype.

## What Is Never Deferred

Do not fake behavior and present it as working. Do not stub something the user
will read as real.

- **Data flow must be real.** If the prototype claims to save data, it must save
  data. If it claims to fetch from a service, it must fetch from a service.
- **User-visible output must be honest.** Do not mock results that should be
  computed.
- **Dependencies must resolve truthfully.** If the prototype depends on an
  external system, it must call that system. Do not replace it with a stub
  during prototype phase.

## Drift Detection

These are signals you have left prototype mode. Stop and recenter.

| Signal | Corrective Action |
|--------|-------------------|
| You are writing a config system or adding command-line flags. | Remove it. Hardcode the value. `assumption-ledger` records the decision. |
| You are refactoring for elegance or symmetry before proving the core works. | Halt refactoring. Prove the core first. Elegance comes in hardening. |
| You are designing for a case that nobody has written yet. | Delete the abstraction layer. Write it when you have a second case to generalize from. |
| You are adding the second or third abstraction layer. | You are over-designing. Walk back to a single layer or none. |
| You are gold-plating a passing test (adding assertions, coverage, edge case branches). | Stop. The test passes. Move on. Hardening comes later. |
| You are implementing error handling paths nobody has described as necessary. | Remove them. Handle errors in the happy path only. Add more when you see them fail. |
| Your code review checklist grows faster than your feature list. | Your checklist is for hardening, not prototyping. Pare it back. |

## Knowing When the Prototype is Done

A prototype is done when it has answered one of these questions:

1. **Does the spec hold?** The prototype either proves the spec works or falsifies
   it. If falsified, loop back to `rapid-spec` with evidence. If it holds,
   graduate to hardening.
2. **What is the real load-bearing risk?** You may have built the wrong thing.
   The prototype showed you. Now you know what to build next.
3. **What will users actually do with this?** The prototype is running in user
   hands (or a user's mental model). Their behavior contradicts or confirms the
   spec. Adjust and repeat, or move to hardening.

Do not leave prototype mode because the code is beautiful or the test suite is
comprehensive. Leave it because you have evidence.

## Interaction with `writing-tdds`

Thin does not mean untested. Tests come first even in prototype mode; there are
just fewer of them.

Write tests for the risky, load-bearing slice. Write tests for the happy path.
Do not write tests for error handling paths you have deferred, or for edge
cases you have not hit.

If your test suite is growing faster than your feature set, you are hardening,
not prototyping. Redirect tests to the critical path.

## Corrective Question

**Are we building to learn or to ship?** If the answer is "learn," you are in
prototype mode. Stay thin. Record assumptions.

If the answer is "ship," the prototype has done its job and hordev is the wrong
tool for what comes next. Hardening is well-understood work against a spec you
now trust — exactly the case where structure beats speed. Hand the branch over
and say so plainly. Do not let a prototype drift into production by accretion.

## Battle cry

"Me not that kind of orc!" — when the ask has drifted into hardening and hordev
is the wrong tool. Say the line, then hand the branch over plainly.

Once, at that moment — not every message, and never two messages running. Full
rules in `using-hordev` § Voice: conversational output only, never in artifacts,
never on bad news.
