---
name: init
description: Scaffold the keel ledger (.keel/) in the current project — run when the user asks to set up keel, initialize the ledger, start tracking requirements/decisions/verification, or when any keel skill finds no .keel/ directory and the user wants one. Creates the directory structure and config, captures an initial Working Spec (interviewing the user only where the repo and conversation can't answer), sets the gate toggles, and generates the first digest so the very next session starts warm.
---

# keel init

Scaffold `.keel/` — keel's persistent engineering ledger — and capture enough initial state that the next session starts warm. This is the onboarding moment: everything the other keel skills read and write lives in what you create here.

The ledger format is specified in the plugin's `docs/LEDGER.md`; the shapes that hooks parse mechanically (requirement lines, config keys, section headings) are restated below — keep them exact.

## Workflow

**1. Check for an existing ledger.** If `.keel/` already exists, do not re-scaffold. Report what's there, fill only missing pieces (e.g. a config without the gate keys, a missing digest), and stop. Never overwrite an existing `spec.md`, `decisions.md`, or `verification.md`.

**2. Create the structure.**

```bash
mkdir -p .keel/state .keel/handoffs
printf 'state/\n' > .keel/.gitignore
```

Then write `.keel/config` (gates ship **off** — they are opt-in until the user chooses them):

```
# keel gate toggles — 1 to enable, 0 to disable
# GATE_FIRST_EDIT: block the session's first file edit until spec.md has requirements
# GATE_STOP_VERIFY: block finishing a turn with edits newer than the last verification record
GATE_FIRST_EDIT=0
GATE_STOP_VERIFY=0
```

Create `decisions.md`, `verification.md`, and `deadends.md` each with just a title line (`# Decisions`, `# Verification records`, `# Dead ends`) — they are append-only logs that grow from here.

**3. Capture the initial Working Spec.** Gather from what you already have before asking anything: the conversation so far, README/docs, manifests, git history. Then write `.keel/spec.md`:

```markdown
# Working Spec
Updated: <today>

## Goal
<the real outcome, 1–2 sentences>

## Constraints
<hard rules the implementation must respect>

## Requirements
- [ ] R1: <observable, checkable requirement>
- [ ] R2: ...

## Assumptions
## Out of scope
## Risks
```

Requirement lines must match `- [ ] R<n>: <text>` exactly — hooks grep for this shape. If the project has a clear active goal, extract 3–8 requirements from it. If there is genuinely no current task (bare repo, exploratory project), ask the user one focused question: "What is this project trying to do right now?" — and if they have no answer yet, write the Goal and leave Requirements as a single line `<!-- no requirements yet — agent-spec-builder adds them when work starts -->`. Do not invent requirements to fill space. For anything beyond a quick capture, invoke `keel:agent-spec-builder` — it owns spec quality.

**4. Offer the gates.** Ask the user (one question, both toggles):

- **First-edit gate** — blocks the session's first file edit until the spec has requirements. Best for projects where "code first, think later" has burned them.
- **Stop gate** — blocks finishing a turn that edited files until verification is recorded and fresh. Best when "done" claims must carry evidence.

Set the chosen values in `.keel/config`. If the user isn't present to answer (autonomous run), leave both `0` and note in your summary how to enable them.

**5. Generate the first digest.** Write `.keel/digest.md` — the summary the SessionStart hook injects every session. Smallest digest the content needs, hard cap 600 tokens; for a fresh ledger that's typically 3–6 lines:

```markdown
Goal: <from spec.md>
Open requirements: R1, R2, R3 (of 3; 0 verified)
Last verification: none yet
Ledger initialized: <today>. Gates: first-edit <on/off>, stop-verify <on/off>.
```

**6. Report.** Tell the user what was created, which gates are on, and that the ledger is committable (`state/` is already gitignored). Recommend committing `.keel/` so the paper trail travels with the repo.

## Keep it honest

- The ledger's value is that it reflects reality. A scaffold full of invented requirements is worse than a sparse honest one.
- Never enable a gate the user didn't choose.
- If the project already has handoff notes, TODOs, or docs describing current work, mine them into the spec and cite where each requirement came from.
