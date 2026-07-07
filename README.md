# keel

Discipline for AI coding agents. keel is a Claude Code plugin that adds six skills enforcing the habits that keep agent-driven development safe and reviewable: write a spec before code, sequence work into phases, verify before claiming "done", get a skeptical second opinion on risky changes, hand off cleanly between sessions, and recover full project context before touching an unfamiliar repo.

## Skills

| Skill | What it does |
| --- | --- |
| **agent-spec-builder** | Turns a vague, broad, or risky request into a short Working Spec before any code is written. |
| **implementation-planner** | Breaks a task into safe, sequenced implementation phases with checkpoints before changes begin. |
| **verification-gate** | Runs before any "done/fixed/working" claim — finds and runs the project's real tests, lint, and build, and separates verified facts from assumptions. |
| **second-opinion-review** | Skeptical senior-engineer review of a plan, change, or architecture decision, ending in a Proceed / Revise / Stop verdict. |
| **agent-handoff-summary** | Writes a handoff note capturing goal, changes, decisions, dead ends, and next steps so the next session, agent, or human can continue without rediscovery. |
| **context-recovery** | Rebuilds full project context — docs, manifests, git history, uncommitted diffs, TODO notes — before continuing or modifying a paused or unfamiliar project. |

## Install

From within Claude Code:

```
/plugin marketplace add adam-N-singh/keel
/plugin install keel
```

## Usage

No commands to learn — the skills fire automatically based on context. When a task looks underspecified, keel writes a spec first; when a change spans files, it sequences the work; before claiming completion, it verifies; and so on. You can also invoke any skill explicitly by name.

## License

[MIT](LICENSE)
