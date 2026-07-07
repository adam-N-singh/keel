---
name: implementation-planner
description: Break a software task into safe, sequenced implementation phases before any code changes begin. Use this whenever a task could touch multiple files, involves architecture or data-model choices, database migrations, UI changes, or external services — anything that gets messy or hard to unwind if done in one pass. It pairs with agent-spec-builder — once the goal and scope are understood (from a Working Spec or a clear request), use this to decide the order of work, the smallest useful first slice, where the checkpoints go, and what to verify after each phase. Trigger it even when the user never says "plan" or "phases" — if you're about to start a build that spans more than a file or two, sequence it first. Skip it for small, single-spot changes where one careful edit is the whole job.
---

# Implementation Planner

## Why this exists

Handed a task with several moving parts — a schema change, a new endpoint, a UI update, a
third-party call — an agent's instinct is to land it all in one pass. A dozen files change
at once. Then something breaks, and there's no way to tell which of the twelve edits did it,
no safe point to roll back to, and a diff too large for anyone to review with confidence.
The work *looks* fast right up until it has to be unwound.

Phasing trades one big risky leap for a few small safe ones. Each phase is a slice you can
implement, verify, and trust before moving on — so when something breaks, the cause is in
the handful of lines you just touched, not somewhere in a giant diff. You also learn
earlier: the smallest useful slice surfaces the real unknowns while they're still cheap to
get wrong.

This is the execution counterpart to a Working Spec. A spec settles *what* you're building
and *why*; this settles *in what order*, *how small the first step is*, and *how you'll
know each step is safe* before taking the next one.

## When to use

Reach for an Implementation Plan when a task could touch more than a file or two, or
involves any of: architecture or data-model decisions, database migrations, auth or other
shared/public interfaces, UI changes, or external services. Those are exactly the tasks
where a one-pass implementation gets messy and hard to reverse.

If a **Working Spec already exists, start from it** — its goal, scope, facts, and risks are
your inputs; don't re-derive them. If there's no spec and the task is genuinely ambiguous
about *what* to build, that's a signal to spec it first (or spec it quickly inline):
planning the *how* of an unclear *what* just produces a confident plan for the wrong thing.

Skip planning for small, local, single-spot changes — one careful edit is the whole job,
and a five-phase plan there is exactly the overbuilding this skill exists to prevent.

## Core principles

1. **Smallest useful slice first.** The first implementation should be the thinnest path
   that proves the approach end-to-end — a vertical slice through the layers, not a finished
   horizontal layer. One feature working through the whole stack beats every layer
   half-built. The point is to de-risk: get the *uncertain* part working early, on something
   small, where being wrong is cheap.

2. **Don't change many files at once unless the change is atomic.** Small diffs are
   reviewable, localizable when they break, and reversible. A phase that touches twelve files
   is only justified when the change is genuinely indivisible — a consistent rename, a
   mechanical migration — where splitting it would leave the code broken in between.
   Otherwise, split it. When unsure, fewer files per phase.

3. **Don't overbuild.** Build what the task needs now, not the general version you imagine
   it might need later. No speculative abstraction, no config for a single case, no framework
   for one use. Generality is cheap to add when a second case actually appears and expensive
   to carry when it never does.

4. **Every phase ends at a checkpoint.** A checkpoint is an observable "safe to continue" —
   tests green, the slice runs, the migration applied cleanly. Phases exist so you *stop and
   check* between them; a plan whose phases can't each be independently verified isn't really
   phased, it's just a to-do list with headings.

## Workflow

1. If a Working Spec exists, read it and carry its goal, scope, and risks forward. If not,
   make sure the *what* is clear enough to sequence.
2. Find the smallest useful first slice — the thin end-to-end path that proves the riskiest
   assumption.
3. Sequence the rest into phases, each independently verifiable, each touching as few files
   as it can.
4. For each phase, name the files it will likely touch, its dependencies (what must come
   first, and any external pieces it needs — libraries, services, env, migrations), and its
   checkpoint (what to verify before moving on).
5. Surface risks, consolidate the total blast radius, and name the single recommended first
   step.

## Output format

Use this structure. The five phases are the default scaffold — if the task is small, merge
or drop phases and say so in one line (e.g. "Phase 5 — Cleanup: none needed") rather than
padding them out. Each phase carries what it does, the files it touches, and its checkpoint.

```
## Implementation Plan

**Phase 1 — Discovery**
<read and confirm what's needed before changing anything: touchpoints, conventions to
 match, unknowns to resolve, external dependencies. Often no code changes at all.>
Checkpoint: <what you'll have confirmed before writing a line of code>

**Phase 2 — Minimal implementation**
<the smallest useful slice — the thin end-to-end path that proves the approach works.>
Files: <the few files this touches>
Checkpoint: <how you'll verify the slice actually works>

**Phase 3 — Integration**
<wire the slice into the rest of the system and handle the remaining cases.>
Files: <files this touches>
Checkpoint: <feature works in context, nothing adjacent broke>

**Phase 4 — Verification**
<tests, edge cases, error paths; confirm the success criteria (from the spec if there is one).>
Checkpoint: <the concrete checks that say "done and correct">

**Phase 5 — Cleanup**
<remove scaffolding and dead code, tidy naming, update docs if warranted. Skip if nothing to do.>
Checkpoint: <diff is tidy, no leftover temporary code>

**Likely files affected**
<consolidated list across all phases, so the total blast radius is visible at a glance>

**Risks**
<what could break / is irreversible / is uncertain — each paired with the phase that mitigates it>

**Recommended first step**
<the one concrete action to take right now — usually the start of Phase 1 or 2>
```

## Example

A compressed example on a task with several moving parts.

**Request:** "Add a 'Download CSV' button to the reports page so users can export the
current report."

```
## Implementation Plan

**Phase 1 — Discovery**
Confirm where the report data is assembled (reports/views.py:report_view) and whether a
serializer/CSV helper already exists. Check how the page renders the table
(templates/reports.html) and how current filters reach the server. No code changes yet.
Checkpoint: know the exact data source for the export and whether a CSV helper exists.

**Phase 2 — Minimal implementation**
Thinnest slice: a GET endpoint that returns the current report as CSV, reusing the same
query the page uses. Reachable by URL only — no button yet.
Files: reports/views.py, reports/urls.py.
Checkpoint: hitting the endpoint downloads a correct CSV of the current report.

**Phase 3 — Integration**
Add the "Download CSV" button to the page, wired to the endpoint, passing the report's
current filters so the export matches what's on screen.
Files: templates/reports.html (+ small JS if filters are client-side).
Checkpoint: the button downloads a CSV that matches the on-screen report, filters included.

**Phase 4 — Verification**
Empty report, large report, fields containing commas/quotes/newlines, and permissions
(can a user export a report they aren't allowed to view?).
Checkpoint: every edge case yields valid CSV; no permission leak.

**Phase 5 — Cleanup**
Unify the Phase 2 endpoint query with the page's query helper so they can't drift apart.
Checkpoint: export and page read from one source; diff is tidy.

**Likely files affected**
reports/views.py, reports/urls.py, templates/reports.html (+ possibly a small csv helper).

**Risks**
- CSV injection / unquoted fields → use the stdlib csv writer, never string concatenation.
- Export query drifting from the page query → Phase 5 unifies them; until then it's a
  deliberate, noted duplication.

**Recommended first step**
Start Phase 1: open reports/views.py and confirm the report's data source before touching
anything.
```

Notice what the phasing bought. The uncertain part — producing correct CSV from the real
data — is proven in Phase 2 on a bare URL, *before* any UI exists. If the data shape is
wrong, you find out with two files changed, not five. Each phase touches a small, named set
of files and ends at a check you can actually run. And cleanup is explicitly *deferred*, not
skipped, so the Phase 2 shortcut doesn't quietly become permanent debt.
