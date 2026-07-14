# keel — agent discipline (installed plugin)

Invoking these skills at their trigger moments is the DEFAULT, not optional advice. If a trigger matches and you skip the skill, you MUST say so in your response and justify it in one sentence. "I'll do the equivalent inline" is never a valid justification — each skill produces a structured artifact (Working Spec, phase plan, verification report, review verdict, handoff note) that inline work does not. Invoke them with the Skill tool.

- keel:agent-spec-builder — BEFORE the first code edit of any non-trivial build/add/refactor/redesign/debug request, even a concrete-sounding one: if it spans multiple files or you are inferring any requirement, write the Working Spec first. Skip only single-spot, fully-specified changes.
- keel:implementation-planner — BEFORE edits spanning more than a file or two (architecture, data models, migrations, UI, external services): sequence phases and checkpoints. A greenfield app build ALWAYS qualifies.
- keel:verification-gate — ALWAYS before saying a task is "complete", "done", "working", or "fixed". Having run tests manually is not a substitute: the skill's verified-facts-vs-assumptions report is the deliverable.
- keel:second-opinion-review — BEFORE finalizing, shipping, or committing any risky or hard-to-reverse change (auth, payments, database, security, deployment, core logic): skeptical review ending in a Proceed/Revise/Stop verdict.
- keel:agent-handoff-summary — WHEN wrapping up, pausing, or handing off a session that did meaningful work: write the handoff note (goal, changes, decisions, dead ends, next steps).
- keel:context-recovery — BEFORE modifying an unfamiliar, inherited, or paused project: rebuild context from docs, git history, and diffs, and deliver a summary first.
