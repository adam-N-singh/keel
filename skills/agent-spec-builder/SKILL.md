---
name: agent-spec-builder
description: Turn a vague, broad, or risky software request into a short Working Spec before writing code. Use this whenever the user asks to build, add, modify, refactor, debug, improve, redesign, or plan a feature — especially when the request is underspecified, spans multiple files, touches architecture, data models, schemas, auth, or public interfaces, is hard to reverse, or is framed in product/outcome terms rather than an exact code change. Trigger it even when the user never says "spec" or "plan" — if you're about to start editing code on a non-trivial task and you're inferring what they mean, write the spec first. Skip it only for genuinely trivial, single-spot, unambiguous changes (a typo, a rename, a one-line fix the user fully specified), where a spec would be pure overhead.
---

# Agent Spec Builder

## Why this exists

When an agent gets a broad request — "add billing", "make the export faster", "refactor
auth" — and starts editing immediately, it commits to one interpretation before checking
whether it's the right one. The cost shows up later: code that solves the wrong problem,
touches files it shouldn't, or has to be unwound. By then the agent has spent real effort
and the user has to reverse-engineer what happened.

A **Working Spec** moves that interpretation to the front, while it's still cheap to
correct. It's short — usually ten to twenty lines, not a document — and it gives the user
exactly one thing to react to before expensive work begins. This is the inversion of
"think, then code": instead of reasoning privately and diving in, you make the plan
*inspectable* for a beat, then build. Cheap alignment before costly implementation.

The spec is a checkpoint, not a wall. Most of the time you write it and keep going.

## When to write one (and when not to)

Write a Working Spec when the request is any of:

- **Vague or interpretable** — more than one reasonable reading exists.
- **Multi-file** — the change spans more than a file or two.
- **Architectural or stateful** — it touches data models, schemas, migrations, auth, public
  APIs, or anything other code depends on.
- **Hard to reverse** — migrations, deletions, deploys, anything with a real blast radius.
- **Product-framed** — stated as an outcome ("users should be able to…") rather than a
  specific diff.

Skip it and just do the work when the change is small, local, and unambiguous: a typo, a
rename, a one-line fix, a function the user fully specified. A spec there is friction, not
value — and reflexively producing one for trivial work trains the user to ignore them.

**Scale the spec to the task.** A two-file feature gets a tight spec. A schema migration on
a live system gets a careful one. A borderline case gets three lines — Goal, Plan, one risk
— which is still better than silently guessing.

## Workflow

1. **Restate the real goal** in one or two sentences — the *outcome* the user wants, not the
   literal instruction. If the literal request and the apparent goal diverge, say so; that
   gap is often the most valuable thing the spec surfaces.

2. **Look before assuming.** On a real codebase, read the files the change would touch:
   entry points, the modules named or implied, relevant config and schema, and any existing
   feature that does something similar (so you match its conventions instead of inventing
   new ones). This is the single highest-leverage step — most wrong specs come from guessing
   at code that could have been read in thirty seconds. Populate *Current project facts* only
   with what you actually observed, and cite each one (path, function, line) so the user can
   verify it.

3. **Separate facts from assumptions, ruthlessly.** A fact is something you read or
   confirmed. An assumption is anything inferred, defaulted, or hoped. Quietly promoting an
   assumption to a fact is exactly how an agent drifts off course — keep the line bright.

4. **Bound the work.** State what's in scope and, just as importantly, what's deliberately
   out of scope. Naming the omissions lets the user object to them now rather than discover
   them later, and keeps the change from sprawling.

5. **Define success** as observable, checkable conditions. "Tests pass" is weak;
   "`POST /invoices` returns 201 with the persisted id, and the invoice shows in the
   customer's portal" is checkable.

6. **Surface risks** — what could break, what's irreversible, what's genuinely uncertain,
   where the blast radius reaches. Pair each risk with how you'd mitigate or verify it.

7. **Sketch a small implementation plan** — ordered steps a competent agent could follow,
   sized to the task. The sequence and the touch-points, not pseudocode.

8. **Ask blocking questions only.** A question is blocking when you genuinely can't proceed
   sensibly without the answer *and* no reasonable default exists. Everything else becomes a
   labeled assumption the user can veto. Burying the user in optional questions defeats the
   purpose — the spec is meant to reduce back-and-forth, not generate it.

After the spec: if nothing blocks and the work is reversible, continue into implementation.
For large, risky, or irreversible changes, present the spec and wait for a quick go-ahead.
Let the size of the risk decide whether you pause, not habit.

## Output format

Produce this structure. Omit a section only when it's genuinely empty (most often *Blocking
questions*).

```
## Working Spec

**Goal**
<the real outcome, 1–2 sentences>

**User / stakeholder**
<who this is for and what they're ultimately trying to accomplish>

**Current project facts**
<observed from the code/config, each with a source — path / function / line.
 "Not yet checked: X" is a valid, honest entry.>

**Assumptions**
<inferred or defaulted; each one phrased so the user can veto it>

**In scope**
<what this change will do>

**Out of scope**
<what it deliberately will not do>

**Success criteria**
<observable, checkable conditions — how we'll know it worked>

**Risks**
<what could break / is irreversible / is uncertain — each with a mitigation or check>

**Implementation plan**
<ordered steps, sized to the task>

**Blocking questions**
<only questions that truly block progress; omit this heading entirely if none>
```

## Keep it honest and lean

- A spec that's all assumptions and no facts means you skipped the "look before assuming"
  step. Go read the code.
- "Not yet checked" beats a confident guess. An honest partial spec is more useful than a
  complete, wrong one.
- Don't perform certainty. If the right design is genuinely unclear, put that in *Risks* or
  *Blocking questions* rather than silently picking one and presenting it as settled.
- Don't pad. If a section is one line, it's one line. The value is in the thinking the
  format forces, not in filling every heading.

## Example

A compressed example of the spec doing its job on a vague request.

**Request:** "Can you make the report export faster? It's slow."

```
## Working Spec

**Goal**
Cut the wait on report export so it feels responsive (rough target: a couple of seconds
for a typical report), without changing the exported output.

**User / stakeholder**
End users who export reports and currently sit through a noticeable delay.

**Current project facts**
- Export lives in reports/export.py:generate_pdf().
- Rows are built by querying once per row inside a loop — an N+1 pattern (export.py:42).
- No caching layer observed around the export path.
- Not yet checked: typical report row count in production.

**Assumptions**
- "Slow" refers to the per-row query loop, not PDF rendering itself. (Unverified — I'll
  confirm by timing before changing anything.)

**In scope**
- Replace the per-row query loop with a single batched query, and measure before/after.

**Out of scope**
- Swapping the PDF library; moving export to a background job.

**Success criteria**
- A ~1,000-row report exports in under 2s locally.
- Exported file is byte-identical to the current output.

**Risks**
- Batching could change row ordering → add an explicit sort and diff the output to confirm
  it's unchanged.

**Implementation plan**
1. Add timing to confirm the loop is the real bottleneck.
2. Replace the per-row loop with one batched query.
3. Re-time and compare.
4. Diff the output against a known-good export.

(No blocking questions — I'll verify the bottleneck myself rather than ask.)
```

Note what the format forced: facts carry citations, the unknown is labeled "not yet
checked" instead of guessed, the one assumption is flagged as unverified with a plan to
confirm it, and there are no questions because the agent can answer them itself by reading
and timing. That's the spec earning its place — not paperwork, but a thirty-second
guardrail against building the wrong thing.
