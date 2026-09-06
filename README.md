# hordev

![A horde of orcs and goblins swarming over a half-built structure, hauling beams
up scaffolding and hammering joists, while one larger orc foreman stands apart in
the foreground reading a plan](assets/hordev-horde.png)

A skills library for [Claude Code](https://claude.com/claude-code) that trades
interviewing for building.

hordev takes a small amount of input, decides the rest, writes a spec and a
test-driven design without asking anyone to approve them, and then throws a
horde of cheap fast agents at the problem in parallel. The goal is a running
prototype you can judge, quickly, across several directions at once.

It is a descendant of [superpowers](https://github.com/obra/superpowers) and
keeps its tenets: skills as version-controlled markdown, tests before
implementation, artifacts that outlive the session. It diverges on pacing.

## Which one should you use

They are aimed at different jobs, and hordev is not a strict upgrade.

**Use superpowers** when structure is what you need: spec-driven development,
a framework to work inside, long autonomous runs on well-understood work, and
review checkpoints you actually want. That structure is where superpowers earns
its keep, and hordev deliberately gives some of it up.

**Use hordev** when you need to find out fast, and broadly: you are not sure
what to build yet, several approaches look plausible, and the cheapest way to
learn is to have working versions of them in front of you. Breadth is the point
as much as speed — a horde is good at exploring four directions at once, not
just at doing one direction faster.

If you are executing a spec you already trust, hordev's speed buys you little
and costs you the checkpoints. Use superpowers.

## How it works

Every hordev run moves through five stages:

![Five stages left to right - Extract, Design, Cut, Swarm, Verify - colored by
model, with a single arrow fanning out into a dozen parallel agents and
converging again before Verify. Caption: haiku does the volume, opus does the
judgment](assets/five-stage-run.png)

| Stage | Skill | Model |
|---|---|---|
| Extract | `rapid-spec` | haiku |
| Design | `writing-tdds` | haiku |
| Cut | `decomposing-for-hordes` | opus |
| Swarm | `dispatching-hordes`, `reconciling-horde-output` | haiku fan-out, opus merge |
| Verify | `horde-qa` | opus |

When the right approach is genuinely unknown, the horde goes wide instead of
deep: `racing-prototypes` builds two to four competing versions at once, under
identical budgets and pre-committed judging criteria, and picks a winner on
evidence from running code.

![One spec and TDD splitting into three identical candidate lanes, each in its
own worktree, meeting a line labelled "judged on running code" - one continues as
the winner, the other two continue as dashed lines labelled "kept". Caption:
losing branches stay until you have seen them](assets/racing-prototypes.png)

Supporting skills: `prototype-first`, `racing-prototypes`, `assumption-ledger`,
`debugging-in-a-horde`, `isolating-horde-workspaces`, `improving-hordev`,
`writing-hordev-skills`. `using-hordev` is the entrypoint, injected at session
start by a hook.

### The three decisions that define it

**No approval gate.** hordev never asks you to sign off on a spec or a TDD. It
decides, writes them, and starts building. This is the whole speed bet, and it
is why QA is the most important skill in the library — with nobody approving
the design, verification is the only thing between a wrong spec and a wrong
prototype.

**Every question you did not get asked is written down.** Not asking is only
honest if the decision is visible, so each one becomes an entry in
`.hordev/assumptions.md` with its blast radius and how it will be falsified.
You see the open ones at the end of a run. That ledger is the contract that
makes skipping the interview defensible instead of reckless.

**Cheap agents do the volume, strong agents do the judgment.** Specs, TDDs, and
implementation run on Haiku; orchestration, decomposition, reconciliation, and
QA run on Opus. Reaching for the strongest model everywhere defeats the purpose
of a horde.

### It improves itself

![A four-step cycle - run, log, diagnose, amend - with a Stop hook prompting the
move from log to diagnose, and a red gate blocking the return from amend labelled
"repeated failure only, never a one-off"](assets/self-improvement-loop.png)

Runs append to `.hordev/run-log.md`. A `Stop` hook notices when the log has
grown and asks whether anything should change a skill. The bar is deliberately
high: amend on a repeated failure, never on a one-off. `improving-hordev` maps
symptoms back to the skill that probably needs the edit — seam bugs usually
mean the decomposition rules are too loose, agents returning plans instead of
code mean the dispatch prompt contract is weak.

## Install

In Claude Code, add this repository as a plugin marketplace, then install from
it:

```
/plugin marketplace add heffrey/hordev
/plugin install hordev@hordev
```

The entrypoint skill loads itself at session start, so there is nothing else to
configure. Restart the session after installing.

Requires `bash`. Nothing else.

## Status

Early. Version 0.1.0.

The skills are written. Both hooks run correctly when executed directly —
`session-start.sh` emits the entrypoint as valid JSON, and `reflect.sh` blocks
once when the run log grows, honors the `stop_hook_active` loop guard, and
stays silent afterward. They have not yet been exercised inside a live Claude
Code session, which is a different thing and the next thing to verify.

The library has not been run in anger across enough projects for its own
self-improvement loop to have taught it anything. Expect rough edges, and
expect these rules to change as real runs falsify them.

## License

MIT. See [LICENSE](LICENSE).

Derived in part from [superpowers](https://github.com/obra/superpowers) by
Jesse Vincent, used under the MIT License.
