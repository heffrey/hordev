# hordev run log

Append-only. Format defined by `improving-hordev`.

---

EVENT: Bootstrap run. 12 haiku agents dispatched in one message to write the
initial skill library, cannibalizing superpowers skills as source material.
All 12 produced usable files; none returned a plan instead of content.
SKILL: dispatching-hordes
COST: one-off
RULE:
---

EVENT: Agents committed their own work to the shared git index without being
asked. 4 of 12 committed, 8 did not, producing an inconsistent history and
concurrent writes to one index. Nothing was lost, but only by luck.
SKILL: dispatching-hordes
COST: one-off
RULE: The horde agent prompt contract must state who commits. Default: agents
write files only, the orchestrator commits.
---

EVENT: rapid-spec and writing-tdds each invented a different location for the
spec artifact ("the file path you determine" vs unspecified), and rapid-spec
invented a one-line assumption format that contradicted the fuller entry
format defined by assumption-ledger. Caught in QA at the seam.
SKILL: decomposing-for-hordes
COST: one-off
RULE: Shared artifact paths and file formats are interfaces. The orchestrator
fixes them before dispatch and inlines them in every agent prompt.
---

EVENT: writing-tdds came back at 262 lines against a stated 80-150 line bar,
with a section title duplicated at top level. Re-dispatched with specific
defects; returned at 194 lines, still over budget but coherent.
SKILL: dispatching-hordes
COST: one-off
RULE:
---

EVENT: Two skill descriptions came back as summaries rather than trigger
conditions (improving-hordev scoped to a single file state, rapid-spec
describing its own capabilities). Both would have failed to fire in situations
they are meant for.
SKILL: writing-hordev-skills
COST: one-off
RULE:
---

EVENT: The skill forbidding machine-specific paths in a public repo contained a
machine-specific path in its own example.
SKILL: writing-hordev-skills
COST: one-off
RULE:
---

EVENT: isolating-horde-workspaces told agents to stage and commit their own
work, contradicting the rule just added to dispatching-hordes. Second
appearance of the same commit-ownership defect, so it clears the repeat bar.
Both skills now say agents do not run git and the orchestrator commits.
SKILL: decomposing-for-hordes
COST: systemic (2 times)
RULE: When two skills describe the same shared resource, one of them owns the
rule and the other links to it. Never state it twice.
---

EVENT: Worktree isolation was framed only as collision avoidance. It is also
what keeps a spec attached to a reviewable, revertible branch, which is the
SDD tenet hordev keeps. The unit of isolation is a track of work, not an agent.
SKILL: isolating-horde-workspaces
COST: one-off
RULE:
---

EVENT: Hook end-to-end execution could not be verified in the authoring
session; the sandbox refused to run the scripts. Verified by syntax check and
by validating the JSON payload shape separately. Still unproven in a live
session.
SKILL: horde-qa
COST: one-off
RULE:
---
