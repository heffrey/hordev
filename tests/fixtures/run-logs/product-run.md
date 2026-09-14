# Fixture: a product run's log

A real product run (12 specs, ~26 agents, a local database stack, analytics, a
separate marketing-site repository), rewritten from prose into the entry format
with product details removed. The original was prose, which is exactly what
tests/validate-run-log.test.sh expects the validator to reject; this is what it
would have looked like written properly.

---

EVENT: Dispatch covered 10 of 16 planned tasks; a wave in a sibling repository
was never sent. Every dispatched task passed, so the gap looked finished.
SKILL: dispatching-hordes
COST: one-off
CLASS: dispatch-gap
RULE:
---

EVENT: An agent reported 21/21 passing under a test runner it chose; under the
project's own runner the suite did not execute at all.
SKILL: dispatching-hordes
COST: one-off
CLASS: green-but-broken
RULE: Name the exact verification command and require raw output.
---

EVENT: A data file shipped four duplicate object keys behind a green suite that
tested only the function reading it. The agent reported 157 entries; there
were 156.
SKILL: horde-qa
COST: one-off
CLASS: green-but-broken
RULE:
---

EVENT: Root tsconfig and eslint configs globbed a newly created sibling app and
reported its build output as errors.
SKILL: decomposing-for-hordes
COST: systemic (3 times)
CLASS: write-collision
RULE:
---

EVENT: The orchestrator and an agent edited one SQL test file concurrently.
SKILL: decomposing-for-hordes
COST: systemic (3 times)
CLASS: write-collision
RULE:
---

EVENT: An agent and the orchestrator both wrote one .env.local; demo fixtures
nearly replaced a live backend config.
SKILL: decomposing-for-hordes
COST: systemic (3 times)
CLASS: write-collision
RULE: Ownership covers files that do not exist yet; the orchestrator is a writer.
---

EVENT: The spec named two interfaces that exist only on an unmerged branch,
taken from project docs rather than source.
SKILL: rapid-spec
COST: one-off
CLASS: spec-misread
RULE: Ground specs in source on the branch being built.
---

EVENT: Four assumption IDs were cited in dispatch prompts and never written to
the ledger. No spec file cited them.
SKILL: rapid-spec
COST: one-off
CLASS: format-drift
RULE:
---

EVENT: An agent ran git rm and git commit against an explicit prohibition, then
unwound its own commit.
SKILL: dispatching-hordes
COST: one-off
CLASS: agent-git
RULE: Repeat every prohibition in the closing lines of the prompt.
---

EVENT: The run log was written as prose instead of the entry format and had to
be re-tallied by hand at reflection.
SKILL: improving-hordev
COST: one-off
CLASS: format-drift
RULE:
---

EVENT: Specs came back at 1,100 to 2,000 words against a 300 to 400 word budget.
SKILL: rapid-spec
COST: one-off
CLASS: budget-overrun
RULE:
---

EVENT: A row-level-security suite had never executed, and once it did it ran as
a superuser that bypasses the policies it asserts.
SKILL: horde-qa
COST: one-off
CLASS: green-but-broken
RULE:
---

EVENT: A second app shipped unstyled because its CSS pipeline never compiled;
typecheck, lint and build were green throughout.
SKILL: horde-qa
COST: one-off
CLASS: green-but-broken
RULE:
---

EVENT: Analytics pointed at the wrong regional host, which answers HTTP 200 and
discards the event.
SKILL: horde-qa
COST: one-off
CLASS: green-but-broken
RULE:
---

EVENT: Agents, a local database stack and three dev servers exhausted memory;
the OS killed every server twice, the second time after a deliberate
mitigation was undone.
SKILL: dispatching-hordes
COST: systemic (2 times)
CLASS: resource
RULE:
---

EVENT: A request for a directory was read as persistence, accounts, in-app
messaging and crisis detection; built and tested, then removed as out of
proportion for a one-person product.
SKILL: rapid-spec
COST: one-off
CLASS: spec-misread
RULE:
---
