# Contributing to hordev

hordev is a skills library that improves itself from run logs. Most amendments
come from the self-improvement loop rather than from pull requests, but both
paths are welcome.

## Setup

```bash
git clone https://github.com/heffrey/hordev ~/src/hordev
cd ~/src/hordev
git config core.hooksPath scripts/git-hooks   # activates the version-sync pre-commit hook
```

No build step. No dependencies beyond `bash`.

## How skills get amended

The primary path is the self-improvement loop:

1. A run writes failures to `.hordev/run-log.md` in the project.
2. The `Stop` hook notices the log grew and asks for a Reflect run.
3. Reflect (`improving-hordev`) tallies failures by class across all logged
   runs. The bar is repetition: amend on two occurrences, schedule a rewrite
   on three.
4. Reflect proposes edits to `~/.claude/hordev/proposed-amendments.md`. It
   edits no skill directly.
5. The orchestrator applies the proposal to the skill files in this clone,
   runs the tests, and opens a PR.

Contributions that follow the same pattern — a run log entry showing the repeat,
a minimal rule addition — are easiest to review.

## Writing or editing a skill

Skills live in `skills/<skill-name>/SKILL.md`. The frontmatter `description`
field is the only text a model sees when deciding whether to invoke the skill —
write it as a trigger condition ("Use when …"), not a summary of what the skill
does.

See `writing-hordev-skills` for the full authorship rules. The short version:
one skill, one decision point; no approval gates; no machine-specific paths.

## Testing

```bash
bash tests/run.sh
```

Dependency-free. Runs both hooks against fixture projects and every script
beside a skill. Run it before committing any change to a hook, script, or test.
Skill prose is validated by reading it — there is no automated prose test.

## Opening a PR

Every skill change that alters behaviour ships as a patch release. The commit
sequence is:

1. Content commits (skill edits, hook changes, new tests).
2. A changelog entry at the top of `CHANGELOG.md` under the new version heading.
   Commit message: `Changelog for x.y.z`.
3. Run `scripts/version.sh x.y.z` to bump the four version files, then commit.
   Commit message: `Release x.y.z`.

PR title: `Release x.y.z: short description`. See `CLAUDE.md` § Releasing for
the full process, including tagging after merge.

## What not to send

- One-off failures: log them, let the loop decide if they repeat.
- Whole-skill rewrites without a run-log justification.
- Changes to the self-improvement threshold or dormancy rules without evidence
  from real runs that the current bar is wrong.
