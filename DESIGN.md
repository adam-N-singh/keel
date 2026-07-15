# keel 2.0 — Design: The Project Flight Recorder

**Status:** implemented 2026-07-15 (hooks, ledger spec in docs/LEDGER.md, all seven skills). Phase-0 mechanics checks (§4) and the E-runs (§7) remain to be executed before README claims are upgraded.
**Grounding:** the keel 1.0 falsification (RESEARCH.md, 2026-07; advisory skills got 0 invocations on frontier models across all arms) and July-2026 ecosystem research (skills auto-activation broken ecosystem-wide at ~50%; winning plugins are hook-driven infrastructure, not advice; documented frontier pain points are goal drift, context rot after ~25–30 tool calls, session amnesia, and the clarification spiral).

---

## 1. Vision

keel 1.0 tried to make the model *choose* discipline. The model already had the discipline and skipped the ceremony. keel 2.0 keeps the same core vision — spec before code, verify before done, clean handoffs, context recovery — but changes the mechanism from advice the model may take to **state the model cannot have without keel**:

> keel maintains a structured, persistent, human-readable engineering ledger per project — requirements with status, decisions with reasons, verification records with evidence, handoffs, dead ends — written and enforced by deterministic hooks. The skills become the read/write interfaces the hooks route the model through.

Two moats, neither dependent on model cooperation and neither eroded by models getting smarter:

1. **Persistence.** Inline discipline leaves no artifact and dies at session end. A smarter model still cannot recover a constraint that was never written down, and cannot prove verification that left no record.
2. **Determinism.** Hooks fire regardless of model judgment. Invocation is guaranteed by construction — the discretion that killed keel 1.0 is out of the loop.

Positioning: "your agent's work, documented — and enforced." The ledger is committable and reviewable, serving teams, audits, and multi-agent pipelines, where inline-equivalent work genuinely does not substitute.

### What keel 2.0 deliberately is not

- **Not conversational memory.** claude-mem compresses observations of what happened. keel records *engineering artifacts*: requirements, decisions, evidence. Chat log vs engineering notebook.
- **Not workflow orchestration.** Superpowers owns opinionated greenfield methodology (brainstorm → plan → subagent execution). keel is harness-level enforcement + records that work under any workflow, including Superpowers itself.
- **Not reliant on skill auto-triggering.** Falsified. Every keel behavior is reachable by hook or explicit command.

---

## 2. Pain → mechanism map

| Documented pain point | keel 2.0 mechanism | Hook |
| --- | --- | --- |
| Requirement/goal drift; constraints lost at compaction | Living requirement checklist, re-injected immediately after compaction | `SessionStart` (source: `compact`) |
| Session amnesia; "prompt fatigue"; expensive re-orientation (Run 2A: 29 tool calls before first edit) | Ledger digest injected at every session start | `SessionStart` (all sources) |
| Clarification spiral: implementation launched on unstated assumptions | Opt-in first-edit gate: block the session's first file edit until a spec exists | `PreToolUse` (Edit\|Write\|MultiEdit\|NotebookEdit) |
| Verification theater: "done" without durable evidence | Stop gate v2: block on *stale verification* (edits since last verification record), not raw dirtiness; the report becomes a ledger record | `Stop` |
| Lost handoffs; cold continuations | Mechanical session record on every session end; rich model-authored handoff as explicit command | `SessionEnd` + `/keel:agent-handoff-summary` |

Compliance-vs-diligence caveat, designed around: every gate's **output is the artifact**. A verification report produced under duress is still a verification report; minimal compliance still yields the paper trail.

---

## 3. The ledger

### 3.1 Location and format

`.keel/` at the project root. Plain files, human-readable, committable. File-based (not SQLite) because the paper trail *is* the product: it must be diffable, reviewable in a PR, and portable to any harness.

```
.keel/
  config            # gate toggles (simple KEY=VALUE, bash-parseable)
  spec.md           # living Working Spec: goal, constraints, requirement checklist
  plan.md           # current phase plan (optional; written by implementation-planner)
  decisions.md      # append-only decision log
  verification.md   # append-only verification records
  handoffs/         # dated handoff notes + mechanical session records
  deadends.md       # append-only: approaches tried and abandoned, and why
  digest.md         # machine-regenerated compact summary (what SessionStart injects)
  state/            # machine state, gitignored via .keel/.gitignore
    last-verified   # git hash + working-tree content hash at last verification record
```

### 3.2 Requirement checklist schema

Requirements live in `spec.md` as checkbox lines with stable IDs, machine-checkable by bash and model alike:

```markdown
## Requirements
- [ ] R1: Settlement amounts round half-up to 2 decimal places
- [x] R2: Trip members can be removed only when their balance is zero  (verified: V7)
- [~] R3: Export to CSV  (dropped 2026-07-15, see decisions.md D4)
```

`[ ]` open · `[x]` met-and-verified (links a verification record) · `[~]` dropped (links a decision). Drift detection is then a diff: requirements don't silently vanish; they get explicitly closed or dropped.

### 3.3 Verification records

Appended to `verification.md` by `/keel:verification-gate`:

```markdown
## V7 — 2026-07-15 14:32 — commit a1b2c3d (tree hash 9f8e...)
- Ran: `npm test` (142 passed), `npx tsc --noEmit` (clean), `npm run lint` (clean)
- Verified: R1, R2 behavior via test suite; R2 additionally in browser
- Assumed, not verified: mobile layout; concurrent-edit behavior
```

The skill also writes `state/last-verified` (commit hash + a hash of `git status --porcelain` + `git diff`). The stop gate compares current state to it — **freshness**, not dirtiness. This fixes keel 1.0's stop-gate blind spot where committing made you "clean" without ever verifying.

### 3.4 The digest

`digest.md` is regenerated (by the skills as they write, and repairable by `/keel:context-recovery`) with an **adaptive size and a hard cap of 600 tokens**: generate the smallest digest the ledger's actual content needs — a young project naturally produces ~150 tokens; a mature ledger gets room for the last handoff's summary, recent decisions, and dead-end warnings. The cap, not a target, is what guards against bloat.

- Every session start: goal (1–2 lines), open requirements, current phase, last verification status, last handoff summary, dead-end warnings — smallest-first, dropping from the tail if the cap binds. Hard cap 600 tokens.
- After compaction (`SessionStart` source `compact`): the **full requirement checklist + constraints** — re-anchoring at exactly the moment drift happens. This is the sharpest novel intervention in the design; to our knowledge nobody ships it.

Cost basis for the cap (2026-07 API pricing, cache-aware): the digest rides the cached prefix, so even a maxed 600-token digest on a ~110-turn session costs ~3–7 cents (Opus 4.8–Fable 5) and the 600-vs-400 delta is ~1–2 cents — while one avoided re-orientation lookup (a Read/Grep at full input price) repays the delta ~10×. E4 measures the real per-session cost; E2 measures whether digest richness reduces re-orientation.

---

## 4. Hook architecture

All hooks are bash, LF-pinned, no dependencies beyond git/grep/sed (same portability posture as 1.0). Gates are **opt-in via `.keel/config`** until validated; the ledger/digest layer is on whenever `.keel/` exists.

| Hook | Fires | Behavior |
| --- | --- | --- |
| `SessionStart` | every session start incl. post-compact | `cat .keel/digest.md`; on `compact` source, also inject the requirement checklist from `spec.md`. If no `.keel/`, inject a one-line pointer to `/keel:init`. |
| `PreToolUse` (edit tools) | before first Edit/Write of a session | *(gate, opt-in: `GATE_FIRST_EDIT=1`)* If `spec.md` missing or has zero requirements, block once with: "run `/keel:agent-spec-builder` first (or `keel-skip <reason>` — recorded in decisions.md)." Session-scoped marker in `state/` prevents re-blocking. The skip path is deliberate: an escape hatch that leaves a record beats a gate people disable. |
| `Stop` | end of turn | *(gate, opt-in: `GATE_STOP_VERIFY=1`)* Block if working tree state ≠ `state/last-verified` (non-git fallback: transcript edit scan, as shipped in 1.0-fix). Reason text routes to `/keel:verification-gate`. Loop-safe via `stop_hook_active`. |
| `SessionEnd` | session close | Mechanical session record into `handoffs/`: timestamp, git status summary, files touched (from transcript). No model authorship — SessionEnd is informational; the model is gone. Deterministic breadcrumb, not a substitute for the rich handoff. |
| `PreCompact` | before compaction | Snapshot nothing initially (compaction re-anchor is handled by SessionStart-compact). Reserved; Phase 0 verifies whether we need it. |

**Phase 0 mechanics to verify before building** (all cheap, all in a scratch project):

1. `SessionStart` with `compact` source: confirm it fires post-compaction and stdout lands in context (docs say yes; never exercised by us).
2. `PreToolUse` block UX: confirm the deny reason reaches the model verbatim and a follow-up Skill invocation succeeds.
3. Hook-directed skill invocation reliability: when a gate names a skill, does the model invoke it (vs doing the function inline)? The 1.0 stop gate never fired in anger — this is still an untested link. If the model complies with the *function* but not the *invocation*, the skill bodies' ledger-write instructions must live in the gate reason text too (belt and braces).

---

## 5. Skills as ledger interfaces

keel 1.0's constraint "never modify skill bodies" is **dropped** — 2.0 rewrites every body to read/write the ledger. Names and artifacts stay.

| Skill | 2.0 behavior |
| --- | --- |
| `agent-spec-builder` | Writes/updates `spec.md` (goal, constraints, requirement checklist with IDs). The first-edit gate routes here. |
| `implementation-planner` | Writes `plan.md`; marks current phase; updates digest. |
| `verification-gate` | Runs the project's real checks; appends a verification record; updates requirement checkboxes it evidenced; writes `state/last-verified`. The stop gate routes here. |
| `second-opinion-review` | Appends verdict + reasoning to `decisions.md`. |
| `agent-handoff-summary` | Writes a rich dated note into `handoffs/`; updates digest. |
| `context-recovery` | Reads ledger + repo; regenerates `digest.md`; the repair path when the ledger is stale or hand-edited. |
| `init` *(new)* | Scaffolds `.keel/`, interviews for the initial spec, sets gate toggles. The onboarding moment. |

Frontmatter descriptions stay trigger-first (costless), but nothing depends on auto-triggering.

---

## 6. Failure modes and mitigations

- **Stale ledger** (model edits code without updating spec): the stop gate catches the verification half; requirement staleness is surfaced by `context-recovery` and by digest-vs-diff mismatch. Accepted residual risk — a slightly stale ledger still beats no ledger.
- **Token cost**: digest hard cap + compact-source injection limited to requirements. Measure real cost in Phase 0; publish it honestly in the README.
- **Two sessions, one project**: append-only files mostly merge clean; `spec.md` checkbox edits can conflict. Documented limitation in v2.0; no locking.
- **Hook latency**: all hooks are `cat`/`grep`/`sed`-class; keep <100ms.
- **Gate fatigue → uninstall**: gates ship opt-in, every gate has a recorded-skip escape hatch, and block reasons are one sentence with the exact command.
- **Windows**: LF via `.gitattributes` (already pinned); transcript-path handling as fixed in 1.0.

---

## 7. Experiment plan (falsifiable, before README claims)

Reusing the Splitfair harness. n ≥ 3 per arm for any quality claim (1.0 lesson).

1. **E0 — mechanics** (Phase 0 above): hook firings, injection, block UX, hook-directed invocation rate.
2. **E1 — drift**: long build with 8–10 explicit constraints stated up front; force compaction mid-task; measure constraint survival in the final product, ledger arm vs control. *This is the headline claim; it must survive testing.*
3. **E2 — amnesia**: continuation of a paused project, ledger arm vs cold start; measure tool calls before first productive edit (baseline: 29 vs 17 in Phase-2 runs) and rediscovery errors.
4. **E3 — stop gate in anger**: with `GATE_STOP_VERIFY=1`, does the block reliably produce a verification record? (The still-untested link from 1.0.)
5. **E4 — cost**: tokens/session added by digest + gates, measured, for the README.

Kill criteria, stated now: if E1 shows no constraint-survival delta and E2 shows no orientation delta, the ledger doesn't earn its keep and keel shrinks to the gates + explicit commands (the 1.0-fix posture we shipped).

---

## 8. Migration and versioning

- v2.0.0, git-versioned by commit (no `version` field churn).
- 1.0's SessionStart index is superseded by the digest (falls back to the static index when no `.keel/` exists — new installs still get awareness).
- 1.0-fix stop gate becomes the non-git fallback inside stop gate v2.
- README rewrite #2 after E-runs, claims bounded by data.
