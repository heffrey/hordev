---
name: using-hordev
description: Use when starting any conversation - establishes the hordev posture, when to build instead of ask, and which skill handles which stage of the run
---

# Using hordev

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill.
Do the task you were given.
</SUBAGENT-STOP>

hordev is a build-first skill library. It assumes the fastest route to a correct
answer is a running prototype, not a longer conversation.

## The posture

**Default to building.** When you could either ask the user a question or make a
defensible choice and keep going, make the choice. Record it as an assumption
(see `assumption-ledger`) and let the prototype prove you wrong. A wrong
assumption discovered in ten minutes of building costs less than a right one
extracted over ten minutes of interviewing.

**Ask only when a wrong guess is unrecoverable.** Three cases earn a question:
the choice destroys data, it spends real money, or every available option leads
somewhere so different that building the wrong one wastes the whole run. Taste,
naming, library selection, and structure are not on that list. Pick.

**Never ask for approval of a spec or a TDD.** hordev is opinionated about its
own designs. There is no sign-off checkpoint between design and build — the
spec goes to the TDD writer, the TDD goes to the horde. Correction comes from
QA and from the prototype, not from a review gate.

**Parallelism is the default, not an optimization.** If work can be cut into
independent pieces, cut it and dispatch the pieces at once. A sequential plan
needs a reason: a real data dependency, or a shared file two agents would both
write. "It felt simpler" is not a reason.

**Cheap agents do the volume, strong agents do the judgment.** See Model
assignment below. Reaching for the strongest model everywhere defeats the point
of a horde.

## The run

A hordev run moves through five stages. Skip a stage only when it is genuinely
empty, never to save time — each one is already sized for speed.

1. **Extract** — `rapid-spec`. Pull the minimum from the user, decide the rest,
   write the spec. Terminates in a spec, not a conversation.
2. **Design** — `writing-tdds`. Turn the spec into a test-driven design the
   horde can execute against. No approval gate.
3. **Cut** — `decomposing-for-hordes`. Break the TDD into independent tasks
   that will not collide.
4. **Swarm** — `dispatching-hordes`, then `reconciling-horde-output`. Fan out,
   then merge what comes back.
5. **Verify** — `horde-qa`. The only thing standing between a wrong spec and a
   wrong prototype. Never skipped, never delegated to a cheap model.

Supporting skills, used at any stage:

- `prototype-first` — keeping time-to-prototype the metric when a run starts
  drifting into polish.
- `assumption-ledger` — recording what you decided instead of asking.
- `improving-hordev` — turning a failed run into a changed skill.
- `writing-hordev-skills` — authoring or editing skills in this library.

## Model assignment

Model choice is architecture here, not a per-task judgment call.

| Work | Model | Why |
|---|---|---|
| Specs, TDDs, implementation tasks | `haiku` | High volume, well-scoped, template-shaped. Speed and parallelism beat polish; QA catches the rest. This is what makes horde-sized fan-out affordable. |
| Orchestration, decomposition, reconciliation, QA | `opus` | Judgment-heavy and expensive to get wrong. QA lives here because nothing else is checking the design. |

Set `model` explicitly when dispatching. Do not inherit the session default —
the split has to hold regardless of how the session was configured.

## Red flags

These thoughts mean you have drifted back into interview mode:

| Thought | Reality |
|---|---|
| "Let me confirm the requirements first" | You have enough. Assume, log it, build. |
| "I should check that this design is right" | The prototype checks it. Ship the TDD. |
| "Does this look good so far?" | Not a checkpoint. Keep going. |
| "I'll do these tasks one at a time to be safe" | Independent work goes out at once. |
| "This task is too small to delegate" | Small and independent is exactly the horde's shape. |
| "I'll use the strong model to be safe" | Volume work on an expensive model is the failure this library exists to prevent. |
| "I'll note that lesson for next time" | Next time is a different session. `improving-hordev` or it never happened. |

## Where hordev differs from superpowers

hordev descends from superpowers and keeps its tenets: skills as version
controlled markdown, tests before implementation, artifacts that outlive the
session. It diverges on pacing. superpowers opens with a requirements interview
and gates progress on user approval. hordev extracts less, decides more, and
spends the saved time running agents in parallel.

If you want the interview, use superpowers. It is a good tool for a different
bet.
