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
4. **hordev improves itself.** Runs append to `.hordev/run-log.md`; a `Stop` hook notices and
   asks whether a skill should change. The bar is a repeated failure, never a one-off. A
   lesson that stays in a session transcript was not learned.

Breadth matters as much as speed. A horde is not just one design built faster — it is four
plausible directions built at once so the user can see which one is right. Reach for the
horde when the answer is genuinely unknown, not only when the work is large.

hordev still produces TDDs and specs — it is not "skip the design." It produces them fast,
from fewer questions, and treats them as living documents the prototype is allowed to correct.

## Positioning: hordev is not a strict upgrade over superpowers

Say this accurately in anything public. superpowers earns its keep on **structure,
framework, spec-driven development, and autonomy** — long runs on well-understood work,
inside a framework, with checkpoints you actually want. hordev gives some of that up on
purpose.

hordev's territory is **fast, broad prototyping**: the answer is not known yet, several
approaches look plausible, and the cheapest way to learn is to have working versions in front
of you. If the spec is already trusted, hordev's speed buys little and costs the checkpoints —
that is a superpowers job. Never write marketing that frames superpowers as the inferior
tool.

## This is a public repository

`https://github.com/heffrey/hordev`, MIT, public from day one. Strangers read this code.

- No machine-specific paths, no personal references, no assumed local setup in any skill,
  hook, or doc. Hooks resolve their own root from `CLAUDE_PLUGIN_ROOT`.
- Several skills are adaptations of superpowers skills. Attribution stays in `LICENSE` and
  `README.md`; keep it there.
- Prose is read by humans and gets held to it: terse, concrete, no marketing voice, no
  filler. Skills themselves are written for a model to follow, not for a human to admire.

## Status

Version 0.5.0. The plugin manifest, both hooks, and the skill library exist. There is no
build step and no test suite yet — validation is currently reading the files and checking
that hooks emit valid JSON. Both hooks have now fired in live sessions.

The self-improvement loop has produced one round of amendments (0.4.0, from the run logged
in `.hordev/run-log.md`), but the library has not been run across enough different projects
to have learned much yet.

## Releasing

The version string lives in four files — `.claude-plugin/plugin.json`,
`.claude-plugin/marketplace.json`, this file, and `README.md` — and it drifted twice when
only the first was bumped, so 0.4.0 and 0.5.0 never actually shipped. `marketplace.json` is
the one installs read; a stale one means nobody downstream sees the release at all.

Never edit those four by hand. `scripts/version.sh` bumps all of them at once and verifies
each edit matched exactly once:

```bash
scripts/version.sh            # check all four agree; non-zero if they do not
scripts/version.sh 0.6.0      # set all four
```

`scripts/git-hooks/pre-commit` refuses a commit that would leave them disagreeing. It is not
active in a fresh clone until someone runs `git config core.hooksPath scripts/git-hooks`.

If prose around a version string is reworded, `version.sh` fails loudly with the pattern that
stopped matching. Fix the pattern in the `SITES` array — do not drop the site, or the next
bump skips that file while reporting success, which is the failure this replaces.

Tag every release: `git tag -a v<version>` and push with `--follow-tags`. Tags v0.2.0
through v0.5.0 exist; v0.3.0 and v0.4.0 were tagged retroactively.

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
- Reflection is a stage of the run, not a thing the user remembers to ask for.
  `improving-hordev` is the sixth stage, triggered by the `Stop` hook rather than by
  judgment, because reflection that depends on an agent choosing to reflect does not happen.
- `horde-status` reports a run against hordev's own six stages, so "where are we" has one
  answer shaped like the pipeline instead of a narrative summary.

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

## Worktrees are load-bearing

hordev drops superpowers' interview, not its spec-driven tenets, and worktrees are what keep
those tenets honest under parallelism. A worktree gives a track of work its own branch,
history, and verifiable end state — which is what lets a spec stay attached to something a
human can review, revert, or compare. Without it a horde's output is an undifferentiated pile
of edits and the spec becomes uncheckable.

The unit of isolation is a **track of work, not an agent**: one worktree per spec, with file
ownership separating agents inside it. Racing candidates are the exception that always get one
each. `isolating-horde-workspaces` owns these rules; other skills link to it rather than
restating them.

## Conventions

- Skill descriptions are trigger conditions, not summaries. Write them so a model can match a
  situation against them.
- Keep skills narrow. One skill, one decision point.
- Skills are prose instructions for a model, not code — they are read, not executed.
