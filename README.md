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

No commands to learn — the skills fire automatically based on context. When a task looks underspecified, keel writes a spec first; when a change spans files, it sequences the work; before claiming completion, it verifies; and so on. You can also invoke any skill explicitly by name (e.g. `/keel:verification-gate`).

keel ships a small `SessionStart` hook that injects a ~250-token index of the six skills and their trigger conditions into each session. This keeps the skills reliably invocable on machines with many plugins installed, where Claude Code's skill-listing budget (1% of the context window) would otherwise drop their descriptions. Claude Code will ask you to approve the hook when you install or update the plugin.

## Reliability on plugin-heavy setups

Claude Code drops skill descriptions from context starting with the least-frequently-invoked skills. Two ways to guarantee keel full visibility:

**Pin the skills** in your `~/.claude/settings.json` so their descriptions are always included:

```json
{
  "skillOverrides": {
    "keel:agent-spec-builder": "on",
    "keel:implementation-planner": "on",
    "keel:verification-gate": "on",
    "keel:second-opinion-review": "on",
    "keel:agent-handoff-summary": "on",
    "keel:context-recovery": "on"
  }
}
```

**Bootstrap invocation frequency**: description retention is earned by use, so on day one invoke each skill once explicitly (`/keel:agent-spec-builder`, `/keel:verification-gate`, …). After that, automatic triggering sustains itself.

## License

[MIT](LICENSE)
