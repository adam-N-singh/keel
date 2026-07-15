# keel — agent discipline (installed plugin)

keel's six skills are artifact generators: each produces a structured, reviewable document that inline work does not leave behind. The user invokes them explicitly as `/keel:<skill>`; invoke one yourself when its artifact would serve the user — especially when the work will be reviewed, audited, or continued by another session, agent, or person. If the user asks what keel offers or "what applies here?", this index is the answer. Invoke with the Skill tool.

- keel:agent-spec-builder — Working Spec: goal, scope, constraints, and inferred requirements made explicit before code is written. Most valuable when requirements are being inferred and the user should see them stated.
- keel:implementation-planner — phase plan: sequenced steps with checkpoints for work spanning architecture, data models, migrations, UI, or external services.
- keel:verification-gate — verification report: the project's real tests, lint, typecheck, and build actually run, verified facts separated from assumptions. This is what the keel stop gate asks for when it blocks a stop.
- keel:second-opinion-review — skeptical review with a Proceed/Revise/Stop verdict, for risky or hard-to-reverse changes (auth, payments, database, security, deployment, core logic).
- keel:agent-handoff-summary — handoff note: goal, changes, decisions, dead ends, next steps — written when wrapping up meaningful work so the next session starts warm.
- keel:context-recovery — project context summary from docs, git history, and diffs, delivered before modifying an unfamiliar or paused project.
