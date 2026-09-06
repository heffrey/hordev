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

## Who runs what

You are the orchestrator. You stay on `opus` for the whole run and you are the
only thing that dispatches, advances the chain, or talks to the user. Skills do
not invoke each other — you invoke them, in order, as work returns.

A dispatched agent cannot see this conversation, cannot ask the user anything,
and cannot hand off to the next stage. So:

1. **Extract.** You ask `rapid-spec`'s 0-2 questions yourself, if any earn a
   slot. Then dispatch one `haiku` agent with the `rapid-spec` skill text, the
   request, and the answers inlined. It returns a path to
   `.hordev/specs/<feature-name>.md`. It does not talk to the user.
2. **Design.** Dispatch one `haiku` agent with the `writing-tdds` skill text and
   the spec path. It returns a path to `.hordev/tdds/<feature-name>.md`.
3. **Cut.** You run `decomposing-for-hordes` yourself. Then set up isolation per
   `isolating-horde-workspaces` — one worktree for this track of work — before
   any agent is dispatched. A horde that never got a worktree is running in the
   user's checkout.
4. **Swarm.** You dispatch the horde, then run `reconciling-horde-output`
   yourself when it returns.
5. **Verify.** You run `horde-qa` yourself.

If a stage's agent returns something unusable, re-dispatch a fresh agent with an
amended prompt. There is no resuming a finished agent — it has no context left
to resume into.

## Finishing a run

`horde-qa`'s report is the run's final output. It must carry three things,
because the user approved nothing along the way and this is where they find out
what was decided for them:

- What was verified, and what was not.
- Open assumptions from `.hordev/assumptions.md`, highest blast radius first.
- The branch the work is on, so they can review or discard it whole.

Do not merge or delete the branch yourself. Hand it over.

## Going wide

When the right approach is genuinely unknown, the horde goes wide instead of
deep: `racing-prototypes` builds two to four competing versions at once and
picks a winner on evidence. Breadth is half of hordev's bet, not a special case.

It sits between Design and Cut: one spec, one TDD shared by every candidate, one
`haiku` agent per candidate in its own worktree. The winner then continues
through the normal chain — Cut and Swarm if it still needs a horde to finish,
otherwise straight to Verify.

Supporting skills, used at any stage:

- `prototype-first` — keeping time-to-prototype the metric when a run starts
  drifting into polish.
- `racing-prototypes` — building competing approaches in parallel and judging
  them.
- `debugging-in-a-horde` — debugging code that many agents wrote in parallel.
- `isolating-horde-workspaces` — keeping a horde out of the user's checkout.
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

## Artifacts

A run leaves these behind, in the project root:

| Path | Written by | Contents |
|---|---|---|
| `.hordev/specs/<feature-name>.md` | `rapid-spec` | The spec |
| `.hordev/tdds/<feature-name>.md` | `writing-tdds` | Test-driven design |
| `.hordev/assumptions.md` | `rapid-spec`, `writing-tdds` | Every question not asked |
| `.hordev/run-log.md` | all stages | What went wrong, for `improving-hordev` |

## Where hordev differs from superpowers

hordev descends from superpowers and keeps its tenets: skills as version
controlled markdown, tests before implementation, artifacts that outlive the
session. It diverges on pacing, and it is not a strict upgrade.

superpowers earns its keep on structure, framework, spec-driven development,
and autonomy — long runs on well-understood work, inside a framework, with
checkpoints you actually want. hordev's territory is fast, broad prototyping:
the answer is not known yet, several approaches look plausible, and the
cheapest way to learn is working versions of them.

If the spec is already trusted, hordev's speed buys little and costs the
checkpoints. That is a superpowers job. Say so.
