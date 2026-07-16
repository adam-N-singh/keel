# keel

**The project flight recorder for AI coding agents.** keel maintains a structured, persistent, human-readable engineering ledger per project — requirements with status, decisions with reasons, verification records with evidence, handoffs, dead ends — written by explicit skills and enforced by deterministic hooks. Your agent's work, documented — and, if you opt in, enforced.

## Why a ledger

Frontier models already practice good engineering discipline inline: they think through specs, orient before editing, verify before claiming done. keel 1.0 tried to make them *invoke* that discipline as skills, and controlled testing showed they simply don't — they do the function and skip the ceremony (see [docs/RESEARCH.md](docs/RESEARCH.md)). What inline discipline cannot do is **persist**. A constraint that lived in the model's reasoning dies at compaction; verification evidence that scrolled by in a transcript can't be audited; the next session starts cold no matter how smart the last one was.

keel 2.0 is built on the two mechanisms that don't depend on model cooperation:

1. **Persistence** — the `.keel/` ledger: plain files, diffable, committable, portable to any harness.
2. **Determinism** — hooks that fire by construction: the ledger digest is injected at every session start, the requirement checklist is re-injected immediately after compaction (exactly the moment constraints get lost), and the opt-in gates block rather than advise.

## The ledger

`/keel:init` scaffolds `.keel/` at your project root ([format spec](docs/LEDGER.md)):

```
.keel/
  config            # gate toggles
  spec.md           # living Working Spec: goal, constraints, requirement checklist (R1, R2, ...)
  plan.md           # phase plan with a current-phase marker
  decisions.md      # append-only decision log (D1, D2, ...)
  verification.md   # append-only verification records with evidence (V1, V2, ...)
  handoffs/         # rich handoff notes + mechanical session records
  deadends.md       # approaches tried and abandoned, and why
  digest.md         # compact summary injected at every session start (hard cap 600 tokens)
  state/            # machine state (gitignored)
```

Requirements are checkbox lines with stable IDs — `[ ]` open, `[x]` verified (citing a verification record), `[~]` dropped (citing a decision) — so drift is a diff, not a mystery: requirements get explicitly closed or dropped, never silently lost.

## Hooks (the deterministic layer)

| Hook | What it does |
| --- | --- |
| `SessionStart` | Injects `.keel/digest.md` every session — goal, open requirements, last verification, last handoff, dead-end warnings. After a **compaction**, additionally re-injects the spec's Goal, Constraints, and Requirements verbatim. |
| `PreToolUse` *(opt-in gate)* | `GATE_FIRST_EDIT=1`: blocks the session's first file edit until `spec.md` has requirements, routing to `/keel:agent-spec-builder`. Blocks once per session; skipping is allowed but leaves a record in `decisions.md`. |
| `Stop` *(opt-in gate)* | `GATE_STOP_VERIFY=1`: blocks finishing a turn that edited files while the working tree no longer matches the last verification record. **Freshness, not dirtiness** — committing doesn't make you "verified", and committing already-verified content doesn't re-block. Routes to `/keel:verification-gate`. |
| `SessionEnd` | Appends a mechanical session record (timestamp, git summary, files edited) to `.keel/handoffs/sessions.md`. |

Gates ship **off**; enable them per project in `.keel/config`. Every gate's block message contains the exact command to satisfy it, and every gate has an escape hatch that leaves a paper trail — because minimal compliance still yields the record, and a recorded skip beats a disabled gate.

## Skills (the ledger's read/write interfaces)

| Command | What it does |
| --- | --- |
| `/keel:init` | Scaffold `.keel/`, capture the initial spec, choose gate toggles. |
| `/keel:agent-spec-builder` | Write/update the Working Spec: goal, constraints, requirement checklist. |
| `/keel:implementation-planner` | Write the phase plan; maintain the current-phase marker. |
| `/keel:verification-gate` | Run the project's real checks, append an evidence record, tick verified requirements, stamp the verified state. |
| `/keel:second-opinion-review` | Skeptical review with a Proceed/Revise/Stop verdict, recorded in the decision log. |
| `/keel:agent-handoff-summary` | Rich handoff note into `handoffs/`; dead ends logged so nobody re-walks them. |
| `/keel:context-recovery` | Rebuild context from ledger + repo; regenerate the digest (the repair path). |

## Install

```
/plugin marketplace add adam-N-singh/keel
/plugin install keel
```

keel ships hooks; Claude Code will ask you to approve them on install/update. Then, in any project: `/keel:init`.

## What keel claims — and what it doesn't (yet)

Claims are bounded by controlled testing (n=3 per arm; protocol and raw analysis in [DESIGN.md](DESIGN.md) §7 and the test harness).

- **Claimed, by construction:** hooks fire deterministically; the ledger persists across sessions and compaction; the artifacts are reviewable and committable. None of this depends on the model choosing to cooperate.
- **Claimed, from testing — continuity (the headline result):** on identical half-built projects continued with "finish whatever remains", the ledger arm completed the intended scope **3/3** (requirements verified and ticked); the cold-start arm **0/3** — all three controls independently invented the *same* plausible-but-wrong scope from code clues. Session amnesia doesn't look like failure; it looks like confident wrong work. The ledger's measured value is outcome correctness, not orientation speed (controls actually oriented faster — into the wrong scope).
- **Claimed, from testing — gates:** every gate outcome leaves a record. The first-edit gate fired 3/3 with a paper trail in every case (full spec capture, partial capture, or a reasoned recorded skip). The stop gate blocked 3/3 when a user explicitly forbade verification; the model sided with the user 3/3 (the gate does not — and should not — coerce against an explicit instruction) but recorded the skip in `decisions.md` 3/3. Absent a countermand, the armed gate produced verification without ever needing to block. The gate's real contract: **deterrence plus recorded exceptions.**
- **Claimed, from 1.0 testing:** advisory skills alone do not get invoked by frontier models — the falsification this design answers.
- **Under test, not yet claimed:** that post-compaction re-anchoring measurably improves constraint survival. The mechanism is proven live (the re-anchor fires and lands in context after real compaction), but the outcome experiment requires compaction mid-build, which headless runs cannot trigger (`/compact` doesn't execute under `claude -p`) — an interactive-compaction run is the one experiment remaining.
- **Cost, measured:** the digest itself is cache-riding and costs cents. The real overhead is the work the gates cause — spec capture, real verification runs, ledger writes — which roughly doubled spend on small tasks (≈ +$3 on a ~$3.50 build; ≈ +$0.75 on a ~$0.75 continuation). On the continuation experiment the cheaper arm delivered the wrong outcome 3/3, so cost per *correct* outcome favored the ledger.

## License

[MIT](LICENSE)
