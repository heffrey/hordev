---
name: writing-hordev-skills
description: Use when creating a new skill, editing an existing one, or verifying a skill triggers correctly and works standalone
---

# Writing Hordev Skills

A skill is a reference guide — imperative instructions for a model to follow in specific situations. Write once, invoke repeatedly across tasks.

## Description Field Is a Trigger, Not a Summary

Your description is the ONLY text a model sees when deciding whether to load your skill. Make it describe WHEN to use, not WHAT it does.

| Bad | Why | Good |
|-----|-----|------|
| "Handles async test flakiness by waiting for conditions instead of sleep" | Summarizes the approach; agent may stop reading | "Use when tests race, hang, or pass/fail inconsistently" |
| "A guide to writing hordev skills with TDD" | Says what it is | "Use when authoring new skills or editing existing ones" |
| "For state management" | Too vague | "Use when managing shared state across parallel subagents" |

Start with "Use when" and list concrete symptoms or situations. Add keywords an agent would search for (error messages, tool names, symptoms).

## File Structure

```
skills/skill-name/
  SKILL.md              # Required: overview, patterns, examples
  supporting-file.*     # Only if reusable code or heavy reference
```

Keep everything inline unless it's >100 lines or a reusable tool.

## Frontmatter

Required: `name` and `description`. Name uses letters, numbers, hyphens only.

```yaml
---
name: your-skill-name
description: Use when [specific triggering condition]
---
```

## Hordev-Specific: No Approval Gates

Hordev prioritizes time-to-prototype. Your skill must not add a user round-trip or checkpoint.

**Test:** Does following your skill require the user to approve output before proceeding? If yes, rewrite it to produce a committable artifact without approval.

Example bad: "Sketch the design, wait for approval, then build."
Example good: "Build the design directly (revise if feedback arrives)."

## Editing an Existing Skill

When a skill fails in production (seen via `improving-hordev`), make the smallest change that prevents that failure. Add a rule rather than rewriting sections. Test the specific failure before deploying.

**Red flags:**
- Rewriting whole sections
- Adding multiple new rules at once
- Editing mid-run (wait until task completes)

## Narrow vs. Broad

One skill = one decision point. If your skill covers "decomposing work AND dispatching AND reconciling," split it.

**Test:** Describe your skill in one sentence. If it needs "and," it is two skills.

## Content Structure

```
# Skill Name

## Overview
Core principle, 1–2 sentences.

## When to Use
Concrete situations and symptoms (bullets).
When NOT to use.

## Core Pattern / Quick Reference
Table or list for scanning. Code inline if <50 lines.

## Common Mistakes
What breaks + fixes.

## Red Flags
Signs you are about to violate the skill (discipline skills only).
```

## Testing Your Skill

**Before deploying:** Run the skill against a fresh model with NO prior conversation context. Does it trigger correctly? Does a model follow it without the authoring conversation's context?

For technique skills: Can a fresh model apply the technique to a new scenario?

For discipline skills: Does a fresh model comply under pressure (time constraint, sunk cost)?

**For editing:** Test the specific failure the edit addresses. Verify new wording does not break compliance in other scenarios.

## Public Repository

hordev is open source. Skills are read by strangers. No machine-specific paths
(no `/Users/<name>/`, no `/home/<name>/`), no personal references, no assumed
local setup. Use paths relative to the project root, or abstract examples.

## Word Count

Target <200 lines. Concrete examples and decision rules are good; explanation and background are expensive. Remove anything that does not change how a model behaves.

## Red Flags — STOP Before Writing

| Excuse | Reality |
|--------|---------|
| "I'll test after I deploy" | Deploy untested = deploy broken. Test first. |
| "It's obvious to me" | Clear to you ≠ clear to a fresh model. Test it. |
| "This adds a checkpoint but it's important" | Checkpoints delay prototype. Hordev rejects them. Redesign. |
| "I'm extending an existing skill" | Test the full skill afterward. Changes can break old scenarios. |
| "Editing is too risky" | Untested edits are riskier. Test the failure, make the change, re-test. |

