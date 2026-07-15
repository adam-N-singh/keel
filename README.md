# keel

Your agent's work, documented. keel is a Claude Code plugin with six skills that each produce a structured, reviewable artifact — a Working Spec, a phase plan, a verification report, a review verdict, a handoff note, a context summary — plus an opt-in enforcement gate that blocks a session from finishing with unverified code changes.

Modern frontier models already practice much of this discipline inline: they think through specs, orient before editing, and verify before claiming completion. What inline work doesn't leave behind is the paper trail. A spec that existed only in the model's reasoning can't be reviewed; verification evidence that scrolled past in a transcript can't be audited; context that was never written down can't be recovered by the next session. keel's skills exist to produce those documents on demand, and its stop gate exists to enforce verification deterministically — without relying on the model's judgment.

## Skills

Each skill is an explicit command. Invoke it when you want the artifact.

| Command | Artifact it produces |
| --- | --- |
| `/keel:agent-spec-builder` | A short Working Spec — goal, scope, constraints, and inferred requirements made explicit — before code is written. |
| `/keel:implementation-planner` | A phase plan — sequenced implementation steps with checkpoints and per-phase verification. |
| `/keel:verification-gate` | A verification report — the project's real tests, lint, typecheck, and build actually run, with verified facts separated from assumptions. |
| `/keel:second-opinion-review` | A skeptical senior-engineer review of a plan, change, or architecture decision, ending in a Proceed / Revise / Stop verdict. |
| `/keel:agent-handoff-summary` | A handoff note — goal, changes, decisions, dead ends, and next steps — so the next session, agent, or human continues without rediscovery. |
| `/keel:context-recovery` | A project context summary rebuilt from docs, manifests, git history, and uncommitted diffs, delivered before any files are touched. |

These artifacts matter most when the work will be reviewed, audited, or continued by someone else — teams, compliance, multi-agent pipelines, or your own future sessions.

## Install

From within Claude Code:

```
/plugin marketplace add adam-N-singh/keel
/plugin install keel
```

keel ships hooks (a session-start index and the stop gate below); Claude Code will ask you to approve them when you install or update the plugin.

## The stop gate

An opt-in `Stop` hook that blocks a session from finishing while it has unverified code changes, directing the model to run `/keel:verification-gate` first. Unlike advice, it fires deterministically — it does not depend on the model deciding to cooperate.

Opt in per project:

```
touch .claude/keel-stop-gate
```

Opt out by deleting that file. Inside a git repo, "unverified changes" means an uncommitted worktree; outside git, it means the session made any file edits (checked from the session transcript, so no git required).

## The session-start index

A `SessionStart` hook injects a ~350-token index of the six skills and when each artifact is useful. This keeps the skills reliably discoverable on plugin-heavy setups, where Claude Code's skill-listing budget (1% of the context window) drops descriptions from rarely-invoked skills. The index makes the model aware of the skills and able to answer "what applies here?" — it does not make the model auto-invoke them, and keel does not claim it will.

## What keel deliberately doesn't claim

Earlier versions of this README said the skills "fire automatically based on context." Controlled testing showed that on frontier models they don't: the models perform the underlying discipline inline and skip the invocation, regardless of how the skills are described or nudged. keel is therefore positioned around what testing supports — explicit invocation for the artifacts, and the stop gate for enforcement. Skills remain model-invocable, and weaker models or non-Claude agents (skills are a portable open format) may trigger them organically; keel just doesn't depend on it.

## License

[MIT](LICENSE)
