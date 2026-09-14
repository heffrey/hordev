# Changelog

Most releases since 0.4.0 are amendments `improving-hordev` proposed from a run
log. A failure seen twice earns a rule; seen three times, a rewrite.

Versions 0.2.0 through 0.4.0 were tagged retroactively. There is no release
before 0.2.0.

## 0.7.0 — 2026-09-13

Fifteen changes from two runs' evidence, read together, plus reflection that
switches itself off. Adds `tests/run.sh`, a dependency-free bash suite that runs
every hook and script against fixture projects.

Mechanisms that silently did not work:

- The reflect hook looked only in the main checkout, so it never fired for a
  run isolated in a worktree. It now scans `.claude/worktrees/*/.hordev/` and
  stamps each log beside itself.
- The hook and the Reflect stage gave contradictory instructions. `using-hordev`
  now owns the procedure; the hook quotes it, and a test fails if they drift.
- Run-log entries gain `CLASS`, from a fixed vocabulary. The hook indexes every
  log in `~/.claude/hordev/runs.md`, and `tally-classes.sh` counts classes
  across runs, so a failure seen once in each of two projects is a repeat.

Rules that depended on discipline:

- `validate-run-log.sh` rejects prose, headings and malformed entries; Reflect
  runs it before tallying.
- Dispatch prompts are saved to `.hordev/dispatch/<task>.md`, and
  `check-ids.sh` fails a wave that cites an assumption ID the ledger lacks.
  `assumption-ledger` owns the rule.
- `rapid-spec` scales its word budget to the feature (400 / 800 / split);
  overriding a budget means stating it in the prompt and logging it.

Gaps:

- `horde-qa`: the real path observed in the real runtime is a required step,
  with a named negative control per critical claim; says what verification
  becomes without a TDD; five more lies in the table.
- `dispatching-hordes`: check memory before wide waves; a deliberate
  mitigation is a ledger entry, not a to-do.
- `horde-status`: a service a report names is checked at the moment of
  reporting.
- `isolating-horde-workspaces`: a pattern for sibling repositories.
- Model assignment has a `sonnet` tier for bounded judgment on existing code.
- `assumption-ledger`: new infrastructure is Existential by default;
  `rapid-spec` states the operating context and sizes the design to it.
- `improving-hordev`: releases go through `scripts/version.sh`, and a committed
  amendment does not reach the running session until the plugin updates.

Reflection goes dormant once converged: the 10 most recent indexed runs, from at
least 3 projects, repeat no failure class. The hook says so once and goes quiet,
and wakes if a class recurs. `HORDEV_REFLECT=on|off` overrides.

## 0.6.1 — 2026-09-13

Four amendments, each seen at least twice in one project's run log.

- `assumption-ledger`, `rapid-spec`: ledger IDs carry a per-run prefix
  (`PK-001`, not `A-001`). Names that must be unique across the repository are
  chosen against the default branch as fetched now. Two concurrent runs had
  allocated the same migration number and ledger IDs.
- `writing-tdds`: at least one test carries a value across a whole encoding
  boundary, and examples include an input that separates the plausible wrong
  behavior from the right one.
- `horde-qa`: price a synthetic client before calling a path unrunnable; grep
  for the whole defect class before fixing one instance; confirm every branch a
  mitigation can take, including the one that fires on a legitimate user; read
  tests whose comments justify a surprising result.

## 0.6.0 — 2026-09-11

Rewrites the two skills that hit the recurring bar in one run.

- `decomposing-for-hordes`: independence is tested over five kinds of write
  surface — files written, files created and everything that then matches them,
  config and environment, live external state, and the orchestrator itself. The
  cut is a checklist dispatched whole; every task is dispatched or deferred with
  a reason.
- `dispatching-hordes`: verification with raw output and bracketed prohibitions
  are numbered items in the prompt contract and appear in the skeleton prompt.
- `scripts/version.sh` bumps or checks the version in all four files that carry
  it, and `scripts/git-hooks/pre-commit` refuses a commit where they disagree.
  0.4.0 and 0.5.0 were bumped in `plugin.json` alone, so installs stayed on
  0.3.0 until this release.

## 0.5.0 — 2026-09-11

- Reflect becomes a sixth stage. After Verify passes, `improving-hordev` is
  dispatched on sonnet and writes only `.hordev/proposed-amendments.md`. Only the
  orchestrator edits skills.
- `horde-status` and the README updated for six stages.

## 0.4.0 — 2026-09-11

Four amendments from a run that failed in five new ways.

- `decomposing-for-hordes`: ownership covers files that do not exist yet, the
  orchestrator is a writer, and a near-miss is a collision.
- `dispatching-hordes`: name the exact verification command, require raw output,
  and repeat every prohibition at the end of the prompt.
- `rapid-spec`: ground specs in source on the branch being built, not in docs;
  never cite an assumption you have not written.
- `horde-qa`: step 0 confirms the suite executed, as the right user. Adds
  invariant tests for data-heavy deliverables.

## 0.3.0 — 2026-09-10

- Adds `horde-status`, a run report shaped for hordev's stages. No task reports
  above 75% before `horde-qa` passes; the assumption ledger is a required
  section, ranked by blast radius; the task table names each agent's model; the
  header states whether the run is isolated in a worktree.

## 0.2.1 — 2026-09-10

- Closes the disguised approval gate. The no-sign-off rule named specs and TDDs,
  so it was evaded by rephrasing ("say the word and I'll dispatch").
  `using-hordev` names that form, and `rapid-spec`, `writing-tdds` and
  `decomposing-for-hordes` hand off by invoking the next skill in the same turn.

## 0.2.0 — 2026-09-06

First release.

- 14 skills: `using-hordev`, `rapid-spec`, `writing-tdds`, `assumption-ledger`,
  `prototype-first`, `decomposing-for-hordes`, `dispatching-hordes`,
  `isolating-horde-workspaces`, `racing-prototypes`, `reconciling-horde-output`,
  `horde-qa`, `debugging-in-a-horde`, `improving-hordev`, `writing-hordev-skills`.
- Plugin manifest and marketplace entry; a session-start hook that injects
  `using-hordev`, and a Stop hook that prompts reflection when the run log grows.
- Worktrees are load-bearing: one per track of work, not per agent. Agents write
  files; the orchestrator commits.
- Each skill ends with a battle cry, with restraint rules in `using-hordev`.
