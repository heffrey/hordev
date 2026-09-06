# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What hordev is

hordev is a skills library for Claude Code, built as a replacement for `superpowers`
(https://github.com/obra/superpowers). It shares superpowers' tenets — skills as
version-controlled markdown, TDD, specs and plans as durable artifacts — but inverts its
pacing.

The name is "horde" + "dev". The defining bet: **less time interviewing the user, more time
building.** Where superpowers opens with `brainstorming` and drives a long requirements
dialogue before any code, hordev extracts the minimum it needs, writes the TDD and spec, and
moves immediately to a running prototype fanned out across a large horde of fast, parallel
agents.

Two consequences shape every design decision here:

1. **Time-to-prototype is the metric.** A skill that adds a round-trip with the user must
   justify itself against the prototype it delayed. Prefer stating an assumption and building
   under it over asking.
2. **Parallelism is the default execution mode, not an optimization.** Work is decomposed so
   many cheap agents can run at once with no shared state. Sequential execution is the
   exception that needs a reason.
3. **hordev is opinionated about its own spec.** It decides the spec rather than deferring the
   decision to the user, and it does **not** ask the user to approve the TDD. There is no
   approval checkpoint between design and build — the TDD is written and the horde starts.
   Correction comes from the running prototype and from QA, not from a review gate. When the
   spec is underdetermined, hordev picks, states the pick, and keeps moving.

hordev still produces TDDs and specs — it is not "skip the design." It produces them fast,
from fewer questions, and treats them as living documents the prototype is allowed to correct.

## Status

The repository is empty apart from this file. No source, no build tooling, no tests yet.
Nothing below describes code that exists — it is the intended shape, derived from the
superpowers plugin layout hordev replaces.

## Target architecture

hordev is expected to ship as a Claude Code plugin, mirroring superpowers' structure:

- `.claude-plugin/plugin.json` — plugin manifest (name, version, author, license, keywords).
- `skills/<skill-name>/SKILL.md` — one directory per skill. `SKILL.md` carries YAML
  frontmatter with `name` and a `description` that states *when to use* the skill, since that
  description is the only thing a model sees when deciding whether to invoke it. Supporting
  files (prompts, references, scripts) live beside `SKILL.md` in the same directory.
- `hooks/` — session lifecycle hooks, notably whatever injects the entrypoint skill at
  session start.
- `scripts/` — tooling for building, validating, and installing skills.
- `tests/` — skill validation and behavioral tests.

Superpowers also carries per-harness adapter directories (`.codex-plugin`, `.pi`,
`.hermes-plugin`, `.cursor-plugin`, and similar) so its skills load outside Claude Code.
Decide deliberately whether hordev takes on that portability surface — it is a real
maintenance cost.

### The entrypoint skill

Superpowers' `using-superpowers` is loaded at session start and is what makes every other
skill reachable; it establishes the rule that a relevant skill must be invoked before any
response. hordev needs the equivalent, and it is the highest-leverage file in the repository:
it sets the default posture. For hordev that posture is bias-to-build, not bias-to-interview.

### Skills to write, and how they differ

Superpowers' 14 skills are the reference set: `brainstorming`, `writing-plans`,
`executing-plans`, `test-driven-development`, `systematic-debugging`,
`dispatching-parallel-agents`, `subagent-driven-development`, `using-git-worktrees`,
`requesting-code-review`, `receiving-code-review`, `verification-before-completion`,
`finishing-a-development-branch`, `writing-skills`, `using-superpowers`.

hordev is not a rename of that set. The divergences that define the project:

- The requirements-gathering skill is short and extractive, not a long interview. It should
  terminate in a spec quickly and mark open questions as assumptions to be falsified by the
  prototype rather than blocking on answers. It ends by handing the spec to the TDD writer —
  not by presenting it to the user for sign-off.
- Parallel dispatch is promoted from one skill among many to the core execution model —
  horde-sized fan-out, agents chosen for speed, decomposition rules that keep tasks
  independent, and a merge/reconcile story for their output.
- Verification has to survive that fan-out: many agents producing work concurrently need
  cheaper, more automatic checking than a sequential workflow does.

## Model assignment

Model choice is part of the architecture, not a per-task judgment call. The split follows the
horde thesis — cheap and fast for the volume work, expensive and careful for the work that
decides:

- **Haiku (`claude-haiku-4-5-20251001`, `model: "haiku"`) — spec writing and TDDs.** These are
  high-volume, well-scoped, template-shaped artifacts. Producing them fast and in parallel
  matters more than producing them perfectly; the prototype and QA catch what is wrong. This
  is also what makes horde-sized fan-out affordable.
- **Opus 5 (`claude-opus-5`, `model: "opus"`) — orchestration and QA.** Decomposing work so
  agents stay independent, dispatching the horde, and reconciling what comes back are the
  judgment-heavy steps, and they are the ones that fail expensively. QA sits here for the same
  reason: with no user approval gate on the TDD, verification is the only thing standing
  between a wrong spec and a wrong prototype, so it gets the strongest model.

Skills that dispatch agents should set `model` explicitly rather than inheriting a default,
so the split holds no matter what the session is configured with.

## Conventions

- Skill descriptions are trigger conditions, not summaries. Write them so a model can match a
  situation against them.
- Keep skills narrow. One skill, one decision point.
- Skills are prose instructions for a model, not code — they are read, not executed.
