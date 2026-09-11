---
name: decomposing-for-hordes
description: Use when turning a TDD into independent tasks that can run in parallel without shared file writes or dependencies
---

# Decomposing for Hordes

Cut a TDD into atomic tasks that can run simultaneously. Parallelism fails when two
tasks touch the same thing, or when a task you planned never goes out at all. This
skill teaches what "the same thing" actually means, and how to check the cut was
delivered whole.

## The unit is a write surface, not a file

The obvious rule — "assign every file to one task" — is where this skill used to
stop, and it is why every collision that matters slipped past it. A file is only
the commonest kind of write surface. Enumerate all five before you cut:

**1. Files a task writes.** The easy case. One owner each.

**2. Files a task *creates*, and everything that then matches them.** A task adding
a new toolchain root — a second app, a nested package, anything with its own
`tsconfig`, `eslint` config or lockfile — silently changes every sibling config
whose glob now sweeps it up. The new directory has an owner. *The existing configs
it breaks do not.* Nobody wrote them, so nobody checked them, and the failure
surfaces as dozens of errors in an app nobody touched.

**3. Config and environment files, which are shared state wearing a file's clothes.**
An `.env.local`, a `docker-compose.yml`, a `project.yml`. Two writers here do not
merge badly — one silently replaces the other's working state, and the product keeps
running while showing the wrong thing.

**4. Live external state.** A database, a running dev server, a port, a cloud
project. Two tasks that both run migrations, or both restart a server, or both
`db reset`, are colliding even though they share no file.

**5. Your own hands.** You are a writer. Ownership gets reasoned about
agent-versus-agent, so an orchestrator who assigns a file and then edits it too is
the collision nobody is looking for. If you will touch it during the wave, you own
it and no agent gets it — otherwise the agent reports your edits as mysterious
changes appearing under it, and is right to.

**A near-miss is a collision.** Two writers where one happened to land last is luck,
not isolation. Count it, fix the cut, and log it — especially on a config file,
where the loser's version can replace a working backend with fixtures and nothing
looks broken.

## Independence Test

Two tasks can run in parallel if ALL of these hold:

- **No shared write surface.** All five kinds above, not just files.
- **No ordering dependency.** Task B does not need Task A's output or side effects.
- **Input is complete.** Both have all context inlined in the prompt. They cannot see
  the conversation, your changes, or each other.

## What Stays With You

Decide these before dispatch; every parallel task compiles against them:

- **Schema and data model.** Define once, implement against it in parallel.
- **Interface contracts.** Function signatures, API paths, event shapes.
- **Shared configuration.** Env vars, feature flags, runtime settings.
- **Any config a new task will newly match** (surface 2 above).
- **Anything you intend to edit yourself** (surface 5).

"Locked" means decided, not blessed. There is no approval gate here.

## Resolving a contested surface

**Split it.** Separate concerns into two files, one owner each.

**Sequence just those two.** Everything else stays parallel; those two run in
successive waves.

**Keep it.** It becomes yours, and no agent gets it.

## Task Sizing

- **One clear deliverable.** "Write the API endpoint", not "write backend and frontend".
- **Self-contained.** All context inlined; the agent sees no history.
- **Haiku-sized.** 15–30 minutes for a cheap fast model. Deeper reasoning folds into
  orchestration.

## Waves

When Task B genuinely needs Task A's output, stage rather than serialise:

**Wave 1 (parallel):** A, C, D. **Wave 2 (parallel):** B (uses A), E.

Wait for Wave 1 to land before Wave 2. Waves preserve the parallelism that exists;
falling back to fully sequential throws it away.

## The cut is a checklist, not a description

**Write the task list down, numbered, with owned surfaces — then dispatch off that
list, not off your memory of it.**

This is the failure that hides best. A plan of sixteen tasks dispatched as ten
produces ten green tasks, a building tree, and a passing suite. It looks exactly
like a finished run. Nothing downstream asks "was anything never sent out" —
reconciliation checks what came back.

Two rules:

- Before the first agent goes out, mark every task **dispatched** or **deferred with
  a reason**. "Later" is a reason; silence is not.
- Tasks in a different repository are the ones most likely to evaporate. They cannot
  share the worktree, so they get mentally filed as separate work and never
  re-surface. Give them a wave of their own rather than a footnote.

## Worked Example: settings page + a new admin app

**Orchestrator decides:** `PATCH /users/:id` with `{ timezone, theme }`; columns
`users.timezone`, `users.theme`; and — because task 5 creates a new toolchain root —
the root `tsconfig` and `eslint` excludes, which are **yours**, in Wave 0.

| # | Task | Owns |
|---|---|---|
| 0 | *(you)* | root `tsconfig.json`, `eslint.config.mjs`, the API contract, the schema |
| 1 | Backend route | `src/routes/users.ts` |
| 2 | Settings form | `src/components/SettingsForm.tsx` |
| 3 | Timezone list | `src/utils/timezones.ts` |
| 4 | Theme provider | `src/context/ThemeContext.tsx` |
| 5 | Admin app | `admin/**` — new toolchain root, hence task 0 |

1–5 run at once. Task 2 imports 3 and 4 without modifying them. Task 5 would have
broken 1–4's typecheck if task 0 had not existed.

## Handoff to `dispatching-hordes`

- Run the independence test over all five surface kinds.
- Confirm every planned task is dispatched or deferred with a reason.
- **Set up isolation per `isolating-horde-workspaces` first.** A horde dispatched
  without a worktree is writing to the user's checkout.
- Invoke `dispatching-hordes` in the same turn. Making the cut is the go signal;
  stopping to confirm the wave is an approval gate hordev does not have.

## Log what went wrong

Append a 4-field entry to `.hordev/run-log.md` (format in `improving-hordev`) when a
cut turns out wrong: two writers on one surface, a task too large for one agent, a
missed dependency, or a planned task that never went out. Decomposition failures
surface late and are easy to forget by the time they hurt.

## Battle cry

"Swobu." — *as you command*, when the cut is made and no two tasks want the same
surface.

Once, at that moment — not every message, and never two messages running. Full
rules in `using-hordev` § Voice: conversational output only, never in artifacts,
never on bad news.
