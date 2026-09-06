---
name: isolating-horde-workspaces
description: Use when setting up a horde run to establish isolation and prevent agents from colliding in the user's working copy or default branch
---

# Isolating Horde Workspaces

## Why Worktrees Carry More Weight Here Than You Think

Worktrees are not just collision avoidance. They are what keeps spec-driven
development honest under parallelism, and hordev keeps the SDD tenets even
though it drops the interview.

A worktree gives a line of work its own branch, its own history, and its own
verifiable end state. That is what lets a spec stay attached to something
real: this branch implements `.hordev/specs/<feature-name>.md`, these commits are
its history, this diff is what `horde-qa` verified, and it can be thrown away
whole if the spec was wrong. Without that, a horde's output is an undifferen-
tiated pile of edits in one tree, and there is nothing to review, revert, or
compare — the spec becomes a document nobody can check the code against.

**The unit of isolation is a track of work, not an agent.** One worktree per
spec being implemented. Agents inside a track share it and stay out of each
other's way through file ownership. This is the rule that decides everything
below.

Never run a horde in the user's checkout, and never on the default branch.

## Default: One Shared Worktree with File Ownership

**Use this for most hordes.** Create one worktree for the entire horde. Agents coordinate via file ownership assigned in `decomposing-for-hordes`: each file belongs to exactly one agent. Why: Process isolation per agent wastes merging overhead when agents do not actually collide. Ownership suffices when files are disjoint.

```bash
# Create shared horde worktree from default branch
HORDE_ROOT=".claude/worktrees/horde-$(date +%s)"
git worktree add "$HORDE_ROOT" origin/main -b "horde/run-$(date +%s)"
cd "$HORDE_ROOT"

# Verify you are in the new worktree
git rev-parse --git-dir  # Should show worktree path, not .git
```

All agents in this run work in `$HORDE_ROOT`. Their ownership is enforced by their task assignment in `dispatching-hordes`.

## Per-Agent Isolation: When and How

Create separate worktrees only when agents will:
- **Race competing prototypes** (`racing-prototypes`). Mandatory, not optional:
  each candidate is a separate track of work with its own branch, so the
  candidates can be compared as diffs and the losers deleted whole.
- **Run conflicting servers or builds** (e.g., two agents binding port 3000, or simultaneous cargo builds)
- **Perform destructive or rollback-heavy experiments** (migrations, large deletions, repo rewriting)
- **Do speculative work you expect to discard** (prove feasibility, then decide)

For each agent needing isolation:

```bash
AGENT_WORKTREE=".claude/worktrees/agent-$AGENT_NAME"
git worktree add "$AGENT_WORKTREE" origin/main -b "horde/agent-$AGENT_NAME"
```

Each agent owns its worktree directory and branch. Keep it isolated: do NOT access files across worktrees.

## Shared-State Hazards and Mitigations

Ownership does not prevent these:

| Hazard | Agents Affected | Mitigation |
|--------|-----------------|-----------|
| Git index (.git/index) | All in one worktree | Agents do not run git at all. The orchestrator commits, once the tree is coherent — see `dispatching-hordes`. A worktree has one index, and file ownership does not protect it. |
| Lockfiles (package-lock.json, Cargo.lock, poetry.lock) | All | `decomposing-for-hordes` must assign lockfile ownership to ONE agent. Others use `--locked` or equivalent to freeze. |
| Generated artifacts (dist/, build/, __pycache__) | All | Assign to worktree owner. Add to .gitignore if not tracked. |
| Dependency caches (node_modules/, target/) | All | One agent installs; others skip or use read-only cached versions. |
| Ports and fixture databases | All | Document in task that port X is reserved for agent Y. Cross-check in `dispatching-hordes` before dispatch. |
| npm/cargo registries offline | All | One agent's network hiccup stalls everyone. Mitigate: fetch dependencies before dispatch, cache locally if possible. |

## Cleanup Policy

**Before the horde is removed**, every worktree must be safe to delete:
- All work is committed to its branch.
- No uncommitted changes.
- No local state (running servers, open files).

```bash
# Check all worktrees
git worktree list

# For each worktree, verify
cd "$WORKTREE_PATH"
git status  # Must be clean
git log --oneline -5  # Verify commits exist

# Tear down after horde-qa passes
git worktree remove "$HORDE_ROOT"           # Shared worktree
git worktree remove "$AGENT_WORKTREE_1"     # Per-agent worktrees if used
git worktree remove "$AGENT_WORKTREE_2"
# ... etc
```

If a worktree has uncommitted work and you cannot lose it, the orchestrator —
never an agent — checkpoints it:
```bash
cd "$WORKTREE_PATH"
git add .
git commit -m "Horde checkpoint: $TASK_ID"
git log --oneline -1  # Note the SHA
# Then safe to remove
```

## Critical Rules

**Never:**
- Let agents write to the user's original checkout while the horde runs. (Separate worktree enforces this.)
- Commit horde work to the default branch. Each worktree has its own branch; use one per horde run.
- Share a worktree across multiple horde runs. Use unique branch and worktree names per run.

**Always:**
- Run `git worktree list` at the start to confirm the horde's isolation.
- Pass `$HORDE_ROOT` or `$AGENT_WORKTREE_N` to all dispatched agents as an env var. They `cd` there immediately.
- Commit and verify each agent's work before removing its worktree.

## Run Lifecycle

1. **Before `dispatching-hordes`:** Set up isolation (this skill). Capture `$HORDE_ROOT` and any per-agent worktree paths. Export them.
2. **During dispatch:** Each agent receives its worktree path. Agents work only in that tree; cross-tree reads/writes are errors.
3. **After `horde-qa` passes:** Tear down worktrees. Verify all branches pushed (if a remote exists) or at least committed.
4. **Finish:** Return to the user's original checkout. It is untouched.
