---
name: implementation-planner
description: Sequence a software task into safe implementation phases and write the plan to the project ledger (.keel/plan.md) BEFORE code changes begin — triggers on multi-file tasks, architecture or data-model choices, database migrations, UI changes, or external services; anything messy or hard to unwind in one pass. Pairs with agent-spec-builder — once the goal and requirements are in .keel/spec.md, use this to decide the order of work, the smallest useful first slice, where the checkpoints go, and what to verify after each phase. Maintains the "Current phase" marker that keel's digest carries across sessions. Skip for small, single-spot changes where one careful edit is the whole job.
---

# Implementation Planner

## Why this exists

Handed a task with several moving parts, an agent's instinct is to land it all in one
pass. A dozen files change at once. Then something breaks, and there's no way to tell
which of the twelve edits did it, no safe point to roll back to, and a diff too large to
review with confidence.

Phasing trades one big risky leap for a few small safe ones. Each phase is a slice you can
implement, verify, and trust before moving on. You also learn earlier: the smallest useful
slice surfaces the real unknowns while they're still cheap to get wrong.

In keel 2.0 the plan lives at **`.keel/plan.md`**, and its `Current phase:` line rides the
digest into every future session — so a continuation doesn't have to rediscover where the
work stood. A plan that existed only in a transcript dies with the session; this one doesn't.

## When to use

Reach for a plan when a task could touch more than a file or two, or involves architecture
or data-model decisions, migrations, auth or shared interfaces, UI changes, or external
services.

**Start from the ledger.** Read `.keel/spec.md` first — its goal, constraints, requirements,
and risks are your inputs; don't re-derive them. Check `deadends.md` so no phase re-walks an
abandoned approach, and `decisions.md` so the plan doesn't relitigate a settled choice. If
there's no spec and the task is genuinely ambiguous about *what* to build, spec it first
(`keel:agent-spec-builder`) — planning the *how* of an unclear *what* just produces a
confident plan for the wrong thing.

Skip planning for small, local, single-spot changes — a five-phase plan there is exactly
the overbuilding this skill exists to prevent.

## Core principles

1. **Smallest useful slice first.** The first implementation should be the thinnest path
   that proves the approach end-to-end — a vertical slice, not a finished horizontal layer.
   Get the *uncertain* part working early, where being wrong is cheap.

2. **Don't change many files at once unless the change is atomic.** Small diffs are
   reviewable, localizable when they break, and reversible. When unsure, fewer files per phase.

3. **Don't overbuild.** Build what the task needs now, not the general version you imagine
   it might need later.

4. **Every phase ends at a checkpoint.** A checkpoint is an observable "safe to continue" —
   tests green, the slice runs, the migration applied cleanly. Tie checkpoints to the spec's
   requirement IDs where possible ("R1 passes its timing check") so the verification-gate
   can tick them with evidence. A plan whose phases can't each be independently verified
   isn't phased, it's a to-do list with headings.

## Workflow

1. Read `.keel/spec.md`, `deadends.md`, and `decisions.md`; carry the goal, constraints,
   and requirements forward.
2. Find the smallest useful first slice — the thin end-to-end path that proves the riskiest
   assumption.
3. Sequence the rest into phases, each independently verifiable, each touching as few files
   as it can.
4. For each phase, name the files it will likely touch, its dependencies, and its checkpoint
   (with the requirement IDs it advances).
5. Surface risks, consolidate the total blast radius, and name the single recommended first step.

## Writing the plan

**With a ledger**: write `.keel/plan.md` and show it to the user. Include the update stamp
and the current-phase marker — the digest carries that line across sessions:

```markdown
# Implementation Plan
Updated: <today>
Current phase: 1 — Discovery

## Phase 1 — Discovery
<what to read and confirm before changing anything>
Checkpoint: <what you'll have confirmed before writing a line of code>

## Phase 2 — Minimal implementation
<the smallest useful slice>
Files: <the few files this touches>
Checkpoint: <how you'll verify the slice works — cite R-IDs where possible>

## Phase 3 — Integration
## Phase 4 — Verification
## Phase 5 — Cleanup

## Likely files affected
<consolidated list — the total blast radius at a glance>

## Risks
<each paired with the phase that mitigates it>

## Recommended first step
<the one concrete action to take right now>
```

The five phases are the default scaffold — merge or drop phases for small tasks and say so
in one line ("Phase 5 — Cleanup: none needed") rather than padding.

**As phases complete**, update the `Current phase:` line — that one-line edit is what keeps
continuations oriented. When you update the plan, also refresh the `Phase:` line in
`.keel/digest.md` (respect the 600-token cap).

**Without a ledger**: present the same structure inline and mention once that `/keel:init`
would persist it.

## Example

**Request:** "Add a 'Download CSV' button to the reports page."

```markdown
# Implementation Plan
Updated: 2026-07-15
Current phase: 1 — Discovery

## Phase 1 — Discovery
Confirm where report data is assembled (reports/views.py:report_view) and whether a CSV
helper exists. Check how the page renders the table and how filters reach the server.
No code changes.
Checkpoint: exact data source known; helper existence confirmed.

## Phase 2 — Minimal implementation
Thinnest slice: a GET endpoint returning the current report as CSV, reusing the page's
query. Reachable by URL only — no button yet.
Files: reports/views.py, reports/urls.py
Checkpoint: hitting the endpoint downloads a correct CSV (advances R1).

## Phase 3 — Integration
Button on the page, wired to the endpoint, passing current filters.
Files: templates/reports.html (+ small JS if filters are client-side)
Checkpoint: button's CSV matches the on-screen report, filters included (R2).

## Phase 4 — Verification
Empty report, large report, comma/quote/newline fields, permissions.
Checkpoint: verification-gate run; R1–R3 ticked with evidence.

## Phase 5 — Cleanup
Unify the endpoint query with the page's query helper so they can't drift.
Checkpoint: one shared source; diff tidy.

## Likely files affected
reports/views.py, reports/urls.py, templates/reports.html (+ possibly a csv helper)

## Risks
- CSV injection / unquoted fields → stdlib csv writer, never string concatenation (Phase 2).
- Export query drifting from page query → Phase 5 unifies; until then a deliberate,
  noted duplication.

## Recommended first step
Open reports/views.py and confirm the report's data source before touching anything.
```

The uncertain part — correct CSV from real data — is proven in Phase 2 on a bare URL,
before any UI exists. Each phase touches a small named set of files and ends at a check
you can run. And because the plan is in the ledger, a session that dies after Phase 2
hands the next one a `Current phase:` line instead of a cold start.
