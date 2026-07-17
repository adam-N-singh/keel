# Decisions

## D1 — 2026-07-14 — Advisory-only skills are falsified; never rely on auto-invocation
Four controlled 1.0 runs: frontier models perform the discipline inline and skip
skill invocation regardless of visibility or framing (docs/RESEARCH.md). Every keel
behavior must be reachable by deterministic hook or explicit command. Do not
relitigate by adding features that depend on the model choosing to invoke a skill.

## D2 — 2026-07-15 — Gate escape hatches always leave a record
A gate people disable is worth less than a gate people can skip on the record.
First-edit gate: skip entry in decisions.md. Stop gate: recorded-skip added after
E3 proved the model honors an explicit user countermand (3/3) — the gate's contract
is deterrence + recorded exceptions, not coercion.

## D3 — 2026-07-16 — §7 kill-criteria verdict: the ledger survives
Full E-runs (skilltests/eruns/results/ANALYSIS-2026-07-16.md): E2 continuity
3/3 vs 0/3 intended-scope completion is decisive; E1 was invalid-by-stressor-failure
(no compaction under headless /compact), not a measured null. keel keeps the full
ledger architecture; only the drift-outcome claim remains open (R1).
