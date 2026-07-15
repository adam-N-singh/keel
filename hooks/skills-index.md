# keel — the project flight recorder (installed plugin)

keel maintains a persistent engineering ledger per project (`.keel/`): the spec with a requirement checklist, decisions with reasons, verification records with evidence, handoffs, and dead ends. The skills are the ledger's read/write interfaces; deterministic hooks inject its digest at session start, re-anchor requirements after compaction, and (opt-in) gate first edits and unverified stops. This project has no ledger yet — `/keel:init` scaffolds one. Invoke skills with the Skill tool as `keel:<name>`.

- keel:init — scaffold `.keel/`, capture the initial spec, choose gate toggles. The onboarding moment; everything below writes to the ledger it creates.
- keel:agent-spec-builder — write/update the Working Spec (`.keel/spec.md`): goal, constraints, requirement checklist with stable IDs. The first-edit gate routes here.
- keel:implementation-planner — write the phase plan (`.keel/plan.md`): sequenced steps with checkpoints; marks the current phase.
- keel:verification-gate — run the project's real tests/lint/typecheck/build, append an evidence record to `.keel/verification.md`, tick verified requirements, stamp the verified state. The stop gate routes here.
- keel:second-opinion-review — skeptical review with a Proceed/Revise/Stop verdict, appended to `.keel/decisions.md`.
- keel:agent-handoff-summary — rich handoff note into `.keel/handoffs/` so the next session starts warm.
- keel:context-recovery — rebuild context from the ledger + repo and regenerate `.keel/digest.md`; the repair path when the ledger is stale.
