---
name: decomposing-for-hordes
description: Use when turning a TDD into independent tasks that can run in parallel without shared file writes or dependencies
---

# Decomposing for Hordes

Cut a TDD into atomic tasks that can run simultaneously. Parallelism fails when tasks
collide on files or create hidden dependencies. This skill teaches the independence test
and the rules of file ownership.

## Independence Test

Two tasks can run in parallel if ALL of these hold:

- **No file collision:** Each file is owned by exactly one task. No two tasks write the
  same file.
- **No ordering dependency:** Task B does not require Task A's output or side effects to
  start.
- **No shared state:** No two tasks mutate the same database, environment, or config.
- **Input is complete:** Both tasks have all code and context they need in their prompt.
  They cannot see the conversation or reference your changes mid-run.

Use this checklist before grouping tasks into a wave.

## File Ownership

Assign every file touched by a task to exactly one task. When two tasks both need to
modify one file:

**Option 1: Split the file.** Separate concerns into two files. Frontend code → file A,
backend → file B.

**Option 2: Sequence just those two.** Keep all other tasks parallel; run only those two
sequentially in a second wave.

**Option 3: Keep orchestrator writes.** Schema changes, interface definitions, config
that affects multiple tasks stays with you. Tasks implement against a fixed interface.

## Task Sizing

Each task should be:

- **One clear deliverable:** "Write the API endpoint" or "Write the frontend form", not
  "write backend and frontend".
- **Self-contained:** All context inlined in the prompt (code snippets, requirements,
  edge cases). The agent sees no git history or earlier messages.
- **Haiku-sized:** 15–30 minutes of focused work for a cheap fast model. If it needs
  deep reasoning, fold it into orchestration.

## What Stays Sequential

These decisions block parallelism. Do them before dispatching:

- **Schema and data model.** Define once, implement against it in parallel.
- **Interface contracts.** Function signatures, API paths, event shapes.
- **Shared configuration.** Env vars, feature flags, runtime settings that tasks depend
  on.

Finalize these with your TDD. Once locked, tasks can assume them.

## Worked Example: User Settings Page

**TDD:** Add a settings page where users pick a timezone and theme, saved to the database.

**Orchestrator decides (you):**
- API route: `PATCH /users/:id` with `{ timezone, theme }` in the body
- Database schema: `users.timezone`, `users.theme` columns
- Frontend form fields: two dropdowns, a save button

**Task decomposition (four parallel tasks):**

1. **Backend API** (owns `src/routes/users.ts`): POST route, validate inputs, update DB.
2. **Frontend form** (owns `src/components/SettingsForm.tsx`): Build form, handle submit.
3. **Timezone list** (owns `src/utils/timezones.ts`): Generate dropdown options.
4. **Theme provider** (owns `src/context/ThemeContext.tsx`): Theme selector logic.

No collisions. Each task writes one file. Frontend form imports timezone list and theme
context but doesn't modify them. All run simultaneously.

## Handling Dependencies: Waves

When Task B genuinely needs Task A's output, stage work into waves:

**Wave 1 (parallel):** Task A (builds core feature), Task C, Task D (independent).

**Wave 2 (parallel):** Task B (uses A's output), Task E (independent).

Wait for Wave 1 to finish before dispatching Wave 2. Avoid falling back to fully
sequential; waves preserve parallelism where it exists.

## Handoff to `dispatching-hordes`

Once tasks are decomposed:

- Verify the independence checklist above.
- List tasks with ownership and deliverables.
- Pass to `dispatching-hordes` to dispatch them all at once.

Never dispatch a task until its dependencies are met and its interface is locked.
