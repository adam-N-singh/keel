---
name: agent-spec-builder
description: Write or update the project's Working Spec (.keel/spec.md) BEFORE coding any vague, broad, risky, or underspecified request — build, add, modify, refactor, debug, improve, redesign, or plan a feature. Triggers when a request spans multiple files, touches architecture, data models, schemas, auth, or public interfaces, is hard to reverse, or is framed in product/outcome terms rather than an exact code change. This is the skill keel's first-edit gate routes to when it blocks an edit. The spec's requirement checklist (R1, R2, ...) is what keel re-injects after compaction and what verification records tick off — so getting requirements stated here is what protects them for the rest of the project. Skip only for genuinely trivial, single-spot, unambiguous changes.
---

# Agent Spec Builder

## Why this exists

When an agent gets a broad request — "add billing", "make the export faster", "refactor
auth" — and starts editing immediately, it commits to one interpretation before checking
whether it's the right one. The cost shows up later: code that solves the wrong problem,
touches files it shouldn't, or has to be unwound.

A **Working Spec** moves that interpretation to the front, while it's still cheap to
correct. It's short — usually ten to twenty lines — and it gives the user exactly one
thing to react to before expensive work begins.

In keel 2.0 the spec is not just a message in the transcript: it is **the living
`.keel/spec.md`** at the heart of the project ledger. Its requirement checklist is what
the SessionStart hook re-injects after compaction (the moment constraints usually get
lost), what the verification-gate ticks off with evidence, and what the first-edit gate
checks for. A constraint that never makes it into `spec.md` is a constraint no future
session can recover.

## When to write one (and when not to)

Write or update the Working Spec when the request is any of:

- **Vague or interpretable** — more than one reasonable reading exists.
- **Multi-file** — the change spans more than a file or two.
- **Architectural or stateful** — data models, schemas, migrations, auth, public APIs.
- **Hard to reverse** — migrations, deletions, deploys, real blast radius.
- **Product-framed** — stated as an outcome rather than a specific diff.

Skip it when the change is small, local, and unambiguous: a typo, a rename, a one-line
fix the user fully specified. **Scale the spec to the task** — a borderline case gets a
goal line and two requirements, which is still better than silently guessing.

## Workflow

1. **Read the existing ledger first.** If `.keel/spec.md` exists, this is an *update*,
   not a rewrite: keep existing requirement IDs stable, add new requirements with the
   next free `R<n>`, and never delete a requirement — mark it dropped (`[~]`, citing a
   decision) if it no longer applies. Check `decisions.md` and `deadends.md` so the spec
   doesn't reopen a settled question.

2. **Restate the real goal** in one or two sentences — the *outcome* the user wants, not
   the literal instruction. If the literal request and the apparent goal diverge, say so.

3. **Look before assuming.** Read the files the change would touch: entry points, the
   modules named or implied, relevant config and schema, any existing feature that does
   something similar. Most wrong specs come from guessing at code that could have been
   read in thirty seconds. Cite each observed fact (path, function, line).

4. **Separate facts from assumptions, ruthlessly.** A fact is something you read or
   confirmed. An assumption is anything inferred, defaulted, or hoped. Keep the line bright.

5. **Extract requirements as checkable checklist items.** This is the load-bearing step.
   Each requirement is one observable, verifiable behavior with a stable ID:

   ```markdown
   - [ ] R1: Settlement amounts round half-up to 2 decimal places
   - [ ] R2: Members can be removed only when their balance is zero
   ```

   The exact shape `- [ ] R<n>: <text>` is machine-checked by keel's hooks. "Tests pass"
   is not a requirement; "`POST /invoices` returns 201 with the persisted id" is.
   Constraints the user stated ("no new dependencies", "keep the v1 API stable") go under
   `## Constraints` — that section is re-injected verbatim after compaction.

6. **Bound the work.** In scope, and just as importantly, deliberately out of scope.

7. **Surface risks**, each paired with how you'd mitigate or verify it.

8. **Ask blocking questions only.** A question is blocking when you can't proceed sensibly
   without the answer *and* no reasonable default exists. Everything else becomes a
   labeled assumption the user can veto.

## Writing the spec

**With a ledger** (`.keel/` exists — the normal case): write/update `.keel/spec.md` in
this structure, then show the user the spec (or the diff of what changed, if updating):

```markdown
# Working Spec
Updated: <today>

## Goal
## Constraints
## Requirements
- [ ] R1: ...
## Assumptions
## Out of scope
## Risks
```

Keep the `## Goal`, `## Constraints`, and `## Requirements` headings spelled exactly —
the post-compaction hook extracts them by name. After writing, **update `.keel/digest.md`**:
refresh the `Goal:` and `Open requirements:` lines (smallest digest the content needs,
hard cap 600 tokens).

**Without a ledger**: present the spec inline in the same structure and mention once that
`/keel:init` would make it persistent. Don't create `.keel/` unprompted — init owns onboarding.

After the spec: if nothing blocks and the work is reversible, continue into implementation.
For large, risky, or irreversible changes, present the spec and wait for a quick go-ahead.
Let the size of the risk decide whether you pause, not habit.

## Keep it honest and lean

- A spec that's all assumptions and no facts means you skipped "look before assuming."
  Go read the code.
- "Not yet checked" beats a confident guess. An honest partial spec is more useful than a
  complete, wrong one.
- Don't perform certainty. If the right design is genuinely unclear, put that in *Risks*
  rather than silently picking one.
- Don't pad. The value is in the thinking the format forces, not in filling every heading.
- Never mark a requirement `[x]` here — only the verification-gate does that, with evidence.

## Example

**Request:** "Can you make the report export faster? It's slow."

```markdown
# Working Spec
Updated: 2026-07-15

## Goal
Cut the wait on report export so it feels responsive (~2s for a typical report),
without changing the exported output.

## Constraints
- Exported file must remain byte-identical to current output.
- No new dependencies.

## Requirements
- [ ] R1: A ~1,000-row report exports in under 2s locally
- [ ] R2: Exported CSV is byte-identical to the pre-change output for the same report

## Assumptions
- "Slow" refers to the per-row query loop in reports/export.py:42 (N+1 pattern observed),
  not PDF rendering. Unverified — will confirm by timing before changing anything.

## Out of scope
- Swapping the PDF library; moving export to a background job.

## Risks
- Batching could change row ordering → add an explicit sort; R2 catches regressions.
```

Note what the format forced: the observed fact is cited, the unknown is labeled instead of
guessed, and both requirements are checkable — the verification-gate can later tick R1 and
R2 with a timing run and a diff, and no compaction can lose them.
