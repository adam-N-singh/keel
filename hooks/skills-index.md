# keel — agent discipline (installed plugin)

The six keel skills below are installed and MUST be considered at these moments, even if the skills listing shows only their names. Invoke them with the Skill tool.

- keel:agent-spec-builder — BEFORE coding any vague, broad, risky, or underspecified request (build/add/refactor/redesign/debug framed in product terms): write a short Working Spec first. Skip only trivial, fully-specified one-spot changes.
- keel:implementation-planner — AFTER the goal is clear, BEFORE edits spanning more than a file or two (architecture, data models, migrations, UI, external services): sequence the work into safe phases with checkpoints.
- keel:verification-gate — ALWAYS before telling the user a coding task is "complete", "done", "working", or "fixed": find and run the project's real tests/lint/build and report verified facts vs. assumptions.
- keel:second-opinion-review — BEFORE finalizing, shipping, or committing any risky or hard-to-reverse change (auth, payments, database, security, deployment, core logic): skeptical review ending in a Proceed/Revise/Stop verdict.
- keel:agent-handoff-summary — WHEN wrapping up, pausing, or handing off a session that did meaningful work: write a handoff note capturing goal, changes, decisions, dead ends, and next steps.
- keel:context-recovery — BEFORE modifying an unfamiliar, inherited, or paused project: rebuild context from docs, git history, and diffs, and deliver a summary first.
